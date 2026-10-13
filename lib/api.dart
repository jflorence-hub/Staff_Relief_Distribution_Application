import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static const baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://192.168.1.11:8000/api');
  static Future<String?> get token async =>
      (await SharedPreferences.getInstance()).getString('staff_token');
  static Future<void> saveToken(String value) async =>
      (await SharedPreferences.getInstance()).setString('staff_token', value);
  static Future<void> clearToken() async =>
      (await SharedPreferences.getInstance()).remove('staff_token');

  static Future<Map<String, dynamic>> req(String method, String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    };
    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    final uri = Uri.parse('$baseUrl$path');
    final response = method == 'POST'
        ? await http.post(uri, headers: headers, body: jsonEncode(body ?? {}))
        : await http.get(uri, headers: headers);
    Map<String, dynamic> data = {};
    if (response.body.trim().isNotEmpty) {
      try {
        final value = jsonDecode(response.body);
        if (value is Map<String, dynamic>) data = value;
      } catch (_) {
        throw Exception(
            'The server returned a non-JSON response. Check API_BASE_URL and Laravel logs.');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errors = data['errors'];
      var message = data['message']?.toString() ??
          'Request failed (${response.statusCode}).';
      if (errors is Map &&
          errors.isNotEmpty &&
          errors.values.first is List &&
          (errors.values.first as List).isNotEmpty)
        message = (errors.values.first as List).first.toString();
      throw Exception(message);
    }
    return data;
  }
}
