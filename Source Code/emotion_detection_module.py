"""
emotion_detection_module.py  —  MediaPipe 0.10+ Face Landmarker emotion detection
==================================================================================
Compatible with mediapipe 0.10.x (Python 3.12/3.13 on Windows).

On first run this module automatically downloads face_landmarker.task (~6 MB)
from Google's CDN and saves it next to this file.  All subsequent runs use
the cached file — no internet connection needed after that.

Five geometric ratios drive the scorer:
    MAR  — Mouth Aspect Ratio     (how open the mouth is)
    MCR  — Mouth Corner Ratio     (corner lift = smile, drop = frown)
    EAR  — Eye Aspect Ratio       (wide = fear/surprise, narrow = angry)
    BRR  — Brow Raise Ratio       (high = surprise/fear)
    BFR  — Brow Furrow Ratio      (low inner distance = angry)

Calibration:
    If emotions feel slightly off for your face, add this temporarily to your
    main loop and print values while making each expression, then adjust the
    matching threshold in EmotionConfig:

        from emotion_detection_module import get_all_ratios
        ratios = get_all_ratios(frame)
        if ratios: print(ratios)
"""

from __future__ import annotations

import os
import sys
import time as _time
import pathlib
import urllib.request
import cv2
import numpy as np
from dataclasses import dataclass
from typing import List, Tuple, Dict, Optional

# ── Model auto-download ───────────────────────────────────────────────────────

_MODEL_URL  = (
    "https://storage.googleapis.com/mediapipe-models/"
    "face_landmarker/face_landmarker/float16/latest/face_landmarker.task"
)
_MODEL_PATH = pathlib.Path(__file__).parent / "face_landmarker.task"


def _ensure_model() -> str:
    if _MODEL_PATH.exists():
        return str(_MODEL_PATH)
    print("[emotion] face_landmarker.task not found — downloading (~6 MB)...")
    try:
        urllib.request.urlretrieve(_MODEL_URL, _MODEL_PATH)
        print(f"[emotion] Model saved to {_MODEL_PATH}")
    except Exception as e:
        print(
            f"[emotion] Download failed: {e}\n"
            f"  Please download manually from:\n  {_MODEL_URL}\n"
            f"  and place it at:\n  {_MODEL_PATH}"
        )
        sys.exit(1)
    return str(_MODEL_PATH)


# ── MediaPipe 0.10 tasks API setup ────────────────────────────────────────────

import mediapipe as mp
from mediapipe.tasks.python import vision as _mp_vision
from mediapipe.tasks.python.core import base_options as _mp_base

_model_path = _ensure_model()

_landmarker = _mp_vision.FaceLandmarker.create_from_options(
    _mp_vision.FaceLandmarkerOptions(
        base_options = _mp_base.BaseOptions(model_asset_path=_model_path),
        running_mode = _mp_vision.RunningMode.VIDEO,
        num_faces    = 4,
        min_face_detection_confidence = 0.5,
        min_face_presence_confidence  = 0.5,
        min_tracking_confidence       = 0.5,
        output_face_blendshapes       = False,
    )
)
print("[emotion] FaceLandmarker ready.")

# ── Landmark indices (MediaPipe 468-point canonical map) ──────────────────────
_MOUTH_LEFT      = 61;   _MOUTH_RIGHT     = 291
_MOUTH_TOP_INNER = 82;   _MOUTH_BOT_INNER = 312
_MOUTH_TOP       = 13;   _MOUTH_BOTTOM    = 14

_L_EYE_TOP  = 159;  _L_EYE_BOT   = 145
_L_EYE_LEFT = 33;   _L_EYE_RIGHT = 133
_R_EYE_TOP  = 386;  _R_EYE_BOT   = 374
_R_EYE_LEFT = 362;  _R_EYE_RIGHT = 263

_L_BROW_PEAK  = 105;  _R_BROW_PEAK  = 334
_L_BROW_INNER = 55;   _R_BROW_INNER = 285

