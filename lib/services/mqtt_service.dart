// lib/services/mqtt_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../core/constants.dart';
import '../domain/telemetry.dart';
import '../domain/device_status.dart';

enum MqttConnState { disconnected, connecting, connected, error }

class MqttService {
  final _connStateCtrl = StreamController<MqttConnState>.broadcast();
  Stream<MqttConnState> get connectionState$ => _connStateCtrl.stream;

  final _telemetryCtrl = StreamController<Telemetry>.broadcast();
  Stream<Telemetry> telemetry$(String kitId) => _telemetryCtrl.stream;

  final _statusCtrl = StreamController<DeviceStatus>.broadcast();
  Stream<DeviceStatus> status$(String kitId) => _statusCtrl.stream;

  MqttServerClient? _client;
  Timer? _reconnectTimer;
  String? _kitId;

  Future<void> connect({String? kitId}) async {
    _kitId = kitId ?? AppConst.defaultKitId;
    _connStateCtrl.add(MqttConnState.connecting);

    final clientId =
        "${MqttConst.clientPrefix}${DateTime.now().millisecondsSinceEpoch}";
    final c =
        MqttServerClient.withPort(MqttConst.host, clientId, MqttConst.port)
          ..secure = MqttConst.tls
          ..logging(on: false)
          ..keepAlivePeriod = 30
          ..onDisconnected = _onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillTopic(MqttConst.tStatus(_kitId!))
        .withWillMessage(
          jsonEncode({"online": false, "ts": DateTime.now().toIso8601String()}),
        )
        .withWillRetain()
        .withWillQos(MqttQos.atLeastOnce);

    c.connectionMessage = connMess;

    try {
      final status = await c.connect(MqttConst.username, MqttConst.password);
      if (status?.state != MqttConnectionState.connected) {
        _connStateCtrl.add(MqttConnState.error);
        c.disconnect();
        _scheduleReconnect();
        return;
      }
      _client = c;
      _connStateCtrl.add(MqttConnState.connected);

      // Publish online status (retained)
      _publish(MqttConst.tStatus(_kitId!), {
        "online": true,
        "ts": DateTime.now().toIso8601String(),
      }, retain: true);

      // Subscriptions
      c.subscribe(MqttConst.tTelemetry(_kitId!), MqttQos.atLeastOnce);
      c.subscribe(MqttConst.tStatus(_kitId!), MqttQos.atLeastOnce);

      c.updates?.listen((events) {
        for (final ev in events) {
          final rec = ev.payload as MqttPublishMessage;
          final topic = ev.topic;
          final payload = MqttPublishPayload.bytesToStringAsString(
            rec.payload.message,
          );

          try {
            final Map<String, dynamic> j = jsonDecode(payload);
            if (topic == MqttConst.tTelemetry(_kitId!)) {
              _telemetryCtrl.add(Telemetry.fromJson(j));
            } else if (topic == MqttConst.tStatus(_kitId!)) {
              _statusCtrl.add(DeviceStatus.fromJson(j));
            }
          } catch (_) {
            // ignore bad json
          }
        }
      });
    } catch (_) {
      _connStateCtrl.add(MqttConnState.error);
      _client?.disconnect();
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(seconds: 5),
      () => connect(kitId: _kitId),
    );
  }

  void _onDisconnected() {
    _connStateCtrl.add(MqttConnState.disconnected);
    _scheduleReconnect();
  }

  Future<void> publishControl(
    String kitId,
    String cmd,
    Map<String, dynamic> args,
  ) async {
    _publish(MqttConst.tControl(kitId), {
      "cmd": cmd,
      "args": args,
      "ts": DateTime.now().toIso8601String(),
    });
  }

  void _publish(String topic, Map<String, dynamic> obj, {bool retain = false}) {
    if (_client == null) return;
    final builder = MqttClientPayloadBuilder()..addUTF8String(jsonEncode(obj));
    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: retain,
    );
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _client?.disconnect();
    _connStateCtrl.add(MqttConnState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _telemetryCtrl.close();
    await _statusCtrl.close();
    await _connStateCtrl.close();
  }
}
