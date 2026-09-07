import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
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
  final repository = ref.watch(dashboardRepositoryProvider);
  final now = ref.watch(clockProvider);
  return repository.buildSummaryForDay(now);
});