_FACE_TOP   = 10;   _FACE_BOTTOM = 152
_FACE_LEFT  = 234;  _FACE_RIGHT  = 454

EMOTIONS = ('happy', 'sad', 'angry', 'surprise', 'fear', 'neutral')

EMOTION_COLORS: Dict[str, Tuple[int, int, int]] = {
    'happy':    (0,   255, 128),
    'sad':      (255, 100,   0),
    'angry':    (0,     0, 255),
    'surprise': (0,   200, 255),
    'fear':     (128,   0, 255),
    'neutral':  (200, 200, 200),
}


# ── Configuration ─────────────────────────────────────────────────────────────

@dataclass
class EmotionConfig:
    """
    All decision thresholds in one place.
    Use get_all_ratios() to print live values and tune to your face.

    Normal resting values for most faces:
        mar  ≈ 0.02–0.08   (closed mouth)
        mcr  ≈ 0.00–0.01   (neutral corners)
        ear  ≈ 0.25–0.30   (relaxed eyes)
        brr  ≈ 0.06–0.09   (neutral brows)
        bfr  ≈ 0.09–0.13   (neutral inner brow gap)
    """
    mar_open_thresh:   float = 0.25    # mouth open     (MAR above this)
    mcr_smile_thresh:  float = 0.005   # smiling        (MCR above this)
    mcr_sad_thresh:    float = -0.003  # frowning       (MCR below this)
    ear_wide_thresh:   float = 0.32    # eyes wide open (EAR above this)
    ear_narrow_thresh: float = 0.20    # eyes squinting (EAR below this)
    brr_raised_thresh: float = 0.075   # brows raised   (BRR above this)
    bfr_furrow_thresh: float = 0.085   # brows furrowed (BFR below this)

    smoothing_window:  int   = 8
    ema_alpha:         float = 0.30
    min_display_confidence: float = 35.0


# ── Per-face EMA smoother ─────────────────────────────────────────────────────

class _EmotionSmoother:
    def __init__(self, cfg: EmotionConfig):
        self._cfg = cfg
        self._ema: Dict[str, float] = {e: 0.0 for e in EMOTIONS}

    def update(self, raw: Dict[str, float]) -> Dict[str, float]:
        a = self._cfg.ema_alpha
        for e in EMOTIONS:
            self._ema[e] = a * raw.get(e, 0.0) + (1.0 - a) * self._ema[e]
        return dict(self._ema)

    def reset(self):
        self._ema = {e: 0.0 for e in EMOTIONS}


_smoothers: Dict[int, _EmotionSmoother] = {}


def _get_smoother(idx: int, cfg: EmotionConfig) -> _EmotionSmoother:
    if idx not in _smoothers:
        _smoothers[idx] = _EmotionSmoother(cfg)
    return _smoothers[idx]


# ── Geometry helpers ──────────────────────────────────────────────────────────

def _px(lm, idx: int, w: int, h: int) -> np.ndarray:
    p = lm[idx]
    return np.array([p.x * w, p.y * h], dtype=float)


def _dist(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.linalg.norm(a - b))


