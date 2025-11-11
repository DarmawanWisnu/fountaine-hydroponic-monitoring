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

  Future<void> connect({required String kitId}) async {
    _kitId = kitId;
    _connStateCtrl.add(MqttConnState.connecting);

    final clientId =
        "${MqttConst.clientPrefix}${DateTime.now().millisecondsSinceEpoch}";
    final c =
        MqttServerClient.withPort(MqttConst.host, clientId, MqttConst.port)
          ..secure = MqttConst.tls
          ..logging(on: false)
          ..keepAlivePeriod = 30
          ..autoReconnect = true; // ✅ enable auto reconnect

    c.onDisconnected = _onDisconnected;
    c.onConnected = () => _connStateCtrl.add(MqttConnState.connected);

    final topicStatus = MqttConst.tStatus(kitId);
    c.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillTopic(topicStatus)
        .withWillMessage(
          jsonEncode({"online": false, "ts": DateTime.now().toIso8601String()}),
        )
        .withWillRetain()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      final status = await c.connect(
        (MqttConst.username.isEmpty || MqttConst.username == 'guest')
            ? null
            : MqttConst.username,
        (MqttConst.password.isEmpty || MqttConst.password == 'guest')
            ? null
            : MqttConst.password,
      );

      if (status?.state != MqttConnectionState.connected) {
        _connStateCtrl.add(MqttConnState.error);
        c.disconnect();
        _scheduleReconnect();
        return;
      }

      _client = c;
      _connStateCtrl.add(MqttConnState.connected);

      // publish status online
      _publish(topicStatus, {
        "online": true,
        "ts": DateTime.now().toIso8601String(),
      }, retain: true);

      final topicTelemetry = MqttConst.tTelemetry(kitId);

      // ✅ SUBSCRIBE KEDUA TOPIK (telemetry + status)
      c.subscribe(topicTelemetry, MqttQos.atLeastOnce);
      c.subscribe(topicStatus, MqttQos.atLeastOnce);

      c.updates?.listen((events) {
        for (final ev in events) {
          final msg = ev.payload as MqttPublishMessage;
          final topic = ev.topic;
          final payload = MqttPublishPayload.bytesToStringAsString(
            msg.payload.message,
          );

          if (topic == topicTelemetry) {
            try {
              final data = jsonDecode(payload) as Map<String, dynamic>;
              final telemetry = _parseTelemetry(data);
              _telemetryCtrl.add(telemetry);
            } catch (e, s) {
              // 🔴 jangan telan error parsing telemetry
              // ignore: avoid_print
              print('MQTT telemetry parse error: $e\n$s\nPayload: $payload');
            }
          } else if (topic == topicStatus) {
            try {
              _statusCtrl.add(
                DeviceStatus.fromJson(
                  jsonDecode(payload) as Map<String, dynamic>,
                ),
              );
            } catch (e, s) {
              // 🔴 jangan telan error parsing status
              // ignore: avoid_print
              print('MQTT status parse error: $e\n$s\nPayload: $payload');
            }
          }
        }
      });
    } catch (e, s) {
      _connStateCtrl.add(MqttConnState.error);
      _client?.disconnect();
      // 🔴 log error connect biar ketahuan
      // ignore: avoid_print
      print('MQTT connect error: $e\n$s');
      _scheduleReconnect();
    }
  }

  Telemetry _parseTelemetry(Map<String, dynamic> j) {
    double toDouble(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? def;
      return def;
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    // === Sama persis dengan publisher.py ===
    final map = <String, dynamic>{
      "id": toInt(j["id"]),
      "ppm": toDouble(j["ppm"] ?? j["TDS"]),
      "ph": toDouble(j["ph"] ?? j["pH"]),
      "tempC": toDouble(j["temperature"] ?? j["DHT_temp"]),
      "humidity": toDouble(j["humidity"] ?? j["DHT_humidity"]),
      "waterTemp": toDouble(j["waterTemp"] ?? j["water_temp"]),
      "waterLevel": toDouble(j["waterLevel"] ?? j["water_level"]),
      "pH_reducer": false,
      "add_water": false,
      "nutrients_adder": false,
      "humidifier": false,
      "ex_fan": false,
      "isDefault": false,
    };

    return Telemetry.fromJson(map);
  }

  void _publish(String topic, Map<String, dynamic> obj, {bool retain = false}) {
    final cli = _client;
    if (cli == null) return;
    final builder = MqttClientPayloadBuilder()..addUTF8String(jsonEncode(obj));
    cli.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: retain,
    );
  }

  /// Buat kirim kontrol (biar provider gak error)
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

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_kitId == null) return;
    _reconnectTimer = Timer(
      const Duration(seconds: 5),
      () => connect(kitId: _kitId!),
    );
  }

  void _onDisconnected() {
    _connStateCtrl.add(MqttConnState.disconnected);
    _scheduleReconnect();
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
