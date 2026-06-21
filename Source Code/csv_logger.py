import csv
import os
from datetime import datetime

LOG_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'detections_log.csv')

HEADERS = [
    'timestamp',
    'face_detected',
    'face_count',
    'recognized_students',  # ← NEW: comma-separated student names
    'emotion',
    'emotion_confidence',
    'sign_label',
    'sign_confidence',
    'sign_meaning',          # plain-English interpretation
]

# Maps the human-readable label back to a short classroom meaning
_SIGN_MEANINGS = {
    'Question':   'Student has a question',
    'Bathroom':   'Bathroom break request',
    'Water/Drink': 'Water / drink request',
    'none':       '',
}


def ensure_log_exists():
    """Create the CSV file with headers if it doesn't exist."""
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    if not os.path.exists(LOG_PATH):
        with open(LOG_PATH, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=HEADERS)
            writer.writeheader()


def log_detection(
    face_detected: bool,
    face_count: int,
    emotion: str,
    emotion_confidence: float,
    sign_label: str,
    sign_confidence: float,
    recognized_students: str = '',
):
    """Append one row to the CSV log."""
    ensure_log_exists()

    sign_label   = sign_label   if sign_label   else 'none'
    sign_meaning = _SIGN_MEANINGS.get(sign_label, '')

    row = {
        'timestamp':          datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'face_detected':      int(face_detected),
        'face_count':         face_count,
        'recognized_students': recognized_students if recognized_students else '',
        'emotion':            emotion if emotion else 'none',
        'emotion_confidence': round(emotion_confidence, 4) if emotion_confidence else 0.0,
        'sign_label':         sign_label,
        'sign_confidence':    round(sign_confidence, 4) if sign_confidence else 0.0,
        'sign_meaning':       sign_meaning,
    }

    with open(LOG_PATH, 'a', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=HEADERS)
        writer.writerow(row)
