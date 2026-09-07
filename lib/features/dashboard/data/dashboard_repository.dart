import '../../../core/database/database.dart' as db;
import '../../activities/domain/activity.dart';
import '../domain/dashboard_summary.dart';

/// Loads and aggregates the data needed by the Today dashboard.
class DashboardRepository {
  final db.AppDatabase _database;

  DashboardRepository(this._database);

  /// Builds the dashboard summary for the local day [day].
  ///
  /// Activities are all planned for that day (any status). Finance totals are
  /// derived from the day's transactions, never stored.
  Future<DashboardSummary> buildSummaryForDay(DateTime day) async {
    final rows = await _database.getActivitiesForDay(day);
    final transactions = await _database.getTransactionsForDay(day);

    final activities = rows.map(Activity.fromRow).toList();
    activities.sort(compareByStart);

    var finance = FinanceSummary.empty;
    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        finance = FinanceSummary(
          income: finance.income + transaction.amount,
          expense: finance.expense,
        );
      } else {
        finance = FinanceSummary(
          income: finance.income,
          expense: finance.expense + transaction.amount,
        );
      }
    }

    return DashboardSummary(day: day, activities: activities, finance: finance);
  }
}
