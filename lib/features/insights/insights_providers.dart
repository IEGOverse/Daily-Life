import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../dashboard/dashboard_providers.dart';
import 'data/insights_repository.dart';
import 'domain/daily_score.dart';
import 'domain/insight_generator.dart';
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

/// Personal insights comparing this week with last week, generated locally.
final personalInsightsProvider = FutureProvider<List<PersonalInsight>>((ref) {
  final now = ref.watch(clockProvider);
  final repo = ref.watch(insightsRepositoryProvider);
  final currentStart = _startOfWeek(now);
  const generator = InsightGenerator();
  return (repo
      .weeklySummary(currentStart, currentStart.add(const Duration(days: 7)))
      .then((current) async {
        final previousStart = currentStart.subtract(const Duration(days: 7));
        final previous = await repo.weeklySummary(previousStart, currentStart);
        return generator.generate(current, previous);
      }));
});