def _compute_ratios(landmarks, img_w: int, img_h: int) -> Dict[str, float]:
    G = lambda i: _px(landmarks, i, img_w, img_h)

    face_h = max(_dist(G(_FACE_TOP),  G(_FACE_BOTTOM)), 1.0)
    face_w = max(_dist(G(_FACE_LEFT), G(_FACE_RIGHT)),  1.0)

    # MAR — mouth vertical / mouth horizontal
    mar = _dist(G(_MOUTH_TOP_INNER), G(_MOUTH_BOT_INNER)) / \
          max(_dist(G(_MOUTH_LEFT), G(_MOUTH_RIGHT)), 1.0)

    # MCR — corner lift above mouth centre, normalised by face height
    cy  = (G(_MOUTH_TOP)[1] + G(_MOUTH_BOTTOM)[1]) / 2.0
    mcr = ((cy - G(_MOUTH_LEFT)[1]) + (cy - G(_MOUTH_RIGHT)[1])) / 2.0 / face_h

    # EAR — eye vertical / eye horizontal (both eyes averaged)
    l_ear = _dist(G(_L_EYE_TOP), G(_L_EYE_BOT)) / max(_dist(G(_L_EYE_LEFT), G(_L_EYE_RIGHT)), 1.0)
    r_ear = _dist(G(_R_EYE_TOP), G(_R_EYE_BOT)) / max(_dist(G(_R_EYE_LEFT), G(_R_EYE_RIGHT)), 1.0)
    ear   = (l_ear + r_ear) / 2.0

    # BRR — brow peak to eye top, normalised by face height
    brr = (_dist(G(_L_BROW_PEAK), G(_L_EYE_TOP)) +
           _dist(G(_R_BROW_PEAK), G(_R_EYE_TOP))) / (2.0 * face_h)

    # BFR — inner brow distance / face width
    bfr = _dist(G(_L_BROW_INNER), G(_R_BROW_INNER)) / face_w

    return {'mar': mar, 'mcr': mcr, 'ear': ear, 'brr': brr, 'bfr': bfr}


# ── Emotion scorer ────────────────────────────────────────────────────────────

def _score_emotions(ratios: Dict[str, float],
                    cfg: EmotionConfig) -> Dict[str, float]:
    mar, mcr, ear, brr, bfr = (ratios[k] for k in ('mar','mcr','ear','brr','bfr'))

    smile_s    = max(0.0, (mcr - cfg.mcr_smile_thresh)  * 200.0)
    frown_s    = max(0.0, (cfg.mcr_sad_thresh - mcr)    * 200.0)
    mouth_s    = max(0.0, (mar - cfg.mar_open_thresh)    * 5.0)
    eye_wide_s = max(0.0, (ear - cfg.ear_wide_thresh)    * 10.0)
    eye_narr_s = max(0.0, (cfg.ear_narrow_thresh - ear)  * 10.0)
    brow_up_s  = max(0.0, (brr - cfg.brr_raised_thresh)  * 20.0)
    brow_dn_s  = max(0.0, (cfg.bfr_furrow_thresh - bfr)  * 30.0)

    sc: Dict[str, float] = {e: 0.0 for e in EMOTIONS}

    sc['happy']    += 4.0 * smile_s + 0.5 * mouth_s * min(smile_s, 1.0) \
                    - 1.0 * frown_s - 0.5 * brow_dn_s
    sc['surprise'] += 3.0 * brow_up_s + 2.5 * mouth_s + 1.5 * eye_wide_s \
                    - 0.5 * brow_dn_s
    sc['fear']     += 2.5 * eye_wide_s + 2.0 * brow_up_s + 1.5 * mouth_s \
                    - 3.0 * smile_s
    sc['angry']    += 3.0 * brow_dn_s + 2.0 * eye_narr_s \
                    - 2.0 * smile_s - 1.0 * brow_up_s
    sc['sad']      += 3.0 * frown_s + 0.8 * brow_up_s - 2.0 * smile_s

    total = sum([smile_s, frown_s, mouth_s, eye_wide_s,
                 eye_narr_s, brow_up_s, brow_dn_s])
    sc['neutral'] += max(0.0, 1.5 - total)

    for e in EMOTIONS:
        sc[e] = max(0.0, sc[e])
    return sc


def _to_result(scores: Dict[str, float]) -> Tuple[str, float]:
    items = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    w, ws = items[0];  _, rs = items[1]
    return w, float(np.clip(100.0 * (ws - rs) / (ws + 1e-6), 0.0, 95.0))


# ── Frame timestamp tracker (VIDEO mode requires monotonic timestamps) ─────────
# Uses wall-clock time in milliseconds so the timestamp:
#   • is always increasing regardless of frame rate
#   • never resets to 0 when reset_smoothers() is called
#   • won't violate MediaPipe's monotonic requirement across calls

_process_start = _time.monotonic()


