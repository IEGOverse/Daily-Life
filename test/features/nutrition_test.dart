import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/core/router/app_router.dart';
import 'package:daily_life/features/nutrition/domain/food.dart';
import 'package:daily_life/features/nutrition/domain/meal.dart';
import 'package:daily_life/features/nutrition/domain/meal_food.dart';
import 'package:daily_life/features/nutrition/data/nutrition_repository.dart';
import 'package:daily_life/main.dart';

void main() {
  group('NutritionRepository', () {
    final day = DateTime(2026, 9, 8);

    test('inserts and reads back a food', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = NutritionRepository(database);

      await repository.insertFood(
        Food(
          id: 'f1',
          name: 'Rice',
          servingSize: 100,
          servingUnit: 'g',
          calories: 130,
          protein: 2.7,
          carbohydrate: 28,
          fat: 0.3,
        ),
      );

      final foods = await repository.getFoods();
      expect(foods, hasLength(1));
      expect(foods.first.name, 'Rice');
      expect(foods.first.calories, 130);
    });

    test('inserts a meal with foods and derives daily summary', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = NutritionRepository(database);

      await repository.insertFood(
        Food(
          id: 'f1',
          name: 'Rice',
          servingSize: 100,
          servingUnit: 'g',
          calories: 130,
          protein: 2.7,
          carbohydrate: 28,
          fat: 0.3,
        ),
      );
      await repository.insertMeal(
        Meal(
          id: 'm1',
          mealType: 'Lunch',
          date: day,
          time: DateTime(2026, 9, 8, 12),
        ),
      );
      await repository.addMealFood(
        MealFood(
          id: 'mf1',
          mealId: 'm1',
          foodId: 'f1',
          quantity: 200, // 2 servings of 100g rice
          unit: 'g',
        ),
      );

      final summary = await repository.dailySummary(day);
      // 2 servings × 130 kcal = 260 kcal
      expect(summary['calories'], closeTo(260, 0.001));
      expect(summary['protein'], closeTo(5.4, 0.001));
      expect(summary['carbohydrate'], closeTo(56, 0.001));
      expect(summary['fat'], closeTo(0.6, 0.001));
      expect(summary['mealCount'], 1);
      expect(summary['foodCount'], 1);
    });

    test('daily summary only includes the requested day', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = NutritionRepository(database);

      await repository.insertFood(
        Food(
          id: 'f1',
          name: 'Rice',
          servingSize: 100,
          servingUnit: 'g',
          calories: 130,
          protein: 2.7,
          carbohydrate: 28,
          fat: 0.3,
        ),
      );
      await repository.insertMeal(
        Meal(
          id: 'm1',
          mealType: 'Lunch',
          date: day,
          time: DateTime(2026, 9, 8, 12),
        ),
      );
      await repository.addMealFood(
        MealFood(
          id: 'mf1',
          mealId: 'm1',
          foodId: 'f1',
          quantity: 100,
          unit: 'g',
        ),
      );

      final otherDay = await repository.dailySummary(DateTime(2026, 9, 9));
      expect(otherDay['mealCount'], 0);
      expect(otherDay['calories'], 0);
    });

    test('empty day has a zero summary', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = NutritionRepository(database);

      final summary = await repository.dailySummary(DateTime(2026, 9, 8));
      expect(summary['calories'], 0);
      expect(summary['mealCount'], 0);
      expect(await repository.getMeals(DateTime(2026, 9, 8)), isEmpty);
    });

    test('deletes a meal', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = NutritionRepository(database);

      await repository.insertMeal(
        Meal(
          id: 'm1',
          mealType: 'Lunch',
          date: day,
          time: DateTime(2026, 9, 8, 12),
        ),
      );
      await repository.deleteMeal('m1');

      expect(await repository.getMeals(day), isEmpty);
    });
  });

  group('Nutrition screen flow', () {
    testWidgets('renders empty state', (tester) async {
      final container = ProviderContainer(
        overrides: [inMemoryDatabaseOverride()],
      );
      addTearDown(container.dispose);
      final database = container.read(databaseProvider);
      addTearDown(database.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DailyLifeApp(),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go('/nutrition');
      await tester.pumpAndSettle();

      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('No meals recorded today yet.'), findsOneWidget);
    });
  });
}
