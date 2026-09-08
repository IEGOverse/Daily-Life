import '../domain/food.dart';

/// A single, transparent meal suggestion.
///
/// Recommendations are DERIVED locally from the user's food database and
/// recent meals (variety + reasonable energy portioning). They are
/// estimates, not medical advice (PRD §10, §14).
class MealSuggestion {
  final String mealType;
  final List<Food> foods;

  /// Short, explainable reason for the suggestion.
  final String reason;

  const MealSuggestion({
    required this.mealType,
    required this.foods,
    required this.reason,
  });
}
