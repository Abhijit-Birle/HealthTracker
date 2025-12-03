// lib/services/health_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; // used by askForEmail - move to UI if preferred
import 'package:health/health.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class HealthService {
  final Health _health = Health();
  static final Uuid _uuid = const Uuid();

  List<HealthDataType> get _allHealthTypes => [
    // Activity & movement
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.EXERCISE_TIME,

    // Workouts
    HealthDataType.WORKOUT,

    // Vitals
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.WALKING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BODY_TEMPERATURE,

    // Body composition
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BODY_MASS_INDEX,

    // Sleep & mind
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.MINDFULNESS,

    // Respiratory & fitness capacity
    HealthDataType.RESPIRATORY_RATE,

    // Nutrition
    HealthDataType.DIETARY_ENERGY_CONSUMED,
    HealthDataType.DIETARY_PROTEIN_CONSUMED,
    HealthDataType.DIETARY_CARBS_CONSUMED,
    HealthDataType.DIETARY_FATS_CONSUMED,

    // Other (ECG & glucose)
    HealthDataType.ELECTROCARDIOGRAM,
    HealthDataType.BLOOD_GLUCOSE,
  ];

  // -------------------- Fetch from HealthKit --------------------
  Future<List<HealthDataPoint>> fetchDailyData({DateTime? from, DateTime? to}) async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      throw UnsupportedError('Platform not supported for Health APIs');
    }

    var typesToRead = _allHealthTypes.toList();
    if (Platform.isAndroid) {
      typesToRead.removeWhere((t) => t == HealthDataType.ELECTROCARDIOGRAM);
    }

    List<HealthDataAccess> permissions = List.filled(typesToRead.length, HealthDataAccess.READ);

    final authorized = await _health.requestAuthorization(typesToRead, permissions: permissions);
    if (!authorized) {
      print('Health permission incomplete or denied.');
    }

    final DateTime now = to ?? DateTime.now();
    final DateTime start = from ?? DateTime(now.year, now.month, now.day);

    final raw = await _health.getHealthDataFromTypes(startTime: start, endTime: now, types: typesToRead);
    return _health.removeDuplicates(raw);
  }

  // -------------------- Prepare payload --------------------
  List<Map<String, dynamic>> preparePayload(List<HealthDataPoint> data, {required String userId}) {
    return data.map((e) {
      final Map<String, dynamic> metadata = {};

      String sampleId;
      try {
        final json = e.toJson();
        sampleId = (json['id']?.toString() ?? '');
      } catch (_) {
        sampleId = '';
      }
      if (sampleId.isEmpty) sampleId = _uuid.v4();

      try {
        final j = e.toJson();
        if (j is Map && j.containsKey('device') && j['device'] != null) {
          metadata['device'] = j['device'];
        }
      } catch (_) {}

      dynamic value;
      String valueType = 'unknown';

      if (e.value is NumericHealthValue) {
        final num? n = (e.value as NumericHealthValue).numericValue;
        value = (n != null) ? n.toDouble() : null;
        valueType = 'numeric';
      } else if (e.workoutSummary != null) {
        valueType = 'workout';
        try {
          value = _safeToJson(e.workoutSummary);
        } catch (_) {
          value = e.workoutSummary.toString();
        }
      } else {
        try {
          final dynamic vJson = (e.value != null && _hasToJson(e.value)) ? (e.value as dynamic).toJson() : e.value?.toString();
          value = vJson;
          valueType = (vJson is Map) ? (vJson['__type']?.toString() ?? 'object') : 'string';
          if (value is Map && value.containsKey('voltage_values')) {
            value.remove('voltage_values');
            value['hasVoltageValues'] = true;
          }
        } catch (_) {
          valueType = 'string';
          value = e.value?.toString();
        }
      }

      metadata['platform'] = Platform.operatingSystem;
      metadata['sourceName'] = e.sourceName;
      metadata['sourceId'] = e.sourceId;
      metadata['sourceDeviceId'] = e.sourceDeviceId;
      metadata['unit'] = e.unitString;
      metadata['valueType'] = valueType;
      metadata['originalType'] = e.typeString;

      if (e.type == HealthDataType.SLEEP_ASLEEP || e.type == HealthDataType.SLEEP_IN_BED || e.type == HealthDataType.SLEEP_AWAKE) {
        metadata['sleepState'] = e.value.toString();
      }

      if (e.type == HealthDataType.HEART_RATE || e.type == HealthDataType.RESTING_HEART_RATE || e.type == HealthDataType.WALKING_HEART_RATE) {
        metadata['isContinuousStream'] = true;
      }

      if (e.type == HealthDataType.WEIGHT) {
        metadata['isWeight'] = true;
        if (value == null && e.value != null) {
          final parsed = double.tryParse(e.value.toString());
          value = parsed;
        }
        print('Weight sample found: sampleId=$sampleId value=$value unit=${e.unitString} from=${e.dateFrom}');
      }

      return {
        'userId': userId,
        'sampleId': sampleId,
        'type': e.typeString,
        'value': value,
        'unit': e.unitString,
        'date_from': e.dateFrom.toUtc().toIso8601String(),
        'date_to': e.dateTo.toUtc().toIso8601String(),
        'metadata': metadata,
        'uploadedAt': DateTime.now().toUtc().toIso8601String(),
      };
    }).toList();
  }

  // -------------------- Low-level sync --------------------
  Future<Map<String, dynamic>> syncToBackendRawChunk(
      List<Map<String, dynamic>> payloadBatch, {
        required String backendUrl,
        required String? authToken,
        required int? currentUserId,
        String? emailForProvision,
      }) async {
    final uri = Uri.parse(backendUrl);
    final client = http.Client();
    try {
      final body = await _buildSyncRequest(userId: currentUserId, email: emailForProvision, samples: payloadBatch);

      final resp = await client.post(uri,
          headers: {
            'Content-Type': 'application/json',
            if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode(body));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;

        if (json.containsKey('userId')) {
          final dynamic u = json['userId'];
          if (u is int) {
            await _setStoredUserId(u);
          } else if (u is String) {
            final parsed = int.tryParse(u);
            if (parsed != null) await _setStoredUserId(parsed);
          }
        }

        if (json.containsKey('lastSyncedAt')) {
          try {
            final DateTime serverTs = DateTime.parse(json['lastSyncedAt']).toUtc();
            final int storeFor = currentUserId ?? (await _getStoredUserId() ?? 0);
            await _setLocalLastSynced(userId: storeFor, ts: serverTs);
          } catch (_) {}
        }

        return json;
      } else {
        throw Exception('Sync failed ${resp.statusCode}: ${resp.body}');
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _buildSyncRequest({
    required int? userId,
    String? email,
    required List<Map<String, dynamic>> samples,
  }) async {
    return {
      'userId': userId,
      'metaDataEmail': email,
      'points': samples,
    };
  }

  // NOTE: askForEmail is a convenience helper; move to UI if you prefer
  Future<String?> askForEmail(BuildContext ctx) async {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Enter email (optional)'),
        content: TextField(controller: controller, keyboardType: TextInputType.emailAddress),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('Skip')),
          ElevatedButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _retryFailedChunks(int userId, String backendSyncUrl, String authToken) async {
    final chunks = await _loadFailedChunks(userId);
    for (final entry in chunks) {
      final List<Map<String, dynamic>> chunk = (entry['chunk'] as List).cast<Map<String, dynamic>>();
      final String entryId = entry['id'] as String;
      try {
        final resp = await syncToBackendRawChunk(chunk, backendUrl: backendSyncUrl, authToken: authToken, currentUserId: await _getStoredUserId());
        // remove chunk if success
        await _removeFailedChunkEntry(userId, entryId);
      } catch (_) {
        break;
      }
    }
  }

  // -------------------- Server status --------------------
  Future<DateTime?> fetchServerLastSynced({
    required String backendStatusUrl,
    required int userId,
    required String authToken,
  }) async {
    final uri = Uri.parse('$backendStatusUrl?userId=$userId');
    final client = http.Client();
    try {
      final resp = await client.get(uri, headers: {
        if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken'
      });

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final last = body['lastSyncedAt'] as String?;
        if (last != null && last.isNotEmpty) return DateTime.parse(last).toUtc();
        return null;
      } else {
        throw Exception('Failed to fetch sync status: ${resp.statusCode} ${resp.body}');
      }
    } finally {
      client.close();
    }
  }

  Future<DateTime?> _getLocalLastSynced({required int userId}) async {
    final pref = await SharedPreferences.getInstance();
    final s = pref.getString('lastSynced_$userId');
    if (s == null) return null;
    try {
      return DateTime.parse(s).toUtc();
    } catch (_) {
      return null;
    }
  }

// ⭐ Public method
  Future<DateTime?> getLocalLastSynced(int userId) async {
    return _getLocalLastSynced(userId: userId);
  }


  // -------------------- High-level sync flow --------------------
  Future<void> syncSinceLastSynced({
    required int userId,
    required String backendStatusUrl,
    required String backendSyncUrl,
    required String authToken,
    Duration? lookbackWindowIfNull,
  }) async {
    DateTime? lastSynced;
    try {
      lastSynced = await fetchServerLastSynced(backendStatusUrl: backendStatusUrl, userId: userId, authToken: authToken);
    } catch (err) {
      print('fetchServerLastSynced failed: $err — falling back to local');
      lastSynced = await _getLocalLastSynced(userId: userId);
    }

    if (lastSynced == null) {
      if (lookbackWindowIfNull != null) {
        lastSynced = DateTime.now().toUtc().subtract(lookbackWindowIfNull);
      } else {
        final now = DateTime.now();
        lastSynced = DateTime(now.year, now.month, now.day).toUtc();
      }
    }

    final samples = await fetchDailyData(from: lastSynced, to: DateTime.now().toUtc());
    final payload = preparePayload(samples, userId: userId.toString());

    const int chunkSize = 400;
    DateTime? newestServerTime;
    for (var i = 0; i < payload.length; i += chunkSize) {
      final end = (i + chunkSize) > payload.length ? payload.length : (i + chunkSize);
      final chunk = payload.sublist(i, end);
      try {
        final resp = await syncToBackendRawChunk(chunk, backendUrl: backendSyncUrl, authToken: authToken, currentUserId: userId, emailForProvision: null);

        if (resp.containsKey('lastSyncedAt')) {
          try {
            newestServerTime = DateTime.parse(resp['lastSyncedAt']).toUtc();
          } catch (_) {}
        }

        if (resp.containsKey('acks')) {
          final acks = resp['acks'] as List<dynamic>;
          final accepted = acks.where((a) {
            final s = a['status']?.toString();
            return s == 'accepted' || s == 'duplicate';
          }).map((a) => a['sampleId']?.toString()).whereType<String>().toList();

          print('Chunk accepted sampleIds count: ${accepted.length}');
        }

        if (resp.containsKey('tab1')) {
          print('Server returned tab1 in response (apply to UI).');
        }
      } catch (err) {
        print('Sync chunk failed: $err — saving failed chunk for retry');
        await _saveFailedChunk(userId: userId, chunk: chunk);
        rethrow;
      }
    }

    final toStore = newestServerTime ?? DateTime.now().toUtc();
    await _setLocalLastSynced(userId: userId, ts: toStore);
    print('Sync finished. Stored lastSynced=$toStore');
  }

  // -------------------- SharedPreferences helpers --------------------
  Future<void> _setLocalLastSynced({required int userId, required DateTime ts}) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('lastSynced_$userId', ts.toUtc().toIso8601String());
  }



  Future<void> _setStoredUserId(int userId) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('userId', userId);
  }

  Future<int?> _getStoredUserId() async {
    final p = await SharedPreferences.getInstance();
    return p.containsKey('userId') ? p.getInt('userId') : null;
  }

  Future<void> _setAuthToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('authToken', token);
  }

  Future<String?> _getAuthToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('authToken');
  }

  // -------------------- Failed-chunk local queue (file-based) --------------------
  // Stored as JSON array of { id, ts, chunk }
  Future<Directory> _getAppDir() async {
    return await getApplicationDocumentsDirectory();
  }

  Future<File> _failedChunksFile(int userId) async {
    final dir = await _getAppDir();
    return File('${dir.path}/failed_chunks_user_$userId.json');
  }

  Future<void> _saveFailedChunk({required int userId, required List<Map<String, dynamic>> chunk}) async {
    final f = await _failedChunksFile(userId);
    List existing = [];
    if (await f.exists()) {
      try {
        final contents = await f.readAsString();
        existing = jsonDecode(contents) as List;
      } catch (_) {
        existing = [];
      }
    }
    final entry = {
      'id': _uuid.v4(),
      'ts': DateTime.now().toUtc().toIso8601String(),
      'chunk': chunk,
    };
    existing.add(entry);
    await f.writeAsString(jsonEncode(existing));
  }

  Future<List<Map<String, dynamic>>> _loadFailedChunks(int userId) async {
    final f = await _failedChunksFile(userId);
    if (!await f.exists()) return [];
    try {
      final contents = await f.readAsString();
      final List arr = jsonDecode(contents) as List;
      return arr.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _removeFailedChunkEntry(int userId, String entryId) async {
    final f = await _failedChunksFile(userId);
    if (!await f.exists()) return;
    try {
      final contents = await f.readAsString();
      final List arr = jsonDecode(contents) as List;
      final filtered = arr.where((e) => (e as Map)['id'] != entryId).toList();
      await f.writeAsString(jsonEncode(filtered));
    } catch (_) {}
  }

  // Call this from your UI when user submits email/login
  Future<int> createOrGetUserByEmail(String backendBase, String email, {String authToken = ''}) async {
    // preferred: POST /api/users { email }
    final uri = Uri.parse('$backendBase/api/users');
    final client = http.Client();
    try {
      final resp = await client.post(uri,
        headers: {
          'Content-Type': 'application/json',
          if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken'
        },
        body: jsonEncode({'email': email}),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = jsonDecode(resp.body);
        // expect { userId: 123 } or similar
        final u = body['userId'];
        if (u != null) {
          final uid = (u is int) ? u : int.tryParse(u.toString());
          if (uid != null) {
            await _setStoredUserId(uid);
            return uid;
          }
        }
        throw Exception('Invalid response from /api/users: ${resp.body}');
      } else if (resp.statusCode == 409) {
        // conflict - maybe returns existing user
        final body = jsonDecode(resp.body);
        final u = body['userId'];
        if (u != null) {
          final uid = (u is int) ? u : int.tryParse(u.toString());
          if (uid != null) {
            await _setStoredUserId(uid);
            return uid;
          }
        }
        throw Exception('User create conflict: ${resp.body}');
      } else {
        // fallback to /api/sync approach below
        return await createOrGetUserByEmailFallback(backendBase, email, authToken: authToken);
      }
    } catch (err) {
      // fallback if /api/users not available or network error
      return await createOrGetUserByEmailFallback(backendBase, email, authToken: authToken);
    } finally {
      client.close();
    }
  }

  Future<int> createOrGetUserByEmailFallback(String backendBase, String email, {String authToken = ''}) async {
    // Some servers may accept POST /api/sync?email=<email> to auto-provision
    // We'll call POST /api/sync?email=<email> with an empty HealthSyncRequest body
    final uri = Uri.parse('http://192.168.1.4:8080/api/sync?email=${Uri.encodeComponent(email)}');
    final client = http.Client();
    try {
      // send minimal request body (empty points), server should create or return user
      final resp = await client.post(uri,
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'points': []}),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        // server earlier suggested returning HealthSyncResponse; check 'userId' or other fields
        if (body.containsKey('userId')) {
          final u = body['userId'];
          final uid = (u is int) ? u : int.tryParse(u.toString());
          if (uid != null) {
            await _setStoredUserId(uid);
            return uid;
          }
        }

        // If server didn't return userId, attempt to extract from nested location
        if (body.containsKey('data') && body['data'] is Map && body['data'].containsKey('userId')) {
          final u = body['data']['userId'];
          final uid = (u is int) ? u : int.tryParse(u.toString());
          if (uid != null) {
            await _setStoredUserId(uid);
            return uid;
          }
        }

        // If server returns tab1 and saves but doesn't return userId, fallback to fetch by email endpoint (if exists)
        // Try GET /api/users?email=
        final maybeUid = await _getUserIdByEmail(backendBase, email, authToken: authToken);
        if (maybeUid != null) {
          await _setStoredUserId(maybeUid);
          return maybeUid;
        }

        throw Exception('Server did not return userId during fallback provisioning: ${resp.body}');
      } else {
        throw Exception('Provisioning call failed ${resp.statusCode}: ${resp.body}');
      }
    } finally {
      client.close();
    }
  }

  Future<int?> _getUserIdByEmail(String backendBase, String email, {String authToken = ''}) async {
    // Optional helper: implement if your backend exposes GET /api/users?email=
    try {
      final uri = Uri.parse('$backendBase/api/users?email=${Uri.encodeComponent(email)}');
      final client = http.Client();
      final resp = await client.get(uri, headers: {
        if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken'
      });
      client.close();
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is Map && body.containsKey('userId')) {
          final u = body['userId'];
          return (u is int) ? u : int.tryParse(u.toString());
        }
      }
    } catch (_) {}
    return null;
  }

  /// Orchestration: call this from login UI
  /// Returns stored userId on success
  Future<int> loginAndSync({
    required String email,
    required String backendBase, // e.g. http://192.168.1.7:8080
    String authToken = '',
    Duration? lookbackWindowIfNull,
  }) async {
    // 1. Ensure user exists or create one
    final int userId = await createOrGetUserByEmail(backendBase, email, authToken: authToken);

    // 2. fetch server lastSynced for this user
    final statusUrl = '$backendBase/api/sync/status';
    DateTime? lastSynced;
    try {
      lastSynced = await fetchServerLastSynced(backendStatusUrl: statusUrl, userId: userId, authToken: authToken);
    } catch (err) {
      print('fetchServerLastSynced failed during login: $err');
      lastSynced = await _getLocalLastSynced(userId: userId) ?? DateTime.now().toUtc().subtract(Duration(days: 7));
    }

    // 3. Immediately sync since lastSynced (or lookbackWindow)
    final syncUrl = '$backendBase/api/health/sync';
    await syncSinceLastSynced(
      userId: userId,
      backendStatusUrl: statusUrl,
      backendSyncUrl: syncUrl,
      authToken: authToken,
      lookbackWindowIfNull: lookbackWindowIfNull ?? const Duration(days: 7),
    );

    return userId;
  }

  // -------------------- Public helper (UI) --------------------
  /// Returns stored userId or null if not set.
  Future<int?> getStoredUserId() async {
    return await _getStoredUserId();
  }



  // -------------------- Small helpers --------------------
  bool _hasToJson(Object? o) {
    try {
      return (o != null && (o as dynamic).toJson is Function);
    } catch (_) {
      return false;
    }
  }

  dynamic _safeToJson(Object? o) {
    try {
      return (o != null && _hasToJson(o)) ? (o as dynamic).toJson() : o?.toString();
    } catch (_) {
      return o?.toString();
    }
  }
}
