# **Fountaine**

*Hydroponic Monitoring App — Flutter + Firebase + MQTT*

---

## **Table of Contents**

* **Project Info**
* **Tech Stack**
* **Dependencies**
* **Architecture**

  * Pattern
  * Layers
* **Features**
* **IoT & MQTT Flow**
* **Environment Variables**
* **Project Structure**
* **Setup & Installation**
* **Build & Deployment**
* **Troubleshooting**
* **Future Stack Sections (Template)**
* **License**

---

## **Project Info**

Fountaine adalah aplikasi monitoring hidroponik berbasis mobile yang menyediakan pemantauan kondisi tanaman secara real-time menggunakan teknologi IoT. Dibangun menggunakan Flutter dan Firebase dengan komunikasi MQTT, aplikasi ini memungkinkan pengguna melihat data sensor secara instan dan akurat.

**Detail Informasi:**

* **Name:** Fountaine
* **Category:** IoT Hydroponic Monitoring App
* **Type:** Mobile Application (Flutter)
* **Platform:** Android & iOS
* **Minimum Flutter SDK:** 3.35.0 – 4.x
* **MQTT Transport:** TCP (TLS Optional)

---

## **Tech Stack — Core**

| Layer            | Technology     |
| ---------------- | -------------- |
| Mobile Framework | Flutter 3.38.1 |
| Language         | Dart 3.10.0    |
| Backend Cloud    | Firebase       |
| Authentication   | Firebase Auth  |
| Realtime IoT     | MQTT           |
| State Management | Riverpod       |
| Local Storage    | SQLite         |
| Build System     | Gradle 8.12    |
| JVM              | Java 17        |
| Node Tools       | Node.js 22.19  |

---

## **Dependencies — Flutter Packages**

| Package            | Version  | Description             |
| ------------------ | -------- | ----------------------- |
| cupertino_icons    | ^1.0.8   | iOS icons               |
| firebase_core      | ^4.1.0   | Firebase core           |
| firebase_auth      | ^6.0.2   | Authentication          |
| firebase_messaging | ^16.0.3  | Push notifications      |
| cloud_firestore    | ^6.0.1   | Firestore DB            |
| firebase_analytics | ^12.0.1  | Analytics               |
| firebase_app_check | ^0.4.0+1 | App verification        |
| mqtt_client        | ^10.11.1 | MQTT client             |
| shared_preferences | ^2.5.3   | Local key-value storage |
| fl_chart           | ^1.1.1   | Charts & graphs         |
| flutter_riverpod   | ^3.0.3   | State management        |
| intl               | ^0.20.2  | Date formatting         |
| url_launcher       | ^6.3.0   | External URL launcher   |
| flutter_dotenv     | ^6.0.0   | Environment variables   |
| rxdart             | 0.28.0   | Reactive extensions     |
| http               | ^1.5.0   | HTTP requests           |
| sqflite            | ^2.4.2   | SQLite database         |
| path               | ^1.9.1   | File system helper      |
| crypto             | ^3.0.6   | Hash & crypto utils     |
| uuid               | ^4.5.1   | UUID generator          |
| tflite_flutter     | ^0.12.1  | TensorFlow Lite         |

---

## **Architecture**

### **Pattern**

Aplikasi ini menggunakan pendekatan **Clean-ish Architecture** dengan pemisahan kode secara jelas untuk meningkatkan maintainability dan skalabilitas.

Flow utama:
**Presentation Layer → State Management → Domain Layer → Data Layer → Device/Service Layer**

### **Layers Explanation**

* **Presentation Layer** — UI, widget, komponen visual (folder `features/`)
* **State Layer** — Riverpod untuk state management global (folder `providers/`)
* **Domain Layer** — Entities & logic rules (folder `domain/`)
* **Data Layer** — Repository, Firestore, SQLite, mapping (folder `data/`, `models/`)
* **Device Layer** — MQTT, Firebase services, storage, network utilities (folder `services/`)

---

## **Features**

| Feature              | Description                     |
| -------------------- | ------------------------------- |
| Login/Register       | Firebase Authentication         |
| Dashboard Monitoring | Real-time MQTT sensor data      |
| History Logs         | Optional Firestore history      |
| Chart Visualization  | Sensor charts via fl_chart      |
| Environment Config   | Secure .env settings            |
| Connectivity Status  | Real-time connection tracking   |
| Preferences          | Local settings (theme, session) |

---

## **IoT & MQTT Flow**

```
[Sensor Node IoT]
        ↓ Publish (JSON Payload)
[MQTT Broker]
        ↓ Subscribe (mqtt_client)
[Flutter App]
        ↓ Providers (Riverpod)
[UI Update]
```

**Additional Notes:**

* QoS 0/1 supported
* Auto reconnect enabled
* Username/Password optional
* JSON decoded into provider layer

---

## **Data Flow Diagram**

```
         +-------------+
         | MQTT Broker |
         +------^------+
                |
                | JSON Payload
                v
      +---------------------+
      | MQTT Service        |
      +----------+----------+
                 |
                 | Stream Data
                 v
       +---------------------+
       | Riverpod Providers  |
       +----------+----------+
                 |
                 | State Updates
                 v
       +---------------------+
       | UI (Features/*)     |
       +---------------------+
```

---

## **Environment Variables**

| Variable           | Description               |
| ------------------ | ------------------------- |
| MQTT_BROKER_URL    | Broker URL                |
| MQTT_PORT          | MQTT port number          |
| MQTT_USERNAME      | Username (optional)       |
| MQTT_PASSWORD      | Password (optional)       |
| MQTT_TOPIC_SENSOR  | Topic for receiving data  |
| MQTT_TOPIC_CONTROL | Topic for sending command |

---

## **Project Structure (Simplified Modern)**

```txt
lib/
├── app/               # Routing & navigation
├── core/              # Constants, helpers, configs
├── data/              # Repository & data sources (SQLite/Firestore)
├── domain/            # Entities & logic rules
├── enums/             # App enums
├── features/          # All UI screens/modules
│   ├── auth/          # Login, register, verify, forgot
│   ├── home/
│   ├── monitor/
│   ├── history/
│   ├── notifications/
│   ├── profile/
│   ├── settings/
│   ├── splash/
│   └── add_kit/
├── models/            # DTOs & models
├── providers/         # Riverpod providers
├── services/          # Firebase, MQTT, DB services
├── utils/             # Firebase options, shared utils
└── main.dart          # App entry point
```

---

## **Setup & Installation**

```txt
1. Clone
   git clone <your-repo>
   cd fountaine

2. Install
   flutter pub get

3. Env
   setup file .env

4. Run
   flutter run
```

---

## **Build & Deployment**

```txt
Android
   flutter build apk --release

iOS
   Requires macOS
   cd ios && pod install
   Add GoogleService-Info.plist
   Update Bundle ID
   Configure Signing & Capabilities
   flutter build ios --release
```

---

## **Troubleshooting**

| Issue                 | Cause                | Fix                       |
| --------------------- | -------------------- | ------------------------- |
| MQTT tidak connect    | Broker salah         | Cek .env                  |
| App nggak nerima data | Topic mismatch       | Samakan topic publish/sub |
| Firebase error        | Fingerprint kurang   | Tambah SHA-1 & SHA-256    |
| Env tidak terbaca     | Release mode         | Pastikan .env ter-embed   |
| MQTT reconnect loop   | Jaringan drop        | Aktifkan auto reconnect   |
| Payload JSON rusak    | Data IoT tidak valid | Validasi firmware IoT     |
| Firestore throttle    | Write terlalu sering | Gunakan batch/limit       |

---

## **Backend**

* Runtime
* Framework
* Database
* Realtime Engine
* Deployment Strategy

---

## **Database**

* Type
* Tables
* ORM
* Backup Strategy

---

## **Machine Learning**

* Model
* Dataset
* Platform
* Inference Format

---

## **API Docs**

* Base URL
* Auth Method
* Endpoints

---

## **Hardware**

* Board
* Sensors
* PCB
* Firmware Repo

---

## **UI/UX**

* Design System
* Palette
* Typography
* Components

---

## **License**

© **Wisnu 2025** — MIT License

---