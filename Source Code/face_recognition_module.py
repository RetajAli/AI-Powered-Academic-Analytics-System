"""
face_recognition_module.py  —  ArcFace + IoU tracker  (multi-face build)
==========================================================================
Performance improvements over previous build:
  1. Recognition runs in a background daemon thread → zero frame-drop from ArcFace.
  2. BOX_EMA_ALPHA lowered to 0.18 → much smoother / less jittery boxes.
  3. IOU_MIN raised to 0.35 → tighter detection-to-track matching, fewer ghost tracks.
  4. RECOG_EVERY_N raised to 6 → half the GPU calls without visible latency.
  5. Confidence hysteresis: a confirmed identity requires 3 consecutive "Unknown"
     votes before it reverts — eliminates flicker on partial occlusion.
  6. VOTE_WINDOW raised to 15 → more stable majority vote.
  7. TRACK_MAX_MISSING raised to 18 → box survives brief detector misses.
  8. Threading lock protects shared state; result queue is non-blocking.
  9. All prior bug-fixes retained (adaptive threshold, pre-crop, LBPH threshold, etc.)

Multi-face fix (this build):
  10. Single worker thread replaced with a ThreadPoolExecutor (RECOG_WORKERS threads).
      Multiple faces are now recognised IN PARALLEL — no queuing lag when 2+ people
      are in the frame at the same time.
  11. Per-track in-flight counter replaces boolean flag so overlapping results from
      the pool are handled correctly.
  12. RECOG_WORKERS defaults to min(4, cpu_count) — automatically scales to the machine.
"""

from __future__ import annotations

import os
import math
import queue
import threading
import warnings
from concurrent.futures import ThreadPoolExecutor
import cv2
import numpy as np
from collections import deque
from typing import Dict, List, Optional, Tuple

os.environ.setdefault('TF_CPP_MIN_LOG_LEVEL', '3')
warnings.filterwarnings('ignore')

# ── DeepFace ──────────────────────────────────────────────────────────────────
try:
    from deepface import DeepFace
    _USE_DEEPFACE = True
    print("[face] DeepFace loaded OK")
except Exception as e:
    _USE_DEEPFACE = False
    print(f"[face] DeepFace failed to load: {e}")
    print("[face] Falling back to LBPH — pip install deepface tf-keras (Python 3.11)")

# ── Cascades ──────────────────────────────────────────────────────────────────
_face_cascade = cv2.CascadeClassifier(
    cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
)
_eye_cascade = cv2.CascadeClassifier(
    cv2.data.haarcascades + 'haarcascade_eye.xml'
)

# ── Paths ─────────────────────────────────────────────────────────────────────
_script_dir       = os.path.dirname(os.path.abspath(__file__))
_photo_cache_path = os.path.join(_script_dir, 'photo_cache')

# ══════════════════════════════════════════════════════════════════════════════
#  TUNEABLE CONSTANTS  (accuracy-tuned for CPU)
# ══════════════════════════════════════════════════════════════════════════════

DEEPFACE_THRESHOLD: float = 0.62   # raised: CPU embeddings have higher intra-variance
DEEPFACE_MODEL:     str   = "ArcFace"
DEEPFACE_DETECTOR:  str   = "skip" # use "skip" inside _embed — ROI is already a face crop
                                   # "opencv" was causing misaligned crops → wrong embeddings
AUGMENT_COUNT:      int   = 7      # raised: denser embedding cloud per person

LBPH_THRESHOLD:     float = 130.0

# ── Tracker ───────────────────────────────────────────────────────────────────
IOU_MIN:            float = 0.35
BOX_EMA_ALPHA:      float = 0.18
TRACK_MAX_MISSING:  int   = 18
RECOG_EVERY_N:      int   = 3      # lowered: fills vote window faster → quicker lock-on
VOTE_WINDOW:        int   = 15
UNKNOWN_FLIP_COUNT: int   = 5      # raised: confirmed identity is harder to knock off

