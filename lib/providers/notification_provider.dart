import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kit_provider.dart';

// --- Model kecil, ga perlu file terpisah
class NotificationItem {
  final String id;
  final String level; // info | warning | urgent
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

// --- StateNotifier
class NotificationListNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationListNotifier(this.ref, List<Kit> kits) : super(_seedDummy(kits));

  final Ref ref;

  static List<NotificationItem> _seedDummy(List<Kit> kits) {
    String kitA = (kits.isNotEmpty ? kits.first.name : 'Hydro Kit A');
    String kitB = (kits.length > 1 ? kits[1].name : 'Hydro Kit B');
    String kitC = (kits.length > 2 ? kits[2].name : 'Hydro Kit C');

    return [
      NotificationItem(
        id: 'n1',
        level: 'urgent',
        title: 'Urgent',
        message: 'TDS Reached 850 Ppm - Potential Water Quality Issue.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        kitName: kitA,
      ),
      NotificationItem(
        id: 'n2',
        level: 'info',
        title: 'Info',
        message: 'All Parameters Are Within Safe Limits.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        kitName: kitB,
      ),
      NotificationItem(
        id: 'n3',
        level: 'warning',
        title: 'Warning',
        message: 'PH Dropped To 5.8 - Below Optimal Range.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        kitName: kitA,
      ),
      NotificationItem(
        id: 'n4',
        level: 'warning',
        title: 'Warning',
        message: 'Ppm Dropped To 100 - Below Optimal Range.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        kitName: kitC,
      ),
    ];
  }

  void markAllRead() =>
      state = [for (final n in state) n.copyWith(isRead: true)];

  void markRead(String id) => state = [
    for (final n in state)
      if (n.id == id) n.copyWith(isRead: true) else n,
  ];

  void add(NotificationItem n) => state = [n, ...state];
}

// --- Provider utama (otomatis tarik nama kit dari kitListProvider)
final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, List<NotificationItem>>((
      ref,
    ) {
      final kits = ref.watch(kitListProvider);
      return NotificationListNotifier(ref, kits);
    });

// helper selector buat filter di UI (tanpa fungsi tambahan di Notifier)
final filteredNotificationProvider =
    Provider.family<List<NotificationItem>, String?>((ref, level) {
      final list = ref.watch(notificationListProvider);
      if (level == null)
        return [...list]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return ([
        for (final n in list)
          if (n.level == level) n,
      ]..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
    });
