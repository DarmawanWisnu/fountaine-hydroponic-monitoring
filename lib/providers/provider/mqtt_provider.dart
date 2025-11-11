import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fountaine/core/constants.dart';
import 'package:fountaine/services/mqtt_service.dart';

class MqttVM extends ChangeNotifier {
  final MqttService _svc = MqttService();

  MqttConnState _state = MqttConnState.disconnected;
  MqttConnState get state => _state;

  StreamSubscription<MqttConnState>? _connSub;
  bool _initialized = false;
  String? _currentKitId;

  /// Inisialisasi & connect ke broker (pakai 10.0.2.2).
  Future<void> init({String? kitId}) async {
    if (_initialized) return;
    _initialized = true;

    _connSub = _svc.connectionState$.listen((s) {
      _state = s;
      notifyListeners();
    });

    _currentKitId = kitId ?? AppConst.defaultKitId;

    debugPrint("[MQTT] Connecting to ${MqttConst.host}:${MqttConst.port}");
    await _svc.connect(kitId: _currentKitId!);
  }

  MqttService get service => _svc;

  Future<void> switchKit(String kitId) async {
    if (kitId == _currentKitId) return;
    _currentKitId = kitId;
    await _svc.disconnect();
    await _svc.connect(kitId: kitId);
  }

  Future<void> sendControl(String cmd, Map<String, dynamic> args) async {
    final id = _currentKitId ?? AppConst.defaultKitId;
    await _svc.publishControl(id, cmd, args);
  }

  Future<void> disposeConn() async {
    await _connSub?.cancel();
    _connSub = null;
    await _svc.dispose();
    _initialized = false;
    _state = MqttConnState.disconnected;
  }

  @override
  void dispose() {
    unawaited(disposeConn());
    super.dispose();
  }
}