import os as _os
RECOG_WORKERS: int = min(4, (_os.cpu_count() or 2))

# ══════════════════════════════════════════════════════════════════════════════
#  MODULE STATE
# ══════════════════════════════════════════════════════════════════════════════
_db_loaded:        bool                          = False
_frame_counter:    int                           = 0
_known_embeddings: List[Tuple[str, np.ndarray]]  = []
_person_threshold: Dict[str, float]              = {}
_recogniser:       Optional[object]              = None
_label_map:        Dict[int, str]                = {}
_tracks:           Dict[int, dict]               = {}
_next_track_id:    int                           = 0
_state_lock:       threading.Lock                = threading.Lock()

# ── Background recognition pool ───────────────────────────────────────────────
# The main loop submits (track_id, roi_bgr) futures; results are collected each frame.
# Using a pool means multiple faces are recognised in parallel — no queuing lag
# when several people are visible at the same time.
_recog_result_q:  queue.Queue        = queue.Queue()
_recog_pool:      ThreadPoolExecutor = ThreadPoolExecutor(max_workers=RECOG_WORKERS,
                                                          thread_name_prefix="recog")


def _recog_task(track_id: int, roi: np.ndarray) -> None:
    """Runs inside the pool: recognise ROI and post result to the result queue."""
    name, conf = _recognize(roi)
    _recog_result_q.put((track_id, name, conf))


# ══════════════════════════════════════════════════════════════════════════════
#  UTILITIES
# ══════════════════════════════════════════════════════════════════════════════

def _imread_unicode(path: str) -> Optional[np.ndarray]:
    try:
        raw = np.fromfile(path, dtype=np.uint8)
        img = cv2.imdecode(raw, cv2.IMREAD_COLOR)
        if img is None:
            print(f"[WARNING] cv2.imdecode returned None for: {path}")
        return img
    except Exception as e:
        print(f"[WARNING] Cannot read {path}: {e}")
        return None


def _l2_norm(vec: np.ndarray) -> np.ndarray:
    n = np.linalg.norm(vec)
    return vec / n if n > 0 else vec


def _cosine_dist(a: np.ndarray, b: np.ndarray) -> float:
    return float(1.0 - np.dot(a, b))


def _augment_bgr(img: np.ndarray) -> List[np.ndarray]:
    h, w = img.shape[:2]
    variants: List[np.ndarray] = [
        img,
        cv2.flip(img, 1),
        cv2.convertScaleAbs(img, alpha=0.75, beta=-20),
        cv2.convertScaleAbs(img, alpha=1.25, beta=20),
        cv2.GaussianBlur(img, (3, 3), 0),
    ]
    if AUGMENT_COUNT >= 6:
        M = cv2.getRotationMatrix2D((w / 2, h / 2), 5, 1.0)
        variants.append(cv2.warpAffine(img, M, (w, h)))
    if AUGMENT_COUNT >= 7:
        M = cv2.getRotationMatrix2D((w / 2, h / 2), -5, 1.0)
        variants.append(cv2.warpAffine(img, M, (w, h)))
    return variants[:AUGMENT_COUNT]


def _embed(img_bgr: np.ndarray) -> Optional[np.ndarray]:
    """
    Extract a normalised ArcFace embedding from a BGR image.

    Strategy (CPU-accuracy fix):
      1. Try 'skip' first — the input is already a face crop from _pre_crop_face(),
         so asking DeepFace to re-detect a face inside it often fails or misaligns.
         'skip' passes the crop straight to ArcFace → better embeddings.
      2. Fall back to 'opencv' only if 'skip' returns no result (e.g. very small ROI).
    """
    for detector in ("skip", DEEPFACE_DETECTOR):
        try:
            reps = DeepFace.represent(
                img_path          = img_bgr,
                model_name        = DEEPFACE_MODEL,
                detector_backend  = detector,
                enforce_detection = False,
                align             = (detector != "skip"),  # align only when using a real detector
            )
            if reps and len(reps[0].get('embedding', [])) > 0:
                vec = np.array(reps[0]['embedding'], dtype=np.float32)
                return _l2_norm(vec)
        except Exception as e:
            print(f"[WARNING] DeepFace.represent ({detector}): {e}")
    return None


