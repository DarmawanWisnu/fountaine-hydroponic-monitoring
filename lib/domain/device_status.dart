// lib/domain/device_status.dart
class DeviceStatus {
  final bool online;
  final DateTime? lastSeen;

  DeviceStatus({required this.online, this.lastSeen});

  factory DeviceStatus.fromJson(Map<String, dynamic> json) => DeviceStatus(
    online: json["online"] == true,
    lastSeen: DateTime.tryParse(json["ts"] ?? ""),
  );

  Map<String, dynamic> toJson() => {
    "online": online,
    "ts": lastSeen?.toIso8601String(),
  };
}
