# MFU Shuttle Bus

โปรเจ็กต์นี้เป็นระบบ Shuttle Bus ของมหาวิทยาลัย ที่มีทั้ง
- Backend Node.js + Express + MongoDB
- Frontend Flutter (ในโฟลเดอร์ `frontend-vue`)

## โครงสร้างโปรเจ็กต์

- `backend-node/` : API และระบบหลังบ้าน
  - `app.js` : entry point ของเซิร์ฟเวอร์
  - `routes/` : routes สำหรับ auth, station, bus, report
  - `services/detector.js` : เรียกใช้งาน Python YOLO detector
  - `db.js` : เชื่อมต่อ MongoDB
  - `config.js` : การตั้งค่าเช่น Mongo URI และ secret key
  - `python/detector.py` : สคริปต์ตรวจจับวัตถุด้วย YOLO

- `frontend-vue/` : แอป Flutter สำหรับผู้ใช้งาน
  - `lib/main.dart` : entry point ของแอป
  - `lib/` : source code ของหน้าจอและบริการต่าง ๆ
  - `pubspec.yaml` : dependency ของ Flutter

## แพ็กเกจหลักที่ใช้

### Backend
- express
- cors
- body-parser
- jsonwebtoken
- mongodb
- bcrypt

### Frontend
- flutter
- google_fonts
- flutter_map
- latlong2
- http
- shared_preferences

## วิธีติดตั้งและรัน

### 1. เตรียม MongoDB

ระบบ backend จะเชื่อมต่อกับ MongoDB ที่ `mongodb://localhost:27017/` โดยค่าเริ่มต้น

ถ้ายังไม่มี MongoDB ติดตั้ง ให้ติดตั้งและรันให้เรียบร้อยก่อน

### 2. รัน backend

```bash
cd backend-node
npm install
node app.js
```

หลังรันแล้วเซิร์ฟเวอร์จะฟังที่ `http://localhost:5001`

### 3. รัน frontend

```bash
cd frontend-vue
flutter pub get
flutter run
```

หรือเลือกสตาร์ทบน Android/iOS ตามปกติ

## ข้อมูลสำคัญ

- Backend เริ่มที่พอร์ต `5001`
- MongoDB database name: `shuttlebus_system`
- Config key ใน `backend-node/config.js`
  - `MONGO_URI` : mongodb://localhost:27017/
  - `DB_NAME` : shuttlebus_system
  - `SECRET_KEY` : ใช้เข้ารหัส JWT
  - `CAMERA_URL` : URL ของกล้องสำหรับ YOLO detector

## หมายเหตุ

- Backend เรียกสคริปต์ Python โดยใช้ `python3` เพื่อรัน `python/detector.py`
- หากต้องการเปลี่ยน URL กล้องหรือข้อมูลฐานข้อมูล ให้ปรับใน `backend-node/config.js`
- แอป Flutter จะเชื่อมต่อกับ backend ผ่าน HTTP โดยใช้บริการใน `frontend-vue/lib/services`

## คำแนะนำเพิ่มเติม

- หากใช้งานบนเครื่องที่ไม่มี `python3` ให้ติดตั้งก่อน
- ตรวจสอบไฟล์ `backend-node/config.js` ว่าค่าต่าง ๆ ถูกต้องก่อนรัน
- ถ้าต้องการพัฒนาเพิ่มเติม ให้รัน backend และ frontend พร้อมกัน