def _pre_crop_face(img_bgr: np.ndarray) -> np.ndarray:
    gray  = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    faces = _face_cascade.detectMultiScale(gray, 1.05, 4, minSize=(40, 40))
    if len(faces) == 0:
        return img_bgr
    x, y, w, h = max(faces, key=lambda f: f[2] * f[3])
    pad_x = int(w * 0.20)
    pad_y = int(h * 0.20)
    ih, iw = img_bgr.shape[:2]
    x1 = max(0, x - pad_x);  y1 = max(0, y - pad_y)
    x2 = min(iw, x + w + pad_x); y2 = min(ih, y + h + pad_y)
    return img_bgr[y1:y2, x1:x2]


# ── LBPH helpers ──────────────────────────────────────────────────────────────

def _align_face_gray(gray: np.ndarray) -> np.ndarray:
    h, w = gray.shape
    eq = cv2.equalizeHist(gray)
    eyes = _eye_cascade.detectMultiScale(
        eq, 1.1, 4,
        minSize=(int(w * 0.12), int(h * 0.08)),
        maxSize=(int(w * 0.55), int(h * 0.45)),
    )
    if len(eyes) < 2:
        return gray
    eyes = sorted(eyes, key=lambda e: e[0])[:2]
    (x1, y1, w1, h1), (x2, y2, w2, h2) = eyes
    cx1, cy1 = x1 + w1 // 2, y1 + h1 // 2
    cx2, cy2 = x2 + w2 // 2, y2 + h2 // 2
    angle = math.degrees(math.atan2(cy2 - cy1, cx2 - cx1))
    M = cv2.getRotationMatrix2D(((cx1 + cx2) / 2, (cy1 + cy2) / 2), angle, 1.0)
    return cv2.warpAffine(gray, M, (w, h), flags=cv2.INTER_LINEAR)


def _prepare_lbph_crop(face_gray: np.ndarray) -> np.ndarray:
    return cv2.equalizeHist(cv2.resize(_align_face_gray(face_gray), (100, 100)))


def _try_detect_face_gray(gray: np.ndarray) -> Optional[np.ndarray]:
    for sf, mn, ms in [(1.1, 5, (40, 40)), (1.1, 3, (30, 30)), (1.05, 3, (20, 20)), (1.05, 1, (15, 15))]:
        faces = _face_cascade.detectMultiScale(gray, sf, mn, minSize=ms)
        if len(faces) > 0:
            x, y, w, h = max(faces, key=lambda f: f[2] * f[3])
            return gray[y:y + h, x:x + w]
    return None


def _augment_lbph(face: np.ndarray) -> List[np.ndarray]:
    samples = [face, cv2.flip(face, 1)]
    for a, b in [(0.80, -20), (1.20, 20), (0.70, -30), (1.30, 30)]:
        s = cv2.convertScaleAbs(face, alpha=a, beta=b)
        samples += [s, cv2.flip(s, 1)]
    h, w = face.shape
    cx, cy = w / 2, h / 2
    for ang in (-7, 7, -4, 4):
        M = cv2.getRotationMatrix2D((cx, cy), ang, 1.0)
        samples.append(cv2.warpAffine(face, M, (w, h)))
    samples.append(cv2.GaussianBlur(face, (3, 3), 0))
    return samples


# ══════════════════════════════════════════════════════════════════════════════
#  DATABASE LOADING
# ══════════════════════════════════════════════════════════════════════════════

def _load_db() -> None:
    global _db_loaded
    if _db_loaded:
        return
    if _USE_DEEPFACE:
        _load_deepface_db()
    else:
        _load_lbph_db()
    _db_loaded = True


