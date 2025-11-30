// lib/providers/meal_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/meal.dart';
import '../config.dart';

class MealProvider extends ChangeNotifier {
  final List<Meal> _meals = [];
  List<Meal> get meals => _meals;

  // backend base URL -- first check .env, else fallback to config default
  String get backendBase {
    final envUrl = dotenv.env['BACKEND_BASE'];
    if (!USE_MOCK) {
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
      return DEFAULT_BACKEND;
    }
    // In mock mode we still return a placeholder (not used)
    return envUrl ?? DEFAULT_BACKEND;
  }

  void addMeal(Meal meal) {
    _meals.add(meal);
    notifyListeners();
  }

  void addMealRaw(Map<String, dynamic> j) {
    _meals.add(Meal.fromJson(j));
    notifyListeners();
  }

  void clear() {
    _meals.clear();
    notifyListeners();
  }
}
