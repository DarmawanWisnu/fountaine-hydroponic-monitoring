import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fountaine/domain/telemetry.dart';
import 'package:fountaine/domain/device_status.dart';
import 'package:fountaine/services/mqtt_service.dart';
import 'package:fountaine/services/db_service.dart';

// ===== Provider publik =====
final kitListProvider = StateNotifierProvider<KitListNotifier, List<Kit>>((
  ref,
) {
  return KitListNotifier();
});

// ===== Model Kit =====
class Kit {
  final String id;
  final String name;
  final bool online;
  final DateTime lastUpdated;
  final Telemetry? telemetry;

  Kit({
    required this.id,
    required this.name,
    this.online = false,
    DateTime? lastUpdated,
    this.telemetry,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'online': online,
    'lastUpdated': lastUpdated.toIso8601String(),
    'telemetry': telemetry?.toJson(),
  };

  static Kit fromJson(Map<String, dynamic> j) => Kit(
    id: j['id'],
    name: j['name'],
    online: j['online'] ?? false,
    lastUpdated: DateTime.tryParse(j['lastUpdated'] ?? '') ?? DateTime.now(),
    telemetry: j['telemetry'] != null
        ? Telemetry.fromJson(Map<String, dynamic>.from(j['telemetry']))
        : null,
  );

  Kit copyWith({
    String? id,
    String? name,
    bool? online,
    DateTime? lastUpdated,
    Telemetry? telemetry,
  }) => Kit(
    id: id ?? this.id,
    name: name ?? this.name,
    online: online ?? this.online,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    telemetry: telemetry ?? this.telemetry,
  );
}

// ===== Notifier =====
class KitListNotifier extends StateNotifier<List<Kit>> {
  KitListNotifier() : super([]) {
    _load();
    _scheduleDailyPrune();
  }

  static const _storageKey = 'kits';
  final MqttService _mqtt = MqttService();
  StreamSubscription<Telemetry>? _telemetrySub;
  StreamSubscription<DeviceStatus>? _statusSub;
  String? _currentKitId;

  Timer? _pruneTimer;

  // ---------------- LOAD / SAVE ----------------
  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_storageKey) ?? '[]';
      final arr = jsonDecode(raw) as List;
      state = arr
          .map((e) => Kit.fromJson(Map<String, dynamic>.from(e)))
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

  // ---------------- CRUD ----------------
  Future<void> addKit(Kit kit) async {
    if (state.any((k) => k.id == kit.id)) throw Exception('Kit ID sudah ada');
    state = [kit, ...state];
    await _save();
  }

  Future<void> removeKit(String id) async {
    state = state.where((k) => k.id != id).toList();
    await _save();
  }

  Future<void> updateKit(Kit kit) async {
    final i = state.indexWhere((k) => k.id == kit.id);
    if (i == -1) return;
    final newList = [...state];
    newList[i] = kit;
    state = newList;
    await _save();
  }

  // ---------------- LIVE (MQTT + SQLite) ----------------
  Future<void> listenFromMqtt(String kitId, {String? kitName}) async {
    // Upsert kit
    if (!state.any((k) => k.id == kitId)) {
      state = [Kit(id: kitId, name: kitName ?? kitId, online: false), ...state];
      await _save();
    }

    if (_currentKitId != null && _currentKitId != kitId) await stopListening();
    _currentKitId = kitId;

    await _mqtt.connect(kitId: kitId);

    _telemetrySub = _mqtt.telemetry$(kitId).listen((t) async {
      // update UI realtime
      state = [
        for (final k in state)
          k.id == kitId
              ? k.copyWith(
                  telemetry: t,
                  online: true,
                  lastUpdated: DateTime.now(),
                )
              : k,
      ];
      await _save();
      await DatabaseService.instance.insertTelemetry(kitId, t);
    });

    _statusSub = _mqtt.status$(kitId).listen((s) {
      state = [
        for (final k in state)
          k.id == kitId
              ? k.copyWith(
                  online: s.online,
                  lastUpdated: s.lastSeen ?? DateTime.now(),
                )
              : k,
      ];
      _save();
    });
  }

  Future<void> stopListening() async {
    await _telemetrySub?.cancel();
    await _statusSub?.cancel();
    _telemetrySub = null;
    _statusSub = null;
    await _mqtt.dispose();
  }

  // ---------------- PRUNING 7 HARI @ 05:00 ----------------
  void _scheduleDailyPrune() {
    _pruneTimer?.cancel();

    DateTime next5() {
      final now = DateTime.now();
      final today5 = DateTime(now.year, now.month, now.day, 5);
      return now.isBefore(today5)
          ? today5
          : today5.add(const Duration(days: 1));
    }

    void scheduleOnce() {
      final delay = next5().difference(DateTime.now());
      _pruneTimer = Timer(delay, () async {
        await DatabaseService.instance.pruneOlderThan(const Duration(days: 7));
        scheduleOnce(); // jadwalkan lagi besok
      });
    }

    scheduleOnce();
  }

  @override
  void dispose() {
    stopListening();
    _pruneTimer?.cancel();
    super.dispose();
  }
}
