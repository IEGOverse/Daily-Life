import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../dashboard/dashboard_providers.dart' show clockProvider;
import '../schedule/data/schedule_repository.dart';
import 'data/activity_repository.dart';
import 'domain/activity.dart';

/// Single source for the [ActivityRepository].
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(databaseProvider));
});

/// Activities for the given local day. Keyed by the day's date string so that
/// different days are cached separately.
///
/// If [day] is in the current week, the recurring schedule's activities for
/// that week are materialized first (idempotently), so a fresh launch or a
/// week boundary doesn't leave today/calendar empty.
final activitiesForDayProvider =
    FutureProvider.family<List<Activity>, DateTime>((ref, day) async {
      final database = ref.read(databaseProvider);
      final now = ref.read(clockProvider);
      await ensureCurrentWeekActivities(database, now, day);
      return ref.watch(activityRepositoryProvider).getForDay(day);
    });

/// Activity count per day-of-month for a given [month].
final activitiesForMonthProvider =
    FutureProvider.family<Map<int, int>, DateTime>((ref, month) async {
      final database = ref.read(databaseProvider);
      final now = ref.read(clockProvider);
      // When browsing the current month, materialize the current week so the
      // recurring schedule appears on the grid (and week-boundary browsing
      // isn't empty).
      if (now.year == month.year && now.month == month.month) {
        await ensureCurrentWeekActivities(database, now, now);
      }
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);
      final activities = await ref
          .read(activityRepositoryProvider)
          .getForRange(start, end);
      final counts = <int, int>{};
      for (final activity in activities) {
        final day = activity.startTime.day;
        counts[day] = (counts[day] ?? 0) + 1;
      }
      return counts;
    });
