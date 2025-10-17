import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fountaine/core/constants.dart';
import 'package:fountaine/domain/telemetry.dart';
import 'package:fountaine/domain/device_status.dart';
import 'package:fountaine/services/mqtt_service.dart';

// ===== Provider publik =====
final kitListProvider = StateNotifierProvider<KitListNotifier, List<Kit>>((
  ref,
) {
  return KitListNotifier();
});

// ===== Model Kit sederhana =====
class Kit {
  final String id;
  final String name;
  final bool online;
  final DateTime lastUpdated;
  final double? ph;
  final double? ppm;
  final double? humidity;
  final double? temperature;
  final Map<String, dynamic>? sensors;

  Kit({
    required this.id,
    required this.name,
    this.online = true,
    DateTime? lastUpdated,
    this.ph,
    this.ppm,
    this.humidity,
    this.temperature,
    this.sensors,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'online': online,
    'lastUpdated': lastUpdated.toIso8601String(),
    'ph': ph,
    'ppm': ppm,
    'humidity': humidity,
    'temperature': temperature,
    'sensors': sensors,
  };

  static Kit fromJson(Map<String, dynamic> j) => Kit(
    id: j['id'] as String,
    name: j['name'] as String,
    online: j['online'] as bool? ?? true,
    lastUpdated: j['lastUpdated'] != null
        ? DateTime.tryParse(j['lastUpdated'] as String) ?? DateTime.now()
        : DateTime.now(),
    ph: j['ph'] is num
        ? (j['ph'] as num).toDouble()
        : (j['ph'] is String ? double.tryParse(j['ph']) : null),
    ppm: j['ppm'] is num
        ? (j['ppm'] as num).toDouble()
        : (j['ppm'] is String ? double.tryParse(j['ppm']) : null),
    humidity: j['humidity'] is num
        ? (j['humidity'] as num).toDouble()
        : (j['humidity'] is String ? double.tryParse(j['humidity']) : null),
    temperature: j['temperature'] is num
        ? (j['temperature'] as num).toDouble()
        : (j['temperature'] is String
              ? double.tryParse(j['temperature'])
              : null),
    sensors: j['sensors'] != null
        ? Map<String, dynamic>.from(j['sensors'] as Map)
        : null,
  );

  Kit copyWith({
    String? id,
    String? name,
    bool? online,
    DateTime? lastUpdated,
    double? ph,
    double? ppm,
    double? humidity,
    double? temperature,
    Map<String, dynamic>? sensors,
  }) {
    return Kit(
      id: id ?? this.id,
      name: name ?? this.name,
      online: online ?? this.online,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      ph: ph ?? this.ph,
      ppm: ppm ?? this.ppm,
      humidity: humidity ?? this.humidity,
      temperature: temperature ?? this.temperature,
      sensors: sensors ?? this.sensors,
    );
  }
}

class KitListNotifier extends StateNotifier<List<Kit>> {
  KitListNotifier() : super([]) {
    _load(); // muat list Kit tersimpan
  }

  // ====== Storage key untuk SharedPreferences ======
  static const _storageKey = 'kits';

  // ====== MQTT Service & Subscriptions (mode LIVE) ======
  final MqttService _mqtt = MqttService();
  StreamSubscription<Telemetry>? _telemetrySub;
  StreamSubscription<DeviceStatus>? _statusSub;
  String? _currentKitId;

  // ====== SIM LOOP GLOBAL ======
  Timer? _simTimer;

