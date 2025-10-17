import 'dart:async';
import 'dart:math';
import '../../domain/telemetry.dart';

class SimulatedSource {
  final _rng = Random();
  Timer? _t;
  final _ctrl = StreamController<Telemetry>.broadcast();
  Stream<Telemetry> get stream => _ctrl.stream;

  void start() {
    _t?.cancel();
    double ppm = 900, ph = 6.0, temp = 27, wl = 70;
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      ppm += _rng.nextDouble() * 10 - 5;
      ph += (_rng.nextDouble() - 0.5) * 0.05;
      temp += (_rng.nextDouble() - 0.5) * 0.2;
      wl += (_rng.nextDouble() - 0.5) * 0.5;

      _ctrl.add(
        Telemetry(
          ts: DateTime.now(),
          ppm: ppm,
          ph: ph,
          tempC: temp,
          waterLevel: wl.clamp(0, 100),
        ),
      );
    });
  }

  void stop() {
    _t?.cancel();
  }
}