def _next_ts() -> int:
    """Return milliseconds elapsed since module load — always monotonically increasing."""
    return int((_time.monotonic() - _process_start) * 1000)


# ── Public API ────────────────────────────────────────────────────────────────

def detect_emotion(
    frame: np.ndarray,
    faces: List[Tuple[int, int, int, int]],
    cfg:   Optional[EmotionConfig] = None,
) -> Tuple[str, float, np.ndarray]:
    """
    Detect emotion using MediaPipe Face Landmarker (0.10+ tasks API).

    Args:
        frame : BGR frame from OpenCV.
        faces : List of (x, y, w, h) bounding boxes (largest = dominant).
        cfg   : EmotionConfig — uses defaults if None.

    Returns:
        dominant_emotion    (str)
        dominant_confidence (float 0–100)
        annotated_frame     (BGR ndarray)
    """
    if cfg is None:
        cfg = EmotionConfig()

    annotated = frame.copy()
    img_h, img_w = frame.shape[:2]

    if not faces:
        return 'none', 0.0, annotated

    # Run Face Landmarker
    rgb      = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    result   = _landmarker.detect_for_video(mp_image, _next_ts())

    if not result.face_landmarks:
        return 'neutral', 0.0, annotated

    all_lm_sets  = result.face_landmarks          # list of lists of NormalizedLandmark
    sorted_faces = sorted(faces, key=lambda b: b[2] * b[3], reverse=True)

    dominant_emotion, dominant_confidence = 'neutral', 0.0

    for i, (x, y, w, h) in enumerate(sorted_faces):
        if i >= len(all_lm_sets):
            break

        # Match MediaPipe result to bbox by nose-tip proximity
        bbox_cx, bbox_cy = x + w / 2.0, y + h / 2.0
        best_lm, best_d  = None, float('inf')
        for lm_set in all_lm_sets:
            nose = lm_set[1]   # landmark index 1 = nose tip
            d = abs(nose.x * img_w - bbox_cx) + abs(nose.y * img_h - bbox_cy)
            if d < best_d:
                best_d, best_lm = d, lm_set

        if best_lm is None:
            continue

        try:
            ratios = _compute_ratios(best_lm, img_w, img_h)
        except Exception:
            continue

        raw_scores    = _score_emotions(ratios, cfg)
        smooth_scores = _get_smoother(i, cfg).update(raw_scores)
        emotion, confidence = _to_result(smooth_scores)

        if i == 0:
            dominant_emotion, dominant_confidence = emotion, confidence

        if confidence >= cfg.min_display_confidence:
            color = EMOTION_COLORS.get(emotion, (255, 255, 255))
            cv2.putText(annotated, f"{emotion} ({confidence:.0f}%)",
                        (x, y + h + 22), cv2.FONT_HERSHEY_SIMPLEX,
                        0.62, color, 2)

    return dominant_emotion, dominant_confidence, annotated


def reset_smoothers() -> None:
    """
    Call when switching video sources or resetting a session.

    NOTE: This intentionally does NOT reset the timestamp counter.
    MediaPipe's VIDEO mode requires monotonically increasing timestamps
    for the lifetime of the landmarker instance, so the clock must
    never go backwards regardless of session resets.
    """
    for s in _smoothers.values():
        s.reset()
    _smoothers.clear()


def get_all_ratios(frame: np.ndarray) -> Optional[Dict[str, float]]:
    """
    Calibration utility — call in your main loop while making expressions
    and print the output to tune EmotionConfig thresholds for your face.

    Example:
        ratios = get_all_ratios(frame)
        if ratios: print(ratios)
        # smiling  → {'mar': 0.09, 'mcr': 0.018, 'ear': 0.27, ...}
        # neutral  → {'mar': 0.04, 'mcr': 0.003, 'ear': 0.27, ...}
    """
    rgb      = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    result   = _landmarker.detect_for_video(mp_image, _next_ts())
    if not result.face_landmarks:
        return None
    try:
        return _compute_ratios(result.face_landmarks[0], frame.shape[1], frame.shape[0])
    except Exception:
        return None