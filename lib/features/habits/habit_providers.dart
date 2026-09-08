import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../dashboard/dashboard_providers.dart';
import 'data/habit_repository.dart';
import 'domain/habit_with_status.dart';

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepository(ref.watch(databaseProvider)),
);

/// All habits with today's status and derived streaks.
final habitsWithStatusProvider = FutureProvider<List<HabitWithStatus>>((ref) {
  final now = ref.watch(clockProvider);
  return ref.watch(habitRepositoryProvider).habitsWithStatus(now);
});
