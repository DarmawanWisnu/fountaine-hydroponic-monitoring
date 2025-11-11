import 'dart:async';
import 'dart:math';
import '../../domain/telemetry.dart';

/// Sumber data simulasi untuk UI ketika tidak ada broker/publisher.
/// Menghasilkan Telemetry yang konsisten dengan model terbaru (tanpa `ts`).
class SimulatedSource {
  final _rng = Random();
  Timer? _timer;
  final _ctrl = StreamController<Telemetry>.broadcast();
  Stream<Telemetry> get stream => _ctrl.stream;

  int _counter = 0;

  /// Mulai simulasi.
  /// [interval] default 1 detik. Nilai dibuat smooth + realistis.
  void start({Duration interval = const Duration(seconds: 1)}) {
    stop();

    // Seed nilai awal mirip dataset with_interpolation
    double ppm = 650; // TDS
    double ph = 6.0; // pH
    double tempC = 27.5; // suhu udara
    double humidity = 65.0; // kelembapan udara
    double waterTemp = 22.0; // suhu air
    double waterLevel = 2.0; // level air (skala dataset ~2.0)

    double clamp(double v, double lo, double hi) =>
        v < lo ? lo : (v > hi ? hi : v);

    _timer = Timer.periodic(interval, (_) {
      // Drift halus
      ppm = clamp(ppm + (_rng.nextDouble() - 0.5) * 6, 600, 700);
      ph = clamp(ph + (_rng.nextDouble() - 0.5) * 0.06, 5.6, 6.4);
      tempC = clamp(tempC + (_rng.nextDouble() - 0.5) * 0.4, 26.0, 29.5);
      humidity = clamp(humidity + (_rng.nextDouble() - 0.5) * 2.5, 58.0, 75.0);
      waterTemp = clamp(
        waterTemp + (_rng.nextDouble() - 0.5) * 0.5,
        20.0,
        24.5,
      );
      waterLevel = clamp(
        waterLevel + (_rng.nextDouble() - 0.5) * 0.05,
        1.6,
        2.4,
      );

      // Aturan sederhana untuk aktuator (biar hidup dikit)
      final pHReducer = ph > 6.30;
      final addWater = waterLevel < 1.80 || humidity < 60.0;
      final nutrientsAdder = ppm < 630 && ph >= 5.8;
      final humidifier = humidity < 60.0;
      final exFan = tempC > 28.5;

      _counter++;

      _ctrl.add(
        Telemetry(
          id: _counter,
          ppm: ppm,
          ph: ph,
          tempC: tempC,
          humidity: humidity,
          waterTemp: waterTemp,
          waterLevel: waterLevel,
          pHReducer: pHReducer,
          addWater: addWater,
          nutrientsAdder: nutrientsAdder,
          humidifier: humidifier,
          exFan: exFan,
          isDefault: false,
        ),
      );
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    stop();
    await _ctrl.close();
  }
}