def _load_deepface_db() -> None:
    global _known_embeddings, _person_threshold

    if not os.path.exists(_photo_cache_path):
        print(f"[ERROR] photo_cache not found: {_photo_cache_path}")
        return

    print(f"[face] Loading embeddings — model={DEEPFACE_MODEL}  detector=skip(primary)")
    print("[face] (First run downloads ArcFace weights ~170 MB — please wait)\n")

    for folder in sorted(os.listdir(_photo_cache_path)):
        folder_path = os.path.join(_photo_cache_path, folder)
        if not os.path.isdir(folder_path):
            continue

        img_files = [
            f for f in os.listdir(folder_path)
            if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp'))
        ]
        if not img_files:
            print(f"[WARNING] {folder!r} has no images — skipping")
            continue

        # Warn if there are too few source photos — accuracy will suffer.
        if len(img_files) < 3:
            print(
                f"[WARNING] {folder!r} has only {len(img_files)} source photo(s).\n"
                f"          Accuracy improves significantly with 3–5 varied photos\n"
                f"          (different angles, lighting, with/without glasses)."
            )

        person_vecs: List[np.ndarray] = []

        for img_file in img_files:
            img = _imread_unicode(os.path.join(folder_path, img_file))
            if img is None:
                continue

            # _pre_crop_face tightens to the face region before augmentation.
            # This is critical — augmenting a full-body or loose shot produces
            # embeddings that don't cluster tightly around the true face embedding.
            img_cropped = _pre_crop_face(img)

            # Resize to a consistent input size before augmenting.
            # ArcFace was trained on 112×112; giving it wildly different sizes
            # on CPU (without GPU-accelerated resize) increases embedding noise.
            target = (160, 160)
            img_cropped = cv2.resize(img_cropped, target, interpolation=cv2.INTER_LINEAR)

            for variant in _augment_bgr(img_cropped):
                vec = _embed(variant)
                if vec is not None:
                    person_vecs.append(vec)
                    _known_embeddings.append((folder, vec))

        if not person_vecs:
            print(
                f"[WARNING] {folder!r} — ZERO embeddings extracted!\n"
                f"          → Make sure the photo clearly shows a face.\n"
                f"          → Try renaming the image to photo.jpg (ASCII only)."
            )
            continue

        self_dists = [
            _cosine_dist(person_vecs[i], person_vecs[j])
            for i in range(len(person_vecs))
            for j in range(i + 1, len(person_vecs))
        ]

        if not self_dists:
            adaptive = DEEPFACE_THRESHOLD
            worst_self = best_self = 0.0
        else:
            worst_self = round(max(self_dists), 4)
            best_self  = round(min(self_dists), 4)
            # Adaptive threshold: give each person a little breathing room above
            # their own worst-case intra-distance, but cap it at DEEPFACE_THRESHOLD.
            # On CPU the cap is now 0.62, so this rarely triggers — but it protects
            # people whose photos have high intra-variance (glasses, hat, etc.).
            adaptive   = round(min(DEEPFACE_THRESHOLD, worst_self + 0.20), 4)

        _person_threshold[folder] = adaptive
        print(
            f"[face] ✓ {folder}\n"
            f"         photos={len(img_files)}  embeddings={len(person_vecs)}  "
            f"self_dist={best_self}–{worst_self}  threshold={adaptive}"
        )

    people = len({n for n, _ in _known_embeddings})
    print(f"\n[face] DB ready — {len(_known_embeddings)} embeddings, {people} person(s).")

    if people == 0:
        print(
            "\n[ERROR] No embeddings were loaded!\n"
            "  Checklist:\n"
            "  1. Is photo_cache/ in the same folder as this .py file?\n"
            "  2. Do the photos actually show a face (not full body / group)?\n"
            "  3. Are image filenames plain ASCII (no Arabic letters in filename)?\n"
            "  4. Did ArcFace weights finish downloading? (check internet)\n"
            "  5. Are you running inside the Python 3.11 venv (.venv311)?"
        )

