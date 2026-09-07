import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart' as db;
import '../../core/database/database_provider.dart';
import '../activities/activity_providers.dart';
import '../dashboard/dashboard_providers.dart';
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

/// One-shot future that seeds + generates for the current week. Completes on
/// first read.
final _seedAndGenerateFutureProvider = FutureProvider<void>((ref) async {
  final database = ref.read(databaseProvider);
  final now = ref.read(clockProvider);
  await ensureSeededAndGenerated(database, now: now);
  // Seeding may have inserted activities below cached providers; refresh them
  // so the dashboard and today list aren't empty until a manual reload.
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(activitiesForDayProvider);
});

/// Watches the seeding future. Safe to call from a widget's build method:
/// the first watch triggers the seeding; subsequent watches are no-ops.
void useSeeding(WidgetRef ref) {
  ref.watch(_seedAndGenerateFutureProvider);
}
