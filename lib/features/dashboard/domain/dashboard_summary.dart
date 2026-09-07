import '../../activities/domain/activity.dart';
import '../../activities/domain/activity_status.dart';

/// Finance totals derived from a day's transactions.
class FinanceSummary {
  final int income;
  final int expense;

  const FinanceSummary({this.income = 0, this.expense = 0});

  int get balance => income - expense;

  static const FinanceSummary empty = FinanceSummary();

  FinanceSummary combine(FinanceSummary other) {
    return FinanceSummary(
      income: income + other.income,
      expense: expense + other.expense,
    );
  }
}

/// Aggregated view of a single day for the Today dashboard.
class DashboardSummary {
  final DateTime day;
  final List<Activity> activities;
  final FinanceSummary finance;

  const DashboardSummary({
    required this.day,
    required this.activities,
    this.finance = FinanceSummary.empty,
  });

  int get totalActivities => activities.length;

  int get completedActivities =>
      activities.where((a) => a.status == ActivityStatus.completed).length;

  /// Fraction of activities completed (0.0 when nothing is planned).
  double get progress {
    if (activities.isEmpty) {
      return 0.0;
    }
    return completedActivities / activities.length;
  }

  /// The activity happening right now at [now], if any.
  Activity? currentActivityAt(DateTime now) {
    for (final activity in activities) {
      if (activity.isCurrentAt(now)) {
        return activity;
      }
    }
    return null;
  }

  /// The next activity that starts strictly after [now], if any.
  Activity? nextActivityAfter(DateTime now) {
    final upcoming = activities.where((a) => a.isUpcomingAfter(now)).toList()
      ..sort(compareByStart);
    return upcoming.isEmpty ? null : upcoming.first;
  }
}
