// lib/models/meal.dart
class Meal {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime date;
  final String? imageUrl;

  Meal({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
    this.imageUrl,
  });

  factory Meal.fromJson(Map<String, dynamic> j) {
    return Meal(
      name: j['name'] ?? 'Meal',
      calories: (j['calories'] ?? 0).toDouble(),
      protein: (j['protein'] ?? 0).toDouble(),
      carbs: (j['carbs'] ?? 0).toDouble(),
      fat: (j['fat'] ?? 0).toDouble(),
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      imageUrl: j['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'date': date.toIso8601String(),
        'imageUrl': imageUrl,
      };
}
