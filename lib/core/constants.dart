import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class AppConst {
  static int get rollupMinutes =>
      int.tryParse(dotenv.env['ROLLUP_MINUTES'] ?? '30') ?? 30;
  static String get defaultKitId => dotenv.env['DEFAULT_KIT_ID'] ?? 'devkit-01';
  static bool get simulatedMode =>
      (dotenv.env['SIMULATED_MODE'] ?? 'false').toLowerCase() == 'true';
  static String formatDateTime(DateTime? dt) {
    if (dt == null) return "-";
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(dt.toLocal());
  }
}

/// ===========================================================================
/// 🔗 MQTT CONFIGURATION (HiveMQ Cloud)
/// ===========================================================================
class MqttConst {
  static String get host => dotenv.env['MQTT_HOST'] ?? 'localhost';
  static int get port =>
      int.tryParse(dotenv.env['MQTT_PORT'] ?? '1883') ?? 1883;
  static String get username => dotenv.env['MQTT_USERNAME'] ?? 'guest';
  static String get password => dotenv.env['MQTT_PASSWORD'] ?? 'guest';
  static String get clientPrefix =>
      dotenv.env['MQTT_CLIENT_PREFIX'] ?? 'fountaine-app-';
  static const tls = true;

  static String tTelemetry(String kitId) => "kit/$kitId/telemetry";
  static String tStatus(String kitId) => "kit/$kitId/status";
  static String tControl(String kitId) => "kit/$kitId/control";
}

/// ===========================================================================
/// 🌱 DEFAULT THRESHOLDS
/// ===========================================================================
class ThresholdConst {
  static const ppmMin = 800.0;
  static const ppmMax = 1100.0;

  static const phMin = 5.8;
  static const phMax = 6.2;

  static const tempMin = 20.0;
  static const tempMax = 26.0;

  static const wlMinPercent = 30.0;
  static const wlMaxPercent = 90.0;

  static const hysteresisPercent = 5.0;
  static const confirmSamples = 2;
  static const alertCooldownMin = 5;
}

/// ===========================================================================
/// ⚙️ LOCAL HIVE BOX & FIRESTORE PATHS
/// ===========================================================================
class HiveBoxConst {
  static const telemetry = "telemetry_box";
  static const thresholds = "threshold_box";
  static const alerts = "alerts_box";
  static const kits = "kits_box";
}

class FirestorePath {
  static String user(String uid) => "users/$uid";
  static String kit(String uid, String kitId) => "users/$uid/kits/$kitId";
  static String telemetryRollup(String uid, String kitId) =>
      "users/$uid/kits/$kitId/telemetry_${AppConst.rollupMinutes}m";
  static String alerts(String uid, String kitId) =>
      "users/$uid/kits/$kitId/alerts";
  static String commands(String uid, String kitId) =>
      "users/$uid/kits/$kitId/commands";
}
