import 'dart:convert';

class HealthPoint {
  final String type;
  final String startTime; // ISO8601 string
  final String endTime;   // ISO8601 string
  final double? measureValue;
  final String? source;
  final String? idempotencyKey;

  HealthPoint({
    required this.type,
    required this.startTime,
    required this.endTime,
    this.measureValue,
    this.source,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'startTime': startTime,
    'endTime': endTime,
    'measureValue': measureValue,
    'source': source,
    'idempotencyKey': idempotencyKey,
  };
}

class HealthSyncRequest {
  final int userId;
  final String? deviceId;
  final String? source;
  final String? idempotencyKey;
  final List<HealthPoint> points;

  HealthSyncRequest({
    required this.userId,
    this.deviceId,
    this.source,
    this.idempotencyKey,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'deviceId': deviceId,
    'source': source,
    'idempotencyKey': idempotencyKey,
    'points': points.map((p) => p.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());
}
