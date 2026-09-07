import '../../../core/database/database.dart' as db;

/// Muscle groups used by the workout library.
const List<String> exerciseMuscleGroups = [
  'chest',
  'back',
  'legs',
  'shoulders',
  'arms',
  'core',
];

/// Domain model for an exercise in the workout library (PRD §7).
class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String? description;
  final String? instructions;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
    this.instructions,
  });

  factory Exercise.fromRow(db.Exercise row) {
    return Exercise(
      id: row.id,
      name: row.name,
      muscleGroup: row.muscleGroup,
      description: row.description,
      instructions: row.instructions,
    );
  }

  /// Human-readable muscle group label, e.g. "Legs".
  String get muscleGroupLabel =>
      muscleGroup[0].toUpperCase() + muscleGroup.substring(1);
}