def _load_lbph_db() -> None:
    global _recogniser, _label_map
    try:
        cv2.face.LBPHFaceRecognizer_create()
    except AttributeError:
        print("[ERROR] cv2.face missing — pip install opencv-contrib-python")
        return
    if not os.path.exists(_photo_cache_path):
        print(f"[ERROR] photo_cache not found: {_photo_cache_path}")
        return

    print(f"[face] Training LBPH from: {_photo_cache_path}")
    all_faces:  List[np.ndarray] = []
    all_labels: List[int]        = []
    label_id = 0

    for folder in sorted(os.listdir(_photo_cache_path)):
        folder_path = os.path.join(_photo_cache_path, folder)
        if not os.path.isdir(folder_path):
            continue
        img_files = [
            f for f in os.listdir(folder_path)
            if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp'))
        ]
        if not img_files:
            continue

        crops: List[np.ndarray] = []
        for img_file in img_files:
            img = _imread_unicode(os.path.join(folder_path, img_file))
            if img is None:
                continue
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            face = _try_detect_face_gray(gray)
            if face is None:
                hh, ww = gray.shape
                face = gray[0:int(hh * 0.45), int(ww * 0.15):int(ww * 0.85)]
                print(f"[WARNING] No face detected in {img_file} — using top-crop fallback")
            crops.extend(_augment_lbph(_prepare_lbph_crop(face)))

        if not crops:
            continue
        _label_map[label_id] = folder
        all_faces.extend(crops)
        all_labels.extend([label_id] * len(crops))
        print(f"[face] ✓ {folder} → {len(crops)} sample(s)")
        label_id += 1

    if not all_faces:
        print("[ERROR] LBPH: no training samples found.")
        return

    _recogniser = cv2.face.LBPHFaceRecognizer_create(
        radius=1, neighbors=8, grid_x=8, grid_y=8
    )
    _recogniser.train(all_faces, np.array(all_labels, dtype=np.int32))
    print(f"[face] LBPH ready — {label_id} person(s), {len(all_faces)} sample(s).")


# ══════════════════════════════════════════════════════════════════════════════
#  RECOGNITION (called from background thread only)
# ══════════════════════════════════════════════════════════════════════════════

def _recognize_deepface(face_roi_bgr: np.ndarray) -> Tuple[str, float]:
    """
    ArcFace recognition with a margin guard.

    The margin guard rejects a match when the best and second-best candidates
    are too close together — that situation means the face is ambiguous and
    calling it either name would be a coin-flip.  Returning Unknown in that
    case is more honest and prevents wrong-name flickering.
    """
    if not _known_embeddings:
        return "Unknown", 0.0

    # Resize ROI to 160×160 before embedding — same as DB-load resize.
    # Inconsistent sizes between DB and query are a major source of embedding drift on CPU.
    face_roi_bgr = cv2.resize(face_roi_bgr, (160, 160), interpolation=cv2.INTER_LINEAR)

    query = _embed(face_roi_bgr)
    if query is None:
        return "Unknown", 0.0

    best_per_person: Dict[str, float] = {}
    for name, stored in _known_embeddings:
        d = _cosine_dist(query, stored)
        if name not in best_per_person or d < best_per_person[name]:
            best_per_person[name] = d

    if not best_per_person:
        return "Unknown", 0.0

    sorted_persons = sorted(best_per_person.items(), key=lambda x: x[1])
    best_name, best_dist = sorted_persons[0]
    threshold = _person_threshold.get(best_name, DEEPFACE_THRESHOLD)

    if best_dist > threshold:
        return "Unknown", 0.0

    # Margin guard: if there's a second candidate and the gap between best and
    # second is smaller than 0.08, the match is ambiguous — return Unknown.
    if len(sorted_persons) > 1:
        second_dist = sorted_persons[1][1]
        margin = second_dist - best_dist
        if margin < 0.08:
            return "Unknown", 0.0

    confidence = round(min(0.99, 1.0 - best_dist / threshold), 3)
    return best_name, confidence


