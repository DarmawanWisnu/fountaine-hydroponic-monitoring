class Telemetry {
  final DateTime ts;
  final double ppm;
  final double ph;
  final double tempC;
  final double waterLevel;

  Telemetry({
    required this.ts,
    required this.ppm,
    required this.ph,
    required this.tempC,
    required this.waterLevel,
  });

  factory Telemetry.fromJson(Map<String, dynamic> j) => Telemetry(
    ts: DateTime.tryParse(j["ts"] ?? "") ?? DateTime.now(),
    ppm: (j["ppm"] ?? 0).toDouble(),
    ph: (j["ph"] ?? 0).toDouble(),
    tempC: (j["tempC"] ?? 0).toDouble(),
    waterLevel: (j["waterLevel"] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "ts": ts.toIso8601String(),
    "ppm": ppm,
    "ph": ph,
    "tempC": tempC,
    "waterLevel": waterLevel,
  };
}
