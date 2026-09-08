import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'domain/transaction.dart';
import 'finance_repository.dart';

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(databaseProvider)),
);

final allTransactionsProvider = FutureProvider<List<Transaction>>((ref) {
  return ref.watch(financeRepositoryProvider).getAll();
});

final financeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(financeRepositoryProvider).getStatistics();
});
