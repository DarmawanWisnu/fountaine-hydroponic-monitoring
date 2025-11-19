class Telemetry {
  // Identitas/penanda rekam (opsional, dari CSV)
  final int? id;

  // Nilai sensor utama
  final double ppm; // dari TDS
  final double ph; // dari pH
  final double tempC; // dari DHT_temp (udara)
  final double humidity; // dari DHT_humidity
  final double waterTemp; // dari water_temp
  final double waterLevel; // dari water_level

  // Aktuator (jika ada di payload)
  final bool pHReducer;
  final bool addWater;
  final bool nutrientsAdder;
  final bool humidifier;
  final bool exFan;

  // Flag dataset
  final bool isDefault;

  const Telemetry({
    this.id,
    required this.ppm,
    required this.ph,
    required this.tempC,
    required this.humidity,
    required this.waterTemp,
    required this.waterLevel,
    this.pHReducer = false,
    this.addWater = false,
    this.nutrientsAdder = false,
    this.humidifier = false,
    this.exFan = false,
    this.isDefault = false,
  });

  // --- Helpers ---
  static double _toDouble(dynamic v, [double def = 0]) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == 'on' || s == 'true' || s == '1';
  }

  factory Telemetry.fromJson(Map<String, dynamic> j) => Telemetry(
    id: _toInt(j['id']),
    ppm: _toDouble(j['ppm'] ?? j['TDS'] ?? j['tds']),
    ph: _toDouble(j['pH'] ?? j['ph']),
    tempC: _toDouble(j['DHT_temp'] ?? j['tempC']),
    humidity: _toDouble(j['DHT_humidity'] ?? j['humidity']),
    waterTemp: _toDouble(j['water_temp'] ?? j['waterTemp']),
    waterLevel: _toDouble(j['water_level'] ?? j['waterLevel']),
    pHReducer: _toBool(j['pH_reducer']),
    addWater: _toBool(j['add_water']),
    nutrientsAdder: _toBool(j['nutrients_adder']),
    humidifier: _toBool(j['humidifier']),
    exFan: _toBool(j['ex_fan']),
    isDefault: _toBool(j['isDefault']),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) "id": id,
    "ppm": ppm,
    "ph": ph,
    "tempC": tempC,
    "humidity": humidity,
    "waterTemp": waterTemp,
    "waterLevel": waterLevel,
    "pH_reducer": pHReducer,
    "add_water": addWater,
    "nutrients_adder": nutrientsAdder,
    "humidifier": humidifier,
    "ex_fan": exFan,
    "isDefault": isDefault,
  };
}
