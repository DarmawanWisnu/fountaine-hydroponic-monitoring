// Satu-satunya definisi HistoryRouteArgs di seluruh project.
class HistoryRouteArgs {
  final DateTime? targetTime; // waktu notifikasi terjadi
  final String? kitName; // nama kit terkait
  final String? reason; // pesan/penyebab notifikasi

  const HistoryRouteArgs({this.targetTime, this.kitName, this.reason});
}

// models/nav_args.dart
class NotificationRouteArgs {
  final String? initialFilter; // 'info' | 'warning' | 'urgent' | null (All)
  const NotificationRouteArgs({this.initialFilter});
}
