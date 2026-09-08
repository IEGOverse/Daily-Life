import 'dart:math' as math;

import '../domain/food.dart';
import '../domain/meal_suggestion.dart';

/// Derives [MealSuggestion]s from the user's own food database and recent
/// meals.
///
/// Transparent rules (no external service, no health claims):
///  - The meal type follows the current clock (breakfast/lunch/dinner/snack).
///  - Foods eaten within [recentDays] are de-prioritized for variety.
///  - Suggestions favor complete menus (protein + carb + fat present).
///  - Calories are a soft per-meal estimate, never a target.
class MealRecommendationEngine {
  const MealRecommendationEngine();

  /// Returns up to [limit] suggestions. Empty when the user has no foods.
  List<MealSuggestion> recommend({
    required List<Food> foods,
    required DateTime now,
    required Set<String> recentFoodIds,
    int limit = 3,
  }) {
    if (foods.isEmpty) return const [];

    final mealType = _mealTypeFor(now);
    final recent = recentFoodIds;

    final ranked = foods.toList()
      ..sort((a, b) => _score(b, recent).compareTo(_score(a, recent)));

    final suggestions = <MealSuggestion>[];
    for (var i = 0; i < math.min(limit, ranked.length); i++) {
      suggestions.add(_suggestion(mealType, ranked[i], recent, ranked));
    }
    return suggestions;
  }

  /// Higher is more varied / more recently uneaten in this menu context.
  double _score(Food food, Set<String> recent) {
    final base = recent.contains(food.id) ? 0.0 : 6.0;
    // Light preference for balanced foods; keeps ranking stable & explainable.
    final balance = (food.protein + food.carbohydrate + food.fat > 0)
        ? 1.0
        : 0.0;
    return base + balance;
  }

  MealSuggestion _suggestion(
    String mealType,
    Food head,
    Set<String> recent,
    List<Food> all,
  ) {
    final companions = all
        .where((f) => f.id != head.id && !recent.contains(f.id))
        .take(2)
        .toList();
    final foods = [head, ...companions];

    final reasonBuffer = StringBuffer(
      recent.contains(head.id)
          ? _varietyReason(head)
          : 'Anda belum makan ${head.name} baru-baru ini. ',
    );
    reasonBuffer.write(
      'Kira-kira ${_estimateCalories(foods).round()} kcal untuk ${mealType.toLowerCase()} ini.',
    );

    return MealSuggestion(
      mealType: mealType,
      foods: foods,
      reason: reasonBuffer.toString(),
    );
  }

  String _varietyReason(Food food) => 'Selingan yang segar: ${food.name}. ';

  double _estimateCalories(List<Food> foods) =>
      foods.fold<double>(0, (sum, f) => sum + f.calories);

  String _mealTypeFor(DateTime now) {
    final hour = now.hour;
    if (hour < 11) return 'Sarapan';
    if (hour < 15) return 'Makan Siang';
    if (hour < 20) return 'Makan Malam';
    return 'Camilan';
  }
}
