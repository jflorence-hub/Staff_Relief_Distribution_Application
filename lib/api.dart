import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static const baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://ambitious-flaring-jelly.ngrok-free.dev/api');

  static Future<String?> get token async =>
      (await SharedPreferences.getInstance()).getString('staff_token');

  static Future<void> saveToken(String value) async =>
      (await SharedPreferences.getInstance()).setString('staff_token', value);

  static Future<void> clearToken() async =>
      (await SharedPreferences.getInstance()).remove('staff_token');

  static String _extractMessage(Map<String, dynamic> data, int statusCode) {
    final errors = data['errors'];
    var message = data['message']?.toString() ??
        'Request failed ($statusCode).';
    if (errors is Map &&
        errors.isNotEmpty &&
        errors.values.first is List &&
        (errors.values.first as List).isNotEmpty) {
      message = (errors.values.first as List).first.toString();
    }
    return message;
  }

  static Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return {};
    try {
      final value = jsonDecode(body);
      if (value is Map<String, dynamic>) return value;
      return {};
    } catch (_) {
      throw Exception(
          'The server returned a non-JSON response. Check API_BASE_URL and Laravel logs.');
    }
  }

  static Future<Map<String, dynamic>> req(String method, String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    final uri = Uri.parse('$baseUrl$path');
    final response = method == 'POST'
        ? await http.post(uri, headers: headers, body: jsonEncode(body ?? {}))
        : await http.get(uri, headers: headers);
    final data = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(data, response.statusCode));
    }
    return data;
  }

  static Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final t = await token;
    if (t != null) headers['Authorization'] = 'Bearer $t';
    final uri = Uri.parse('$baseUrl$path');
    final response =
        await http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
    final data = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(data, response.statusCode));
    }
    return data;
  }

  static Future<Map<String, dynamic>> uploadFile(
      String path, String fieldName, String filePath) async {
    final t = await token;
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    if (t != null) request.headers['Authorization'] = 'Bearer $t';
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(data, response.statusCode));
    }
    return data;
  }
}
