// lib/providers/mqtt_provider.dart
import 'package:flutter/foundation.dart';
import 'package:fountaine/services/mqtt_service.dart';

class MqttVM extends ChangeNotifier {
  final MqttService _svc = MqttService();
  MqttConnState state = MqttConnState.disconnected;

  Future<void> init({String? kitId}) async {
    _svc.connectionState$.listen((s) {
      state = s;
      notifyListeners();
    });
    await _svc.connect(kitId: kitId);
  }

  MqttService get service => _svc;

  Future<void> disposeConn() async {
    await _svc.dispose();
  }
}
