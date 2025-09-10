import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  final String base; // ex: "http://192.168.1.55"
  ApiService(this.base);

  Future<Telemetry> fetchTelemetry() async {
    final r = await http.get(Uri.parse('$base/telemetry')).timeout(const Duration(seconds: 5));
    if (r.statusCode != 200) {
      throw Exception('Telemetry HTTP ${r.statusCode}');
    }
    final j = json.decode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    return Telemetry.fromJson(j);
    }

  Future<void> startWatering(int seconds) async {
    final r = await http.post(Uri.parse('$base/water?seconds=$seconds')).timeout(const Duration(seconds: 5));
    if (r.statusCode != 200) {
      throw Exception('Water HTTP ${r.statusCode}');
    }
  }

  Future<void> runPredict() async {
    final r = await http.post(Uri.parse('$base/predict')).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception('Predict HTTP ${r.statusCode}');
    }
  }
}
