import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart' as db;
import '../../core/database/database_provider.dart';
import 'data/schedule_repository.dart';

/// Day of the week shown on the schedule screen (1 = Monday … 7 = Sunday).
/// Defaults to today's weekday.
final selectedDayProvider = StateProvider<int>((ref) => DateTime.now().weekday);

/// List of schedules for the selected day.
final schedulesForDayProvider = FutureProvider<List<db.Schedule>>((ref) async {
  final database = ref.watch(databaseProvider);
  final dayOfWeek = ref.watch(selectedDayProvider);
  return database.getSchedulesByDay(dayOfWeek);
});

/// Seeds the initial university schedule (PRD §5) once, then generates
/// activities for each day in the current week.
Future<void> ensureSeededAndGenerated(db.AppDatabase database) async {
  final existing = await database.getActiveSchedules();
  if (existing.isEmpty) {
    for (final schedule in ScheduleSeeder.initialSchedules()) {
      await database.insertSchedule(schedule);
    }
  }

  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  for (var i = 0; i < 7; i++) {
    final day = DateTime(monday.year, monday.month, monday.day + i);
    await generateActivitiesForDay(database, day);
  }
}

/// One-shot future that seeds + generates. Completes on first read.
final _seedAndGenerateFutureProvider = FutureProvider<void>((ref) async {
  final database = ref.read(databaseProvider);
  await ensureSeededAndGenerated(database);
});

/// Watches the seeding future. Safe to call from a widget's build method:
/// the first watch triggers the seeding; subsequent watches are no-ops.
void useSeeding(WidgetRef ref) {
  ref.watch(_seedAndGenerateFutureProvider);
}
