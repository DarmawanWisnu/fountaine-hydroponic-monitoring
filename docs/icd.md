============================================================
INTERFACE CONTROL DOCUMENT (ICD)
HYDROPONIC KIT ↔ APP (MQTT)
============================================================

Dokumen ini menjelaskan kontrak komunikasi antara perangkat IoT (kit)
dan aplikasi mobile menggunakan protokol MQTT.
Tujuannya agar integrasi antara sistem IoT dan aplikasi dapat dilakukan
secara konsisten, terstandarisasi, dan mudah diuji.


============================================================
1) BROKER & IDENTITAS
============================================================
Broker           : HiveMQ Cloud (TLS port 8883)
QoS Default      : 1
Kit ID Format    : String tanpa spasi (contoh: devkit-01)
ClientID (App)   : fountaine-app-{epoch}
ClientID (Kit)   : fountaine-kit-{kitId}
Authentication   : Username & Password (dari HiveMQ)
Protocol Version : MQTT 3.1.1
LWT (Last Will)  : Saat koneksi kit terputus tidak normal, broker mengirim
                   retained message ke topic status:
                   {"online": false, "ts": "2025-10-16T00:00:00Z"}


============================================================
2) TOPICS
============================================================
| Topic                    | Arah       | QoS | Retained | Keterangan                      |
|---------------------------|------------|-----|-----------|----------------------------------|
| kit/{kitId}/telemetry     | Kit → App  | 1   | No        | Data sensor periodik (~5 detik) |
| kit/{kitId}/status        | Kit ↔ App  | 1   | Yes       | Status online/offline (LWT)     |
| kit/{kitId}/control       | App → Kit  | 1   | No        | Perintah kontrol dari aplikasi  |


============================================================
3) PAYLOAD SCHEMA
============================================================

3.1 Telemetry (kit/{kitId}/telemetry)
-------------------------------------
Contoh:
 ts = 2025-10-16T00:00:00Z
 ppm = 930.0
 ph = 6.03
 tempC = 27.1
 waterLevel = 72.0

Keterangan:
 - ts          : Waktu pengambilan data (ISO 8601 UTC)
 - ppm         : Konsentrasi nutrisi (0–5000)
 - ph          : Tingkat keasaman (0–14)
 - tempC       : Suhu air (°C)
 - waterLevel  : Level air (%)

3.2 Status (kit/{kitId}/status)
-------------------------------------
Contoh:
 online = true
 ts = 2025-10-16T00:00:00Z

Catatan:
 - Retained: ON
 - Kit mengirim online:true saat berhasil connect.
 - Broker mengirim online:false saat kit terputus (LWT aktif).

3.3 Control (kit/{kitId}/control)
-------------------------------------
Contoh:
 cmd = pumpAB
 args = { ms: 500 }
 ts = 2025-10-16T00:00:00Z
 by = app

Daftar Command:
| cmd       | args                        | Deskripsi                             |
|------------|-----------------------------|----------------------------------------|
| pumpAB    | { ms: number }              | Nyalakan pompa nutrisi A+B selama ms  |
| waterAdd  | { ms: number }              | Tambahkan air                         |
| phUp      | { ms: number }              | Tambah larutan pH Up                  |
| phDown    | { ms: number }              | Tambah larutan pH Down                |
| setMode   | { mode: manual / auto }     | Ganti mode operasi                    |


============================================================
4) ATURAN SAFETY & HYSTERESIS
============================================================
- Hysteresis: ±5% dari batas ambang sensor.
- Konsensus Data: Perubahan status valid jika terjadi minimal 2 sampel berturut-turut.
- Cooldown (per sensor): 5 menit antar aksi otomatis.
- Limiter: Maksimum 3 aksi otomatis per 30 menit per sensor.
- Prioritas Manual: Saat mode manual aktif, semua aksi otomatis dinonaktifkan.


============================================================
5) CONTOH PAYLOAD
============================================================
Telemetry:
 ts = 2025-10-16T00:00:00Z
 ppm = 930
 ph = 6.03
 tempC = 27.1
 waterLevel = 72

Status (Online retained):
 online = true
 ts = 2025-10-16T01:23:45Z

Control (App → Kit):
 cmd = pumpAB
 args = { ms: 500 }
 ts = 2025-10-16T01:25:00Z
 by = app


============================================================
6) VERSI & RIWAYAT PERUBAHAN
============================================================
| Versi | Tanggal     | Deskripsi                                      |
|--------|--------------|------------------------------------------------|
| v1.0  | 2025-10-16   | Draft awal integrasi skripsi (App ↔ Kit)      |
| v1.1  | (nanti)      | Tambah format alert & threshold jika perlu    |


============================================================
7) CATATAN IMPLEMENTASI
============================================================
- Semua payload dikirim dalam format JSON UTF-8.
- Gunakan QoS 1 untuk memastikan keandalan.
- Field "ts" menggunakan waktu real (UTC).
- Semua nilai numerik disimpan sebagai float.
- Field tambahan boleh ada selama struktur dasar tidak berubah.
- Jika perangkat offline, aplikasi menampilkan status "Offline" (retained).


============================================================
DOKUMEN RESMI
============================================================
Dokumen ini menjadi acuan resmi bagi pengembangan, integrasi,
dan pengujian sistem komunikasi antara aplikasi dan perangkat
IoT Hydroponic Smart Kit.
============================================================
