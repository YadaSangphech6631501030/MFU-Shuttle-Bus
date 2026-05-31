from ultralytics import YOLO
import cv2
import time
from datetime import datetime
from pymongo import MongoClient
import sys

# ===== CONFIG =====
MONGO_URI = "mongodb://localhost:27017/"
DB_NAME = "shuttlebus_system"
COLLECTION = "stations"

CAMERA_URL = sys.argv[1] if len(sys.argv) > 1 else 0
SAVE_INTERVAL = 5

print("🎥 Using camera:", CAMERA_URL)

# ===== DB =====
client = MongoClient(MONGO_URI)
db = client[DB_NAME]
collection = db[COLLECTION]

# ===== YOLO =====
model = YOLO("yolov8s.pt")

def get_status(count):
    if count <= 5:
        return "LOW", (0, 255, 0)
    elif count <= 9:
        return "MEDIUM", (0, 255, 255)
    else:
        return "HIGH", (0, 0, 255)

# ===== CONNECT CAMERA =====
def connect_camera():
    print("🔄 Connecting to camera...")
    cap = cv2.VideoCapture(CAMERA_URL, cv2.CAP_FFMPEG)

    time.sleep(2)

    if not cap.isOpened():
        print("❌ Cannot connect to camera")
        return None

    print("✅ Camera connected")
    return cap

cap = connect_camera()

if cap is None:
    exit()

print("✅ Detector started")

last_save_time = 0

# ===== MAIN LOOP =====
while True:
    ret, frame = cap.read()

    # reconnect 
    if not ret:
        print("⚠️ Camera read failed reconnecting...")
        cap.release()
        cap = connect_camera()
        if cap is None:
            break
        continue

    frame = cv2.flip(frame, 1)

    # detect + track
    results = model.track(frame, persist=True, classes=[0], conf=0.3)[0]

    # ===== count =====
    if results.boxes.id is not None:
        current_ids = set(int(i) for i in results.boxes.id)
        current_count = len(current_ids)
    else:
        current_count = 0

    # ===== status =====
    status, color = get_status(current_count)

    # ===== draw =====
    annotated = frame.copy()

    if results.boxes is not None:
        for box in results.boxes.xyxy:
            x1, y1, x2, y2 = map(int, box)

            # กรอบสีเขียว
            cv2.rectangle(
                annotated,
                (x1, y1),
                (x2, y2),
                (255, 0, 0), 
                2
            )

    # ===== text =====
    cv2.putText(annotated, f"Waiting: {current_count}", (20, 40),
                cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)

    cv2.putText(annotated, f"Status: {status}", (20, 80),
                cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)

    cv2.imshow("Station 1", annotated)

    # ===== save DB =====
    current_time = time.time()

    if current_time - last_save_time >= SAVE_INTERVAL:
        try:
            collection.update_one(
    {"id": "station11"},
    {
        "$set": {
            "waiting": current_count,
            "status": status,
            "updatedAt": datetime.now()
        }
    }
)

            print(f"✅ Saved → {current_count} ({status})")

        except Exception as e:
            print("❌ DB Error:", e)

        last_save_time = current_time

    # ===== exit =====
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()