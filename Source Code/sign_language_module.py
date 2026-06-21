"""
sign_language_module.py
Accurate hand-gesture detection via MediaPipe 0.10+ HandLandmarker Tasks API.
Uses 21 precise finger-joint landmarks instead of unreliable skin-colour blobs.

Gestures
--------
  OPEN_HAND   -> "Question"    (raise whole hand - 4-5 fingers up)
  ONE_FINGER  -> "Bathroom"    (only index finger up)
  CLOSED_FIST -> "Water/Drink" (all fingers curled into fist)
  none        -> no hand / ambiguous
"""

import os
import urllib.request
import cv2
import mediapipe as mp
import numpy as np

# ---------------------------------------------------------------------------
# 1. Auto-download the hand landmarker model file (first run only)
# ---------------------------------------------------------------------------
_MODEL_URL = (
    "https://storage.googleapis.com/mediapipe-models/"
    "hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task"
)
_MODEL_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "hand_landmarker.task"
)


def _ensure_model() -> bool:
    if os.path.exists(_MODEL_PATH) and os.path.getsize(_MODEL_PATH) > 100_000:
        return True
    print("[sign] Downloading hand_landmarker.task (one-time setup)...")
    try:
        urllib.request.urlretrieve(_MODEL_URL, _MODEL_PATH)
        print(f"[sign] Model saved to {_MODEL_PATH}")
        return True
    except Exception as exc:
        print(f"[sign] Download failed: {exc}")
        print("[sign] Using skin-contour fallback instead.")
        return False


_HAS_MODEL = _ensure_model()

# ---------------------------------------------------------------------------
# 2. Build the HandLandmarker (MediaPipe 0.10 Tasks API)
# ---------------------------------------------------------------------------
_landmarker = None

if _HAS_MODEL:
    try:
        _opts = mp.tasks.vision.HandLandmarkerOptions(
            base_options=mp.tasks.BaseOptions(model_asset_path=_MODEL_PATH),
            running_mode=mp.tasks.vision.RunningMode.VIDEO,
            num_hands=1,
            min_hand_detection_confidence=0.6,
            min_hand_presence_confidence=0.6,
            min_tracking_confidence=0.5,
        )
        _landmarker = mp.tasks.vision.HandLandmarker.create_from_options(_opts)
        _CONNECTIONS = mp.tasks.vision.HandLandmarksConnections.HAND_CONNECTIONS
        print("[sign] HandLandmarker ready.")
    except Exception as exc:
        print(f"[sign] HandLandmarker init failed: {exc}")
        _landmarker = None

# ---------------------------------------------------------------------------
# 3. Constants
# ---------------------------------------------------------------------------
GESTURE_LABELS = {
    "OPEN_HAND":   "Question",
    "ONE_FINGER":  "Interception",
    "CLOSED_FIST": "Bathroom",
    "none":        "none",
}

GESTURE_COLORS = {        # BGR
    "OPEN_HAND":   (0,   255, 200),
    "ONE_FINGER":  (0,   200, 255),
    "CLOSED_FIST": (200, 100, 255),
    "none":        (200, 200, 200),
}

#          THUMB  INDEX  MIDDLE  RING  PINKY
_TIP_IDS = [4,    8,     12,     16,   20]
_PIP_IDS = [3,    6,     10,     14,   18]   # one joint below tip
_MCP_IDS = [2,    5,      9,     13,   17]   # knuckle

# ---------------------------------------------------------------------------
# 4. Gesture classifier  (works on MediaPipe NormalizedLandmark list)
# ---------------------------------------------------------------------------
def _classify(lm) -> tuple:
    """Return (gesture_key, confidence) from 21 landmarks."""

    wrist     = lm[0]
    palm_len  = abs(lm[_MCP_IDS[2]].y - wrist.y) + 1e-6
    palm_w    = abs(lm[_MCP_IDS[1]].x - lm[_MCP_IDS[4]].x) + 1e-6

    extended = []

    # Thumb: horizontal distance from wrist > half palm width
    extended.append(abs(lm[_TIP_IDS[0]].x - wrist.x) > palm_w * 0.5)

    # Index -> Pinky: tip must be clearly above PIP joint (2 % of palm height)
    for i in range(1, 5):
        extended.append(lm[_TIP_IDS[i]].y < lm[_PIP_IDS[i]].y - 0.02 * palm_len)

    n_fingers = sum(extended[1:])   # thumb excluded from rules

    # ---- rules (most specific first) ----
    if n_fingers == 0:
        conf = 0.95 if not extended[0] else 0.80
        return "CLOSED_FIST", conf

    if extended[1] and not extended[2] and not extended[3] and not extended[4]:
        return "ONE_FINGER", 0.92

    if n_fingers >= 3:
        return "OPEN_HAND", 0.95 if n_fingers >= 4 else 0.78

    return "none", 0.0


