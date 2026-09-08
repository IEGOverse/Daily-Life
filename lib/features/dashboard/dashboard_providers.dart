import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../schedule/data/schedule_repository.dart';
import '../study/study_providers.dart';
import '../nutrition/nutrition_providers.dart' show dailyNutritionProvider;
import 'data/dashboard_repository.dart';
import 'domain/dashboard_summary.dart';

/// A lightweight clock provider so tests can control "now".
/// Override with `clockProvider.overrideWithValue(DateTime(...))`.
final clockProvider = Provider<DateTime>((ref) => DateTime.now());

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(databaseProvider));
});

/// Future of the Today dashboard summary for the current local day.
///
/// Override in tests with a fixed summary, or invalidate it to force a reload.
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final now = ref.read(clockProvider);
  // Materialize the recurring week (idempotent) so "today" always reflects
  // the approved schedule, even on a week boundary.
  await ensureCurrentWeekActivities(ref.read(databaseProvider), now, now);
  return ref.read(dashboardRepositoryProvider).buildSummaryForDay(now);
});

/// Today's total study minutes derived from study sessions.
///
/// Watches the authoritative [studySessionsProvider] so any insert/update/
/// delete of a study session (all of which invalidate it) automatically
/// refreshes the dashboard study summary. No second source of truth.
final todayStudyMinutesProvider = FutureProvider<int>((ref) async {
  final now = ref.watch(clockProvider);
  final day = DateTime(now.year, now.month, now.day);
  final nextDay = day.add(const Duration(days: 1));
  final sessions = await ref.watch(studySessionsProvider.future);
  var total = 0;
  for (final s in sessions) {
    if (!s.date.isBefore(day) && s.date.isBefore(nextDay)) {
      total += (s.durationSeconds ?? 0);
    }
  }
  return (total / 60).round();
});

/// Today's nutrition summary for compact dashboard display.
final todayNutritionSummaryProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final now = ref.watch(clockProvider);
  final day = DateTime(now.year, now.month, now.day);
  return ref.watch(dailyNutritionProvider(day).future);
});
