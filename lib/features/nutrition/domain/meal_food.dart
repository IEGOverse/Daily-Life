import '../../../core/database/database.dart' as db;

/// Domain model for a single food serving within a meal.
class MealFood {
  final String id;
  final String mealId;
  final String foodId;
  final double quantity;
  final String unit;

  const MealFood({
    required this.id,
    required this.mealId,
    required this.foodId,
    required this.quantity,
    required this.unit,
  });

  factory MealFood.fromRow(db.MealFood row) => MealFood(
    id: row.id,
    mealId: row.mealId,
    foodId: row.foodId,
    quantity: row.quantity,
    unit: row.unit,
  );
}