# ---------------------------------------------------------------------------
# 5. Skeleton drawing helper
# ---------------------------------------------------------------------------
def _draw_skeleton(frame, lm, h, w):
    pts = [(int(l.x * w), int(l.y * h)) for l in lm]
    for conn in _CONNECTIONS:
        cv2.line(frame, pts[conn.start], pts[conn.end], (255, 255, 255), 1)
    for i, pt in enumerate(pts):
        is_tip = i in _TIP_IDS
        cv2.circle(frame, pt, 6 if is_tip else 3,
                   (0, 255, 0) if is_tip else (200, 200, 200), -1)


# ---------------------------------------------------------------------------
# 6. Fallback: skin-contour + convexity defects  (no model file needed)
# ---------------------------------------------------------------------------
def _fallback_detect(frame):
    annotated = frame.copy()
    h, w = frame.shape[:2]

    hsv  = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(hsv, (0,  15, 60), (25,  255, 255))
    mask |= cv2.inRange(hsv, (160, 15, 60), (180, 255, 255))

    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, k, iterations=2)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN,  k, iterations=1)
    mask = cv2.dilate(mask, k, iterations=1)

    contours, _ = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    gesture_key, confidence = "none", 0.0

    if contours:
        hand = max(contours, key=cv2.contourArea)
        if cv2.contourArea(hand) > 3000:
            hull_idx = cv2.convexHull(hand, returnPoints=False)
            hull_pts = cv2.convexHull(hand)
            solidity = cv2.contourArea(hand) / (cv2.contourArea(hull_pts) + 1e-6)
            cv2.drawContours(annotated, [hull_pts], 0, (0, 255, 0), 2)

            fingers = 0
            if len(hull_idx) >= 4:
                defects = cv2.convexityDefects(hand, hull_idx)
                if defects is not None:
                    for i in range(defects.shape[0]):
                        if defects[i, 0, 3] > 8000:
                            fingers += 1

            if solidity > 0.80 and fingers == 0:
                gesture_key, confidence = "CLOSED_FIST", 0.70
            elif fingers == 1:
                gesture_key, confidence = "ONE_FINGER",  0.60
            elif fingers >= 3:
                gesture_key, confidence = "OPEN_HAND",   0.65

            x, y, wr, hr = cv2.boundingRect(hand)
            label = GESTURE_LABELS[gesture_key]
            color = GESTURE_COLORS[gesture_key]
            cv2.putText(annotated, label, (x, y - 12),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.9, color, 2)
            cv2.rectangle(annotated, (x, y), (x + wr, y + hr), color, 1)

    return gesture_key, confidence, annotated


# ---------------------------------------------------------------------------
# 7. Public API  (called by main.py every frame)
# ---------------------------------------------------------------------------
_frame_ts_ms = 0   # VIDEO mode needs monotonically increasing timestamp


def detect_sign(frame: np.ndarray):
    """
    Args:
        frame : BGR image from OpenCV.
    Returns:
        sign_label  (str)    : human-readable gesture name
        confidence  (float)  : 0.0 – 1.0
        annotated   (ndarray): frame with overlay drawn
    """
    global _frame_ts_ms
    annotated   = frame.copy()
    gesture_key = "none"
    confidence  = 0.0
    h, w        = frame.shape[:2]

    # -- landmark path (accurate) ------------------------------------------
    if _landmarker is not None:
        _frame_ts_ms += 33          # ~30 fps; must always increase
        rgb    = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        mp_img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

        try:
            result = _landmarker.detect_for_video(mp_img, _frame_ts_ms)
        except Exception:
            result = None

        if result and result.hand_landmarks:
            lm = result.hand_landmarks[0]
            _draw_skeleton(annotated, lm, h, w)
            gesture_key, confidence = _classify(lm)

            wx = int(lm[0].x * w)
            wy = int(lm[0].y * h)
            label = GESTURE_LABELS[gesture_key]
            color = GESTURE_COLORS[gesture_key]

            cv2.putText(annotated, label,
                        (max(wx - 70, 0), min(wy + 50, h - 30)),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.9, color, 2)
            cv2.putText(annotated, f"{confidence * 100:.0f}%",
                        (max(wx - 70, 0), min(wy + 75, h - 10)),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.65, color, 1)

    # -- fallback path (skin contour) --------------------------------------
    else:
        gesture_key, confidence, annotated = _fallback_detect(frame)

    return GESTURE_LABELS[gesture_key], confidence, annotated