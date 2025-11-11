class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      read: read ?? this.read,
    );
  }
}
