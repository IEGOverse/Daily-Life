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

  /// Indonesian muscle group label, e.g. "Kaki".
  String get muscleGroupLabel => muscleGroupLabelFor(muscleGroup);
}

/// Maps a muscle group key to its Indonesian label, e.g. "legs" → "Kaki".
String muscleGroupLabelFor(String group) => switch (group) {
  'chest' => 'Dada',
  'back' => 'Punggung',
  'legs' => 'Kaki',
  'shoulders' => 'Bahu',
  'arms' => 'Lengan',
  'core' => 'Inti',
  _ => group[0].toUpperCase() + group.substring(1),
};
