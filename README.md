# fountaine

Dart versi 3.8.1
Flutter versi 3.35.3
cupertino_icons: ^1.0.8
firebase_core: ^4.1.0
firebase_auth: ^6.0.2
cloud_firestore: ^6.0.1
firebase_analytics: ^12.0.1
mqtt_client: ^10.11.1
shared_preferences: ^2.5.3
fl_chart: ^1.1.1
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
java 17.0.12 2024-07-16 LTS
node v22.19.0

# State Management 

Riverpod

# flowchart

[Start]
   │
   ▼
[Splash Screen]
   │ (Logo + loading)
   ▼
[Login / Register Screen]
   ├─> [Login] 
   │     ├─ Jika Email/Password salah → Pop-up: "Email atau Password salah"
   │     ├─ Jika Email tidak valid → Pop-up: "Format email tidak valid"
   │     └─ Jika sukses → Dashboard
   │
   └─> [Register] 
         ├─ Jika Password terlalu lemah → Pop-up: "Password terlalu lemah"
         ├─ Jika Email sudah terdaftar → Pop-up: "Email sudah digunakan"
         └─ Jika sukses → Verify Screen → balik ke Login
   │
   ▼
[Home Page]
    |__ Tombol [Monitor]
    |       ▼
    |     [Monitor Screen]
    |      |
    |      |__ Jika belum ada Kit → tampil “Tambahkan Kit” + tombol Add Kit
    |      |__ Jika ada Kit → tampil data sensor + last updated + status online/offline
   │
   ├─ Tombol [Notification] 
   │     ▼
   │  [History Screen]
   │     ├─ Tampil kalender rapi
   │     └─ List data per tanggal
   │     └─ Back ke Home Page
   │
   ├─ Tombol [Add Kit]
   │     ▼
   │  [Add Kit Screen]
   │     ├─ Input ID Kit + nama Kit
   │     └─ [Simpan] → 
   │          └─ Pop-up Konfirmasi:
   │              "Kit berhasil ditambahkan"
   │              Tombol [OK] → balik ke Home Page
   │
   └─ Tombol [Settings]
         ▼
      [Settings Screen]
         ├─ Profile 
         ├─ Ganti bahasa
         ├─ Tampilkan versi app
         └─ Logout
             ▼
          Pop-up Konfirmasi:
          "Yakin ingin logout?"
          ├─ [Ya] → kembali ke Login
          └─ [Batal] → tetap di Settings
