import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../dashboard/dashboard_providers.dart';
import 'data/insights_repository.dart';
import 'domain/daily_score.dart';
import 'domain/time_analytics.dart';
import 'domain/weekly_summary.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>(
  (ref) => InsightsRepository(ref.watch(databaseProvider)),
);

/// Local calendar day (midnight) for the given time.
DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The Monday that starts the current week.
DateTime _startOfWeek(DateTime now) {
  final day = _dayOnly(now);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// Today's daily productivity score.
final dailyScoreProvider = FutureProvider<DailyScore>((ref) {
  final now = ref.watch(clockProvider);
  return ref.watch(insightsRepositoryProvider).dailyScore(now);
});

/// Current week (Monday → next Monday) summary.
final weeklySummaryProvider = FutureProvider<WeeklySummary>((ref) {
  final now = ref.watch(clockProvider);
  final start = _startOfWeek(now);
  return ref
      .watch(insightsRepositoryProvider)
      .weeklySummary(start, start.add(const Duration(days: 7)));
});

/// Current week time distribution.
final weeklyTimeProvider = FutureProvider<TimeAnalytics>((ref) {
  final now = ref.watch(clockProvider);
  final start = _startOfWeek(now);
  return ref
      .watch(insightsRepositoryProvider)
      .timeAnalytics(start, start.add(const Duration(days: 7)));
});
