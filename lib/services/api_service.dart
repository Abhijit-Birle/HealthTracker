// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config.dart';

class ApiService {
  // Use .env or fallback
  static String backendBase() {
    final envUrl = dotenv.env['BACKEND_BASE'];
    return envUrl ?? DEFAULT_BACKEND;
  }

  // Request a presigned URL from backend
  // Expects: POST /api/upload/presigned { fileName }
  // Response: { uploadUrl, fileUrl }
  static Future<Map<String, dynamic>> getPresignedUrl(String fileName) async {
    if (USE_MOCK) {
      // Mock presigned url: we simulate a successful "upload" by returning the final fileUrl
      return {
        'uploadUrl': 'https://mock-s3.local/upload/$fileName', // not actually used
        'fileUrl': 'https://mock-s3.local/$fileName'
      };
    }

    final resp = await http.post(
      Uri.parse('${backendBase()}/api/upload/presigned'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fileName': fileName}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to request presigned url: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // PUT bytes to a presigned url
  static Future<bool> uploadBytesToPresigned(String uploadUrl, Uint8List bytes) async {
    if (USE_MOCK) {
      // simulate uploaded
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }
    final resp = await http.put(Uri.parse(uploadUrl), body: bytes, headers: {
      'Content-Type': 'application/octet-stream',
    });
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  // Notify backend to process the image and return meal JSON
  static Future<Map<String, dynamic>> notifyProcessImage(String imageUrl) async {
    if (USE_MOCK) {
      // return a mocked meal response
      await Future.delayed(const Duration(seconds: 1));
      return {
        "name": "Grilled chicken salad",
        "calories": 420,
        "protein": 38,
        "carbs": 20,
        "fat": 18,
        "date": DateTime.now().toUtc().toIso8601String(),
        "imageUrl": imageUrl
      };
    }

    final resp = await http.post(
      Uri.parse('${backendBase()}/api/meals/process'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageUrl': imageUrl}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed process image: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // Workout suggestion
  static Future<Map<String, dynamic>> getWorkoutSuggestion(String goal, String experience) async {
    if (USE_MOCK) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'program': [
          {'exercise': 'Push Ups', 'sets': 3, 'reps': '8-12'},
          {'exercise': 'Squats', 'sets': 3, 'reps': '12-15'},
          {'exercise': 'Plank', 'sets': 3, 'reps': '30s'}
        ],
        'notes': 'Beginner friendly full-body routine for muscle gain.'
      };
    }

    final resp = await http.post(
      Uri.parse('${backendBase()}/api/workouts/suggest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'goal': goal, 'experience': experience}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Workout suggestion failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
