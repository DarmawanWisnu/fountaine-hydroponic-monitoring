// lib/providers/kit_provider.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final kitListProvider = StateNotifierProvider<KitListNotifier, List<Kit>>((
  ref,
) {
  return KitListNotifier();
});

class Kit {
  final String id;
  final String name;
  final bool online;
  final DateTime lastUpdated;

  // optional explicit fields (useful for direct access)
  final double? ph;
  final double? ppm;
  final double? humidity;
  final double? temperature;

  // flexible map for sensors (string -> num or string)
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
    _load();
  }

  static const _storageKey = 'kits';

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

  /// Jika kosong, tambahkan satu dummy kit (dipanggil dari MonitorScreen init)
  Future<void> seedDummy() async {
    if (state.isNotEmpty) return;
    final dummy = Kit(
      id: 'SUF-UINJKT-HM-F2000',
      name: 'Hydroponic System',
      online: true,
      lastUpdated: DateTime.now(),
      // initial sensor snapshot
      ph: 6.7,
      ppm: 300,
      humidity: 75.0,
      temperature: 28.0,
      sensors: {'ph': 6.7, 'ppm': 300, 'humidity': 75.0, 'temperature': 28.0},
    );
    state = [dummy];
    await _save();
  }

  /// Simulate new sensor values for all kits (useful for testing)
  Future<void> simulateSensorUpdate() async {
    final rnd = Random();
    final now = DateTime.now();

    final newList = state.map((k) {
      // generate small random changes around current value (if present)
      double nextPh = k.ph ?? (5 + rnd.nextDouble() * 3); // 5..8
      nextPh += (rnd.nextDouble() - 0.5) * 0.4; // small jitter
      nextPh = double.parse(nextPh.toStringAsFixed(2));

      double nextPpm = k.ppm ?? (200 + rnd.nextDouble() * 200);
      nextPpm += (rnd.nextDouble() - 0.5) * 30;
      nextPpm = nextPpm.clamp(0, 3000);

      double nextHumidity = k.humidity ?? (50 + rnd.nextDouble() * 30);
      nextHumidity += (rnd.nextDouble() - 0.5) * 6;
      nextHumidity = nextHumidity.clamp(0, 100);

      double nextTemp = k.temperature ?? (22 + rnd.nextDouble() * 6);
      nextTemp += (rnd.nextDouble() - 0.5) * 2;
      nextTemp = double.parse(nextTemp.toStringAsFixed(1));

      final sensors = {
        'ph': nextPh,
        'ppm': nextPpm.round(),
        'humidity': double.parse(nextHumidity.toStringAsFixed(1)),
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
}