  // -----------------------------------------------------------------------------
  // Persistensi ringan: load/save list Kit
  // -----------------------------------------------------------------------------
  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_storageKey) ?? '[]';
      final arr = jsonDecode(raw) as List<dynamic>;
      state = arr
          .map((e) => Kit.fromJson(e as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _storageKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  // -----------------------------------------------------------------------------
  // CRUD Kit
  // -----------------------------------------------------------------------------
  Future<void> addKit(Kit kit) async {
    if (state.any((k) => k.id == kit.id)) {
      throw Exception('ID Kit sudah terdaftar');
    }
    final newKit = kit.copyWith(lastUpdated: DateTime.now());
    state = [newKit, ...state];
    await _save();
  }

  Future<void> removeKit(String id) async {
    state = state.where((k) => k.id != id).toList();
    await _save();
  }

  Future<void> updateKit(Kit updated) async {
    final idx = state.indexWhere((k) => k.id == updated.id);
    if (idx == -1) throw Exception('Kit tidak ditemukan');
    final list = [...state];
    list[idx] = updated.copyWith(lastUpdated: DateTime.now());
    state = list;
    await _save();
  }

  Future<void> clearAll() async {
    state = [];
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_storageKey);
  }

  // -----------------------------------------------------------------------------
  // MODE 1: SIMULASI (dummy lokal)
  // -----------------------------------------------------------------------------
  /// Jika kosong, tambahkan satu dummy kit (dipanggil dari MonitorScreen init)
  Future<void> seedDummy() async {
    if (state.isNotEmpty) return;
    final dummy = Kit(
      id: AppConst.defaultKitId,
      name: 'Hydroponic System (Dummy)',
      online: true,
      lastUpdated: DateTime.now(),
      // initial sensor snapshot
      ph: 6.7,
      ppm: 300,
      humidity: 72.0, // sementara mapping "waterLevel" -> "humidity"
      temperature: 27.0,
      sensors: {'ph': 6.7, 'ppm': 300, 'humidity': 72.0, 'temperature': 27.0},
    );
    state = [dummy];
    await _save();
  }

  /// Simulasikan pergerakan sensor untuk semua kit (panggil tiap 5 dtk)
  Future<void> simulateSensorUpdate() async {
    final rnd = Random();
    final now = DateTime.now();

    final newList = state.map((k) {
      // generate perubahan kecil di sekitar nilai saat ini
      double nextPh = k.ph ?? (5.8 + rnd.nextDouble() * 0.8); // 5.8..6.6
      nextPh += (rnd.nextDouble() - 0.5) * 0.10; // jitter kecil
      nextPh = double.parse(nextPh.toStringAsFixed(2));

      double nextPpm = k.ppm ?? (850 + rnd.nextDouble() * 200); // 850..1050
      nextPpm += (rnd.nextDouble() - 0.5) * 25; // ±12.5
      nextPpm = nextPpm.clamp(0, 3000);

      double nextHumidity =
          k.humidity ?? (70 + rnd.nextDouble() * 10); // 70..80
      nextHumidity += (rnd.nextDouble() - 0.5) * 2.5;
      nextHumidity = double.parse(
        nextHumidity.clamp(0, 100).toStringAsFixed(1),
      );

      double nextTemp = k.temperature ?? (26 + rnd.nextDouble() * 2); // 26..28
      nextTemp += (rnd.nextDouble() - 0.5) * 0.4;
      nextTemp = double.parse(nextTemp.toStringAsFixed(1));

      final sensors = {
        'ph': nextPh,
        'ppm': nextPpm.round(),
        'humidity': nextHumidity,
        'temperature': nextTemp,
      };

      return k.copyWith(
        lastUpdated: now,
        ph: nextPh,
        ppm: nextPpm,
        humidity: nextHumidity,
        temperature: nextTemp,
        sensors: sensors,
      );
    }).toList();

    state = newList;
    await _save();
  }

  /// Jalankan loop simulasi global
  Future<void> ensureSimRunning({
    Duration period = const Duration(seconds: 5),
  }) async {
    if (state.isEmpty) {
      await seedDummy();
    }
    await simulateSensorUpdate();
    if (_simTimer != null && _simTimer!.isActive) return;
    _simTimer = Timer.periodic(period, (_) async {
      try {
        await simulateSensorUpdate();
      } catch (_) {}
    });
  }

  /// Hentikan loop simulasi global
  void stopSim() {
    _simTimer?.cancel();
    _simTimer = null;
  }

  // -----------------------------------------------------------------------------
  // MODE 2: LIVE (MQTT)
  // -----------------------------------------------------------------------------
  /// Pastikan Kit id/name ada di state;
  void _ensureKitInState(String kitId, {String? name}) {
    if (state.any((k) => k.id == kitId)) return;
    final newKit = Kit(
      id: kitId,
      name: name ?? 'Hydroponic Kit ($kitId)',
      online: false,
      lastUpdated: DateTime.now(),
      sensors: const {},
    );
    state = [newKit, ...state];
  }

  /// Mulai listen dari MQTT untuk 1 kitId
  Future<void> listenFromMqtt(String kitId, {String? kitName}) async {
    // kalau sebelumnya sudah listen kit lain, hentikan dulu
    if (_currentKitId != null && _currentKitId != kitId) {
      await stopListening();
    }
    _currentKitId = kitId;

    _ensureKitInState(kitId, name: kitName);

    // connect ke broker, set LWT, subscribe, dll.
    await _mqtt.connect(kitId: kitId);

    // telemetry stream -> update nilai sensor
    _telemetrySub = _mqtt.telemetry$(kitId).listen((t) {
      state = [
        for (final k in state)
          k.id == kitId
              ? k.copyWith(
                  ph: t.ph,
                  ppm: t.ppm,
                  temperature: t.tempC,
                  humidity: t.waterLevel,
                  sensors: {
                    'ph': t.ph,
                    'ppm': t.ppm,
                    'temperature': t.tempC,
                    'humidity': t.waterLevel,
                  },
                  lastUpdated: t.ts,
                  online: true,
                )
              : k,
      ];
      _save();
    });

    // status stream -> update online/lastSeen
    _statusSub = _mqtt.status$(kitId).listen((s) {
      state = [
        for (final k in state)
          k.id == kitId
              ? k.copyWith(
                  online: s.online,
                  lastUpdated: s.lastSeen ?? k.lastUpdated,
                )
              : k,
      ];
      _save();
    });
  }

  /// Hentikan semua langganan MQTT
  Future<void> stopListening() async {
    await _telemetrySub?.cancel();
    await _statusSub?.cancel();
    _telemetrySub = null;
    _statusSub = null;
    _currentKitId = null;
    await _mqtt.dispose();
  }

  @override
  void dispose() {
    // pastikan MQTT & subscriptions ditutup saat provider dispose
    stopListening();
    stopSim();
    super.dispose();
  }
}
