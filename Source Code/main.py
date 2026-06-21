import cv2
import time
import sys, os
import tempfile
sys.path.insert(0, os.path.dirname(__file__))
from face_recognition_module import detect_faces
from emotion_detection_module import detect_emotion, reset_smoothers, EmotionConfig
from sign_language_module import detect_sign
from csv_logger import log_detection, ensure_log_exists

# ── Configuration ──────────────────────────────────────────────────────────────
CAMERA_INDEX     = 0      # Change to 1, 2... if using external webcam
LOG_INTERVAL_SEC = 1.0    # Log to CSV every N seconds (avoid giant files)
SHOW_WINDOW      = True   # Show live OpenCV window
SAVE_FRAMES      = True   # Save frames for R dashboard display
FRAME_SAVE_DIR   = os.path.join(tempfile.gettempdir(), "ai_vision_frames")  # Temp directory for frames
FRAME_SAVE_INTERVAL = 0.1  # Save frame every N seconds (10 fps)

# ── Emotion config (tune here without touching the module) ─────────────────────
emotion_cfg = EmotionConfig(
    smoothing_window = 6,    # frames to smooth over — raise for stability
    ema_alpha        = 0.35, # lower → smoother but more lag
    min_display_confidence = 40.0,
)


def run():
    ensure_log_exists()
    
    # Create frame save directory if needed
    if SAVE_FRAMES:
        os.makedirs(FRAME_SAVE_DIR, exist_ok=True)
    
    cap = cv2.VideoCapture(CAMERA_INDEX)

    if not cap.isOpened():
        print(f"[ERROR] Cannot open camera at index {CAMERA_INDEX}")
        return

    print("[INFO] Starting AI Vision Pipeline. Press 'q' to quit.")
    if SAVE_FRAMES:
        print(f"[INFO] Saving frames to: {FRAME_SAVE_DIR}")

    # Clear any leftover smoother state from a previous session
    reset_smoothers()

    last_log_time = 0.0
    last_frame_save_time = 0.0
    frame_count   = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            print("[ERROR] Failed to grab frame.")
            break

        frame_count += 1

        # ── 1. Face Detection ──────────────────────────────────────────────────
        faces, frame = detect_faces(frame)
        face_detected = len(faces) > 0

        # Extract plain (x, y, w, h) bounding boxes for the emotion module
        face_bboxes = [face['bbox'] for face in faces]

        # ── 2. Emotion Detection (only when faces present) ─────────────────────
        emotion, emotion_conf = 'none', 0.0
        if face_detected:
            emotion, emotion_conf, frame = detect_emotion(
                frame, face_bboxes, cfg=emotion_cfg
            )
        else:
            # Reset smoothers when no face is visible so stale history
            # doesn't bleed into the next appearance
            reset_smoothers()

        # ── 3. Sign Language Detection ─────────────────────────────────────────
        sign_label, sign_conf, frame = detect_sign(frame)

        # ── 4. HUD Overlay ─────────────────────────────────────────────────────
        emotion_display = (
            f"{emotion} ({emotion_conf:.0f}%)" if emotion != 'none' else 'none'
        )
        info_lines = [
            f"Faces:   {len(faces)}",
            f"Emotion: {emotion_display}",
            f"Sign:    {sign_label}",
            f"Frame:   {frame_count}",
        ]
        for i, line in enumerate(info_lines):
            cv2.putText(frame, line, (10, 25 + i * 28),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)

        # ── 5. CSV Logging (throttled) ─────────────────────────────────────────
        now = time.time()
        if now - last_log_time >= LOG_INTERVAL_SEC:
            recognized_names = [f['name'] for f in faces if f['name'] != 'Unknown']
            recognized_str   = ', '.join(recognized_names) if recognized_names else ''

            log_detection(
                face_detected      = face_detected,
                face_count         = len(faces),
                emotion            = emotion,
                emotion_confidence = emotion_conf,
                sign_label         = sign_label,
                sign_confidence    = sign_conf,
                recognized_students= recognized_str,
            )
            last_log_time = now

        # ── 6. Display ─────────────────────────────────────────────────────────
        if SHOW_WINDOW:
            cv2.imshow('AI Vision Pipeline', frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                print("[INFO] Quit signal received.")
                break
        
        # ── 7. Save Frame for R Dashboard (throttled) ──────────────────────────
        if SAVE_FRAMES:
            now = time.time()
            if now - last_frame_save_time >= FRAME_SAVE_INTERVAL:
                try:
                    frame_path = os.path.join(FRAME_SAVE_DIR, "current_frame.jpg")
                    cv2.imwrite(frame_path, frame)
                    last_frame_save_time = now
                except Exception as e:
                    print(f"[WARNING] Failed to save frame: {e}")

    cap.release()
    cv2.destroyAllWindows()
    reset_smoothers()
    print("[INFO] Pipeline stopped.")


if __name__ == '__main__':
    run()