import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  static final String base = dotenv.env["BACKEND_BASE"]!;

  Future<Map<String, dynamic>> login(String email, String name) async {
    final url = Uri.parse('http://192.168.1.7:8080/api/auth/login');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'name': name}),
    );
    if (resp.statusCode != 200) throw Exception('Login failed: ${resp.body}');
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // Remove 'static' so you can use it via the 'api' instance injected into the provider
// Change return type to Future<Map<String, dynamic>>
  static Future<Map<String, dynamic>> syncHealth(int userId, List<Map<String, dynamic>> points) async {
    final url = Uri.parse('http://192.168.1.7:8080/api/health/sync'); // Ensure 'base' is accessible

    final body = jsonEncode({
      "userId": userId,
      "deviceId": "device-ios",
      "source": "apple_health",
      "idempotencyKey": DateTime.now().millisecondsSinceEpoch.toString(),
      "points": points
    });

    final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body
    );

    if (res.statusCode != 200) {
      throw Exception("Sync failed: ${res.body}");
    }

    // Return the body so the Provider can update Tab1Dto
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> fetchRecords(int userId) async {
    final url = Uri.parse('http://192.168.1.7:8080/api/health?userId=$userId');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception("Fetch failed: ${res.body}");
    }
    return jsonDecode(res.body);
  }
}
