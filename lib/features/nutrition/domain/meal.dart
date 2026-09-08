import '../../../core/database/database.dart' as db;

/// Domain model for a meal record.
///
/// A meal groups one or more [Food] servings via the `meal_foods` join.
/// Its calories/macros are DERIVED from its foods and portions; they are
/// never stored on the meal itself (DATABASE.md §4).
class Meal {
  final String id;
  final String mealType;
  final DateTime date;
  final DateTime time;
  final String? notes;

  const Meal({
    required this.id,
    required this.mealType,
    required this.date,
    required this.time,
    this.notes,
  });

  factory Meal.fromRow(db.Meal row) => Meal(
    id: row.id,
    mealType: row.mealType,
    date: row.date,
    time: row.time,
    notes: row.notes,
  );
}
