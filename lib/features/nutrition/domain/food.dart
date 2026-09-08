import '../../../core/database/database.dart' as db;

/// Domain model for a food item in the nutrition database.
///
/// Nutrition values are estimates and are NOT medical-grade measurements
/// (PRD §10).
class Food {
  final String id;
  final String name;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbohydrate;
  final double fat;

  const Food({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbohydrate,
    required this.fat,
  });

  factory Food.fromRow(db.Food row) => Food(
    id: row.id,
    name: row.name,
    servingSize: row.servingSize,
    servingUnit: row.servingUnit,
    calories: row.calories,
    protein: row.protein,
    carbohydrate: row.carbohydrate,
    fat: row.fat,
  );
}