def _recognize_lbph(face_roi_bgr: np.ndarray) -> Tuple[str, float]:
    if _recogniser is None:
        return "Unknown", 0.0
    gray  = cv2.cvtColor(face_roi_bgr, cv2.COLOR_BGR2GRAY)
    tight = _try_detect_face_gray(gray)
    prep  = _prepare_lbph_crop(tight if tight is not None else gray)
    try:
        label, dist = _recogniser.predict(prep)
    except Exception as e:
        print(f"[WARNING] LBPH predict: {e}")
        return "Unknown", 0.0
    if dist > 1e10 or dist >= LBPH_THRESHOLD:
        return "Unknown", 0.0
    confidence = round(min(0.99, max(0.0, 1.0 - dist / LBPH_THRESHOLD)), 3)
    return _label_map.get(label, "Unknown"), confidence


def _recognize(face_roi_bgr: np.ndarray) -> Tuple[str, float]:
    return _recognize_deepface(face_roi_bgr) if _USE_DEEPFACE else _recognize_lbph(face_roi_bgr)


# ══════════════════════════════════════════════════════════════════════════════
#  IoU TRACKER  (with hysteresis)
# ══════════════════════════════════════════════════════════════════════════════

def _iou(a: Tuple, b: Tuple) -> float:
    ax1, ay1, aw, ah = a
    bx1, by1, bw, bh = b
    ix1 = max(ax1, bx1); iy1 = max(ay1, by1)
    ix2 = min(ax1 + aw, bx1 + bw); iy2 = min(ay1 + ah, by1 + bh)
    inter = max(0, ix2 - ix1) * max(0, iy2 - iy1)
    if inter == 0:
        return 0.0
    union = aw * ah + bw * bh - inter
    return inter / union if union > 0 else 0.0


def _ema_box(old: Tuple, new: Tuple, alpha: float) -> Tuple:
    return tuple(int(alpha * n + (1 - alpha) * o) for o, n in zip(old, new))


def _update_tracks(detections: List[Tuple]) -> None:
    global _tracks, _next_track_id
    matched_tids: set = set()
    matched_dids: set = set()

    for did, det in enumerate(detections):
        best_iou = IOU_MIN
        best_tid = None
        for tid, td in _tracks.items():
            s = _iou(td['smooth_box'], det)
            if s > best_iou:
                best_iou = s
                best_tid = tid
        if best_tid is not None:
            t = _tracks[best_tid]
            t['smooth_box'] = _ema_box(t['smooth_box'], det, BOX_EMA_ALPHA)
            t['raw_box'] = det
            t['missing'] = 0
            matched_tids.add(best_tid)
            matched_dids.add(did)

    for did, det in enumerate(detections):
        if did in matched_dids:
            continue
        _tracks[_next_track_id] = {
            'smooth_box': det, 'raw_box': det, 'missing': 0,
            'votes': deque(maxlen=VOTE_WINDOW),
            'last_name': "Unknown", 'last_conf': 0.0, 'frames_seen': 0,
            'in_flight': 0,              # number of pool tasks currently running
            'unknown_streak': 0,
        }
        _next_track_id += 1

    stale = []
    for tid, td in _tracks.items():
        if tid not in matched_tids:
            td['missing'] += 1
            if td['missing'] > TRACK_MAX_MISSING:
                stale.append(tid)
    for tid in stale:
        del _tracks[tid]


def _apply_recog_results() -> None:
    """
    Drain the result queue and apply votes with hysteresis.
    A confirmed identity only flips back to Unknown after UNKNOWN_FLIP_COUNT
    consecutive Unknown votes, preventing flicker on partial occlusion.
    """
    while True:
        try:
            track_id, name, conf = _recog_result_q.get_nowait()
        except queue.Empty:
            break

        with _state_lock:
            t = _tracks.get(track_id)
            if t is None:
                continue

            t['in_flight'] = max(0, t.get('in_flight', 0) - 1)
            t['votes'].append(name)

            # Majority vote
            counts: Dict[str, int] = {}
            for v in t['votes']:
                counts[v] = counts.get(v, 0) + 1
            winner = max(counts, key=lambda n: counts[n])

            # Hysteresis: don't flip confirmed identity to Unknown easily
            if winner == "Unknown" and t['last_name'] != "Unknown":
                t['unknown_streak'] = t.get('unknown_streak', 0) + 1
                if t['unknown_streak'] < UNKNOWN_FLIP_COUNT:
                    continue  # keep current confirmed name
            else:
                t['unknown_streak'] = 0

            t['last_name'] = winner
            t['last_conf'] = conf if winner != "Unknown" else 0.0


