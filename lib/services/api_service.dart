import 'dart:convert';
import 'package:flutter/foundation.dart';
// NOTE: We don't need http dependency for the simulated sync

class ApiService {
  // Static methods for easy access in the UI and services

  // 1. Sync Health Data (FIX: Now simulates backend POST)
  static Future<void> syncHealth(int userId, List<Map<String, dynamic>> data) async {
    // SIMULATION: Printing to console to verify data is sent and success is returned
    debugPrint("🚀 [API] Syncing ${data.length} records for User $userId...");
    debugPrint("📦 Payload Preview: ${data.take(2).toList()}"); // Print first 2 records

    // Simulate network delay and successful backend processing
    await Future.delayed(const Duration(seconds: 2));

    // In a real scenario, check status code here:
    // if (response.statusCode != 200) throw Exception("Sync failed");

    debugPrint("✅ [API] Sync Complete!");
  }

  // 2. Fetch User Records (Used for general dashboard state)
  static Future<List<dynamic>> fetchRecords(int userId) async {
    debugPrint("📥 [API] Fetching records for User $userId...");
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock history data
    return [
      {"date": "2023-10-27", "steps": 8430},
      {"date": "2023-10-26", "steps": 10200},
    ];
  }
}