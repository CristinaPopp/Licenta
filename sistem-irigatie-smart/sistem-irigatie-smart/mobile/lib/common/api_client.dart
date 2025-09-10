import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiClient {
  final _base = AppConfig.apiBase;

  Future<Map<String, dynamic>> health() async {
    final r = await http.get(Uri.parse('$_base/health'));
    if (r.statusCode != 200) throw Exception('Backend down');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
