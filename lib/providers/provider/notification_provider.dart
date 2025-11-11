import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'kit_provider.dart';
import 'package:fountaine/core/constants.dart';

String _norm(String? s) => (s ?? '').trim().toLowerCase();

class NotificationItem {
  final String id;
  final String level;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? kitName;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.level,
    required this.title,
    required this.message,
    required this.timestamp,
    this.kitName,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    level: level,
    title: title,
    message: message,
    timestamp: timestamp,
    kitName: kitName,
    isRead: isRead ?? this.isRead,
  );
}

class NotificationListNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationListNotifier(this.ref, List<Kit> kits) : super([]) {
    _kitsSub = ref.listen<List<Kit>>(kitListProvider, (prev, next) {
      _evaluateAll(next);
    });

    _evaluateAll(kits);

    Future.microtask(() {
      if (!_hasAnyViolationNow(kits)) _emitSafeInfo();
    });

    _safeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      final last1m = now.subtract(const Duration(minutes: 1));
      final hasRecentWarning = state.any(
        (n) => _norm(n.level) != 'info' && n.timestamp.isAfter(last1m),
      );
      if (!hasRecentWarning &&
          !_hasAnyViolationNow(ref.read(kitListProvider))) {
        _emitSafeInfo();
      }
    });
  }

  final Ref ref;
  Timer? _safeTimer;
  ProviderSubscription<List<Kit>>? _kitsSub;
  final Map<String, DateTime> _lastAlertAt = {};
  static const Duration _cooldown = Duration(seconds: 20);

  // Pakai dari constants.dart
  static const double _phMin = ThresholdConst.phMin;
  static const double _phMax = ThresholdConst.phMax;
  static const double _ppmMin = ThresholdConst.ppmMin;
  static const double _ppmMax = ThresholdConst.ppmMax;
  static const double _humMin = ThresholdConst.wlMinPercent;
  static const double _humMax = ThresholdConst.wlMaxPercent;
  static const double _tMin = ThresholdConst.tempMin;
  static const double _tMax = ThresholdConst.tempMax;

  void _evaluateAll(List<Kit> kits) {
    for (final k in kits) {
      _checkThresholdAndNotify(k);
    }
  }

  double? _read(Kit k, String key) {
    final t = k.telemetry;
    if (t == null) return null;
    switch (key) {
      case 'ph':
        return t.ph;
      case 'ppm':
        return t.ppm;
      case 'humidity':
        return t.humidity;
      case 'temperature':
        return t.tempC;
      default:
        return null;
    }
  }

  bool _hasAnyViolationNow(List<Kit> kits) {
    for (final k in kits) {
      final ph = _read(k, 'ph');
      if (ph != null && (ph < _phMin || ph > _phMax)) return true;
      final ppm = _read(k, 'ppm');
      if (ppm != null && (ppm < _ppmMin || ppm > _ppmMax)) return true;
      final hum = _read(k, 'humidity');
      if (hum != null && (hum < _humMin || hum > _humMax)) return true;
      final temp = _read(k, 'temperature');
      if (temp != null && (temp < _tMin || temp > _tMax)) return true;
    }
    return false;
  }

  void _checkThresholdAndNotify(Kit k) {
    final ph = _read(k, 'ph');
    final ppm = _read(k, 'ppm');
    final hum = _read(k, 'humidity');
    final temp = _read(k, 'temperature');

    if (ph != null && (ph < _phMin || ph > _phMax)) {
      final dir = ph < _phMin ? 'below' : 'higher';
      _emitThreshold(
        kit: k,
        param: 'pH',
        title: 'Warning',
        message:
            'pH ${ph < _phMin ? "Dropped" : "Spiked"} to ${ph.toStringAsFixed(2)} - ${dir == "below" ? "Below" : "Higher"} Optimal Range',
        dir: dir,
      );
    }

    if (ppm != null && (ppm < _ppmMin || ppm > _ppmMax)) {
      final dir = ppm < _ppmMin ? 'below' : 'higher';
      _emitThreshold(
        kit: k,
        param: 'ppm',
        title: 'Warning',
        message:
            'PPM ${ppm < _ppmMin ? "Dropped" : "Spiked"} to ${ppm.toStringAsFixed(0)} - ${dir == "below" ? "Below" : "Higher"} Optimal Range',
        dir: dir,
      );
    }

    if (hum != null && (hum < _humMin || hum > _humMax)) {
      final dir = hum < _humMin ? 'below' : 'higher';
      _emitThreshold(
        kit: k,
        param: 'humidity',
        title: 'Warning',
        message:
            'Humidity ${hum < _humMin ? "Dropped" : "Spiked"} to ${hum.toStringAsFixed(1)}%',
        dir: dir,
      );
    }

    if (temp != null && (temp < _tMin || temp > _tMax)) {
      final dir = temp < _tMin ? 'below' : 'higher';
      _emitThreshold(
        kit: k,
        param: 'temperature',
        title: 'Warning',
        message:
            'Temperature ${temp < _tMin ? "Dropped" : "Spiked"} to ${temp.toStringAsFixed(1)} °C',
        dir: dir,
      );
    }
  }

  void _emitThreshold({
    required Kit kit,
    required String param,
    required String title,
    required String message,
    required String dir,
  }) {
    final now = DateTime.now();
    final key = '${kit.id}:$param:$dir';
    final last = _lastAlertAt[key];
    if (last != null && now.difference(last) < _cooldown) return;
    _lastAlertAt[key] = now;

    final n = NotificationItem(
      id: now.millisecondsSinceEpoch.toString(),
      level: 'warning',
      title: title,
      message: message,
      timestamp: now,
      kitName: kit.name,
    );
    add(n);
  }

  void _emitSafeInfo() {
    final now = DateTime.now();
    DateTime? lastInfoTs;
    for (final n in state) {
      if (_norm(n.level) == 'info') {
        if (lastInfoTs == null || n.timestamp.isAfter(lastInfoTs)) {
          lastInfoTs = n.timestamp;
        }
      }
    }
    if (lastInfoTs != null && now.difference(lastInfoTs).inSeconds < 30) return;

    final n = NotificationItem(
      id: 'safe_${now.millisecondsSinceEpoch}',
      level: 'info',
      title: 'Info',
      message: 'All Parameters Are Within Safe Limits',
      timestamp: now,
      kitName: null,
    );
    add(n);
  }

  void markAllRead() =>
      state = [for (final n in state) n.copyWith(isRead: true)];

  void markRead(String id) => state = [
    for (final n in state)
      if (n.id == id) n.copyWith(isRead: true) else n,
  ];

  void add(NotificationItem n) => state = [n, ...state];

  void delete(String id) => state = [
    for (final n in state)
      if (n.id != id) n,
  ];

  void clearAll() => state = [];

  @override
  void dispose() {
    _safeTimer?.cancel();
    _kitsSub?.close();
    super.dispose();
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, List<NotificationItem>>((
      ref,
    ) {
      final kits = ref.read(kitListProvider);
      return NotificationListNotifier(ref, kits);
    });

final filteredNotificationProvider =
    Provider.family<List<NotificationItem>, String?>((ref, level) {
      final list = ref.watch(notificationListProvider);
      final key = _norm(level);
      final showAll = (level == null) || key.isEmpty || key == 'all';
      final items = showAll
          ? [...list]
          : [
              for (final n in list)
                if (_norm(n.level) == key) n,
            ];
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationListProvider);
  return list.where((n) => !n.isRead).length;
});
