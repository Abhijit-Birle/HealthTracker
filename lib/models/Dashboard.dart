class DailyPoint {
  final String date;
  final double steps;
  final double calories;
  DailyPoint({required this.date, required this.steps, required this.calories});
  factory DailyPoint.fromJson(Map<String, dynamic> j) => DailyPoint(
    date: j['date'] ?? '',
    steps: (j['steps'] ?? 0).toDouble(),
    calories: (j['calories'] ?? 0).toDouble(),
  );
}

class Aggregates {
  final double totalSteps;
  final double avgSteps;
  Aggregates({required this.totalSteps, required this.avgSteps});
  factory Aggregates.fromJson(Map<String, dynamic> j) => Aggregates(
    totalSteps: (j['totalSteps'] ?? 0).toDouble(),
    avgSteps: (j['avgSteps'] ?? 0).toDouble(),
  );
}

class Tab1Dto {
  final List<DailyPoint> daily;
  final Aggregates aggregates;
  final String? lastSyncedAt;
  Tab1Dto({required this.daily, required this.aggregates, this.lastSyncedAt});
  factory Tab1Dto.fromJson(Map<String, dynamic> j) => Tab1Dto(
    daily: (j['daily'] as List<dynamic>? ?? []).map((e) => DailyPoint.fromJson(e)).toList(),
    aggregates: Aggregates.fromJson(j['aggregates'] ?? {}),
    lastSyncedAt: j['lastSyncedAt']?.toString(),
  );
}

class Dashboard {
  final Tab1Dto tab1;
  final String serverTime;
  Dashboard({required this.tab1, required this.serverTime});
  factory Dashboard.fromJson(Map<String, dynamic> j) => Dashboard(
    tab1: Tab1Dto.fromJson(j['tab1'] ?? {}),
    serverTime: j['serverTime']?.toString() ?? '',
  );
}
