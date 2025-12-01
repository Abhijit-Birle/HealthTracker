import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/dashboard.dart';

class HealthProvider extends ChangeNotifier {
  final ApiService api;
  Tab1Dto? tab1;
  bool syncing = false;
  static final String base = dotenv.env["BACKEND_BASE"]!;

  HealthProvider(this.api);

  // Consolidated syncHealth method
  Future<void> syncHealth(
      String? email,
      List<Map<String, dynamic>> records,
      {int? userId}
      ) async {
    syncing = true;
    notifyListeners();

    try {
      // 1. Normalize frontend records -> backend 'points' shape
      final List<Map<String, dynamic>> points = records.map((r) {
        String? start = r['startTime'] is DateTime
            ? (r['startTime'] as DateTime).toUtc().toIso8601String()
            : (r['startTime'] ?? r['start'])?.toString();

        String? end = r['endTime'] is DateTime
            ? (r['endTime'] as DateTime).toUtc().toIso8601String()
            : (r['endTime'] ?? r['end'])?.toString();

        double? measure;
        if (r['measureValue'] is num) measure = (r['measureValue'] as num).toDouble();
        else if (r['value'] is num) measure = (r['value'] as num).toDouble();
        else if (r['value'] is String) measure = double.tryParse(r['value']);

        return {
          'type': r['type'] ?? r['metric'] ?? 'unknown',
          'startTime': start,
          'endTime': end,
          'measureValue': measure,
          'source': r['source'] ?? 'app',
          'idempotencyKey': r['idempotencyKey'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        };
      }).toList();

      // 2. Call the correct API method
      // Note: syncHealthData is static, so we call it using the class name ApiService
      await ApiService.syncHealth(userId ?? 0, points);

      // Note: If you need to update 'tab1', the current syncHealthData implementation
      // in ApiService returns void, so you cannot get 'tab1Updated' from it.
      // You might need to refactor ApiService to return the data if you need it here.

    } catch (e, st) {
      debugPrint('syncHealth error: $e\n$st');
      rethrow;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }



}
