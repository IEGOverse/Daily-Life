import 'package:daily_life/core/database/database.dart' as db;

import '../domain/food.dart';
import '../domain/meal.dart';
import '../domain/meal_food.dart';

/// Repository for the Nutrition module.
///
/// Provides food database access, meal records, and a DERIVED daily nutrition
/// summary. Meal calories/macros are computed as
/// `sum(meal_foods quantity × food nutrition per serving)`; they are never
/// stored on the meal (DATABASE.md §4).
class NutritionRepository {
  final db.AppDatabase _database;

  NutritionRepository(this._database);

  // --- Foods --------------------------------------------------------------
  Future<List<Food>> getFoods() async =>
      (await _database.getAllFoods()).map(Food.fromRow).toList();

  Future<Food?> foodById(String id) async {
    final row = await _database.getFoodById(id);
    return row == null ? null : Food.fromRow(row);
  }

  Future<void> insertFood(Food food) => _database.insertFood(
    db.Food(
      id: food.id,
      name: food.name,
      servingSize: food.servingSize,
      servingUnit: food.servingUnit,
      calories: food.calories,
      protein: food.protein,
      carbohydrate: food.carbohydrate,
      fat: food.fat,
    ),
  );

  // --- Meals ---------------------------------------------------------------
  Future<List<Meal>> getMeals(DateTime day) async =>
      (await _database.getMealsForDay(day)).map(Meal.fromRow).toList();

  Future<Meal?> mealById(String id) async {
    final row = await _database.getMealById(id);
    return row == null ? null : Meal.fromRow(row);
  }

  Future<void> insertMeal(Meal meal) => _database.insertMeal(
    db.Meal(
      id: meal.id,
      mealType: meal.mealType,
      date: meal.date,
      time: meal.time,
      notes: meal.notes,
    ),
  );

  Future<void> deleteMeal(String id) => _database.deleteMeal(id);

  /// Adds a food serving to a meal.
  Future<void> addMealFood(MealFood mealFood) => _database.insertMealFood(
    db.MealFood(
      id: mealFood.id,
      mealId: mealFood.mealId,
      foodId: mealFood.foodId,
      quantity: mealFood.quantity,
      unit: mealFood.unit,
    ),
  );

  Future<List<MealFood>> mealFoods(String mealId) async =>
      (await _database.getMealFoods(mealId)).map(MealFood.fromRow).toList();

  // --- Daily nutrition summary --------------------------------------------
  /// Computes the DERIVED nutrition summary for [day].
  ///
  /// For each meal, macros are the sum over its foods of
  /// `quantity / food.servingSize × food.nutrition`. No values are stored.
  Future<Map<String, dynamic>> dailySummary(DateTime day) async {
    final meals = await getMeals(day);
    var totalCalories = 0.0;
    var totalProtein = 0.0;
    var totalCarbs = 0.0;
    var totalFat = 0.0;
    var foodCount = 0;

    final mealSummaries = <Map<String, dynamic>>[];
    for (final meal in meals) {
      final items = await mealFoods(meal.id);
      var mealCalories = 0.0;
      var mealProtein = 0.0;
      var mealCarbs = 0.0;
      var mealFat = 0.0;
      final entries = <Map<String, dynamic>>[];

      for (final item in items) {
        final food = await foodById(item.foodId);
        if (food == null) continue;
        final servings = item.quantity / food.servingSize;
        mealCalories += servings * food.calories;
        mealProtein += servings * food.protein;
        mealCarbs += servings * food.carbohydrate;
        mealFat += servings * food.fat;
        foodCount += 1;
        entries.add({
          'food': food,
          'quantity': item.quantity,
          'unit': item.unit,
        });
      }

      totalCalories += mealCalories;
      totalProtein += mealProtein;
      totalCarbs += mealCarbs;
      totalFat += mealFat;
      mealSummaries.add({
        'meal': meal,
        'calories': mealCalories,
        'protein': mealProtein,
        'carbohydrate': mealCarbs,
        'fat': mealFat,
        'entries': entries,
      });
    }

    return {
      'day': day,
      'calories': totalCalories,
      'protein': totalProtein,
      'carbohydrate': totalCarbs,
      'fat': totalFat,
      'foodCount': foodCount,
      'mealCount': meals.length,
      'meals': mealSummaries,
    };
  }
}
