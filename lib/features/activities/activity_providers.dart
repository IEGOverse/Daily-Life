import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'data/activity_repository.dart';
import 'domain/activity.dart';

/// Single source for the [ActivityRepository].
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(databaseProvider));
});

/// Activities for the given local day. Keyed by the day's date string so that
/// different days are cached separately.
final activitiesForDayProvider =
    FutureProvider.family<List<Activity>, DateTime>((ref, day) async {
      return ref.watch(activityRepositoryProvider).getForDay(day);
    });
