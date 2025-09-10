import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'config.dart';

typedef TelemetryHandler = void Function(Map<String, dynamic> payload);

class MqttService {

  final MqttServerClient _client =
      MqttServerClient(AppConfig.mqttHost, 'mobile-client')
        ..useWebSocket = true 
        ..port = AppConfig.mqttPort
        ..keepAlivePeriod = 30
        ..logging(on: false);

  Future<void> connectAndSubscribe(TelemetryHandler onTelemetry) async {
    try {
      //Conectare
      await _client.connect();

      //Abonare la telemetrie
      const topic = 'greenhouse/zone1/telemetry';
      _client.subscribe(topic, MqttQos.atMostOnce);

      //Ascultare mesaje
      _client.updates?.listen(
        (List<MqttReceivedMessage<MqttMessage?>> events) {
          final MqttReceivedMessage<MqttMessage?> rec = events.first;
          final MqttPublishMessage msg = rec.payload as MqttPublishMessage;
          final payload =
              MqttPublishPayload.bytesToStringAsString(msg.payload.message);

          final data = jsonDecode(payload) as Map<String, dynamic>;
          onTelemetry(data);
        },
      );
    } catch (e) {
      _client.disconnect();
      rethrow;
    }
  }

  void dispose() {
    _client.disconnect();
  }
}