# ══════════════════════════════════════════════════════════════════════════════
#  PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

def detect_faces(frame: np.ndarray) -> Tuple[List[Dict], np.ndarray]:
    """
    Detect, track, and recognise faces in a BGR frame.

    Recognition runs asynchronously in a background thread so this function
    NEVER blocks on ArcFace inference — frame rate stays smooth.

    Returns
    -------
    faces     : list of {'bbox':(x,y,w,h), 'name':str, 'confidence':float}
    annotated : BGR frame with boxes and labels drawn
    """
    global _frame_counter
    _frame_counter += 1

    if not _db_loaded:
        _load_db()

    # ── Detection ─────────────────────────────────────────────────────────────
    gray    = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    raw_det = _face_cascade.detectMultiScale(gray, 1.1, 6, minSize=(50, 50))
    detections = [tuple(map(int, d)) for d in raw_det] if len(raw_det) > 0 else []

    with _state_lock:
        _update_tracks(detections)

    # ── Apply any recognition results that arrived from the background thread ─
    _apply_recog_results()

    # ── Dispatch new recognition requests (non-blocking) ─────────────────────
    run_recog = (_frame_counter % RECOG_EVERY_N == 0)

    annotated = frame.copy()
    faces_result: List[Dict] = []

    with _state_lock:
        tracks_snapshot = list(_tracks.items())

    for tid, tdata in tracks_snapshot:
        x, y, w, h = tdata['smooth_box']
        x  = max(0, x);  y  = max(0, y)
        x2 = min(frame.shape[1], x + w)
        y2 = min(frame.shape[0], y + h)
        if x2 <= x or y2 <= y:
            continue

        tdata['frames_seen'] += 1

        # Submit a recognition job to the pool if:
        #   - it's a recognition frame
        #   - the track has been seen at least 2 frames (avoids one-frame ghosts)
        #   - no task is already in-flight for this track
        if run_recog and tdata['frames_seen'] >= 2 and tdata.get('in_flight', 0) == 0:
            roi = frame[y:y2, x:x2].copy()
            tdata['in_flight'] = tdata.get('in_flight', 0) + 1
            _recog_pool.submit(_recog_task, tid, roi)

        name = tdata['last_name']
        conf = tdata['last_conf']
        faces_result.append({'bbox': (x, y, x2 - x, y2 - y), 'name': name, 'confidence': conf})

        known = (name != "Unknown")
        color = (0, 220, 90) if known else (0, 140, 255)
        cv2.rectangle(annotated, (x, y), (x2, y2), color, 2)

        label = f"{name}  {conf:.0%}" if known else "Unknown"
        (tw, th), bl = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.58, 2)
        ly1 = max(0, y - th - bl - 6)
        cv2.rectangle(annotated, (x, ly1), (x + tw + 8, y), color, -1)
        cv2.putText(annotated, label, (x + 4, y - bl - 2),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.58, (0, 0, 0), 2, cv2.LINE_AA)

    return faces_result, annotated


def reset_recognition_state() -> None:
    """Clear tracker state. Call when switching cameras or starting a new session."""
    global _tracks, _next_track_id, _frame_counter
    with _state_lock:
        _tracks.clear()
        _next_track_id = 0
        _frame_counter = 0
    # Drain result queue
    while not _recog_result_q.empty():
        try:
            _recog_result_q.get_nowait()
        except queue.Empty:
            break