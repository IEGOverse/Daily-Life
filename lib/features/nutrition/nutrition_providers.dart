import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../dashboard/dashboard_providers.dart' show clockProvider;
import 'data/nutrition_repository.dart';
import 'domain/food.dart';
import 'domain/meal_suggestion.dart';
import 'services/meal_recommendation_engine.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => NutritionRepository(ref.watch(databaseProvider)),
);

/// All foods in the database, ordered by name.
final foodsProvider = FutureProvider<List<Food>>((ref) {
  return ref.watch(nutritionRepositoryProvider).getFoods();
});

/// Derived nutrition summary for a given local day.
final dailyNutritionProvider =
    FutureProvider.family<Map<String, dynamic>, DateTime>(
      (ref, day) => ref.watch(nutritionRepositoryProvider).dailySummary(day),
    );

/// Local, transparent meal suggestions derived from the user's own foods and
/// recent meals. Estimates, not medical advice.
final mealSuggestionsProvider = FutureProvider<List<MealSuggestion>>((
  ref,
) async {
  final repo = ref.watch(nutritionRepositoryProvider);
  final now = ref.watch(clockProvider);
  const engine = MealRecommendationEngine();
  final foods = await repo.getFoods();
  final recent = await repo.recentFoodIds(now: now);
  return engine.recommend(foods: foods, now: now, recentFoodIds: recent);
});
