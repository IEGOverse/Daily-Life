import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'data/nutrition_repository.dart';
import 'domain/food.dart';

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
