import 'workout_session.dart';

class WorkoutHistory {
  final List<WorkoutSession> completedSessions;
  final int totalDurationSeconds;
  final int completedSets;

  const WorkoutHistory({
    required this.completedSessions,
    required this.totalDurationSeconds,
    required this.completedSets,
  });

  int get sessionCount => completedSessions.length;
}
