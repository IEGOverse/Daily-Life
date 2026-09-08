import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/core/router/app_router.dart';
import 'package:daily_life/features/finance/domain/transaction.dart';
import 'package:daily_life/features/finance/finance_repository.dart';
import 'package:daily_life/main.dart';

void main() {
  group('FinanceRepository', () {
    test('inserts and reads back a transaction', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = FinanceRepository(database);

      final tx = Transaction(
        id: 't1',
        type: 'expense',
        category: 'Food',
        amount: 25000,
        description: 'Lunch',
        date: DateTime(2026, 9, 8),
      );
      await repository.insert(tx);

      final found = await repository.byId('t1');
      expect(found?.category, 'Food');
      expect(found?.amount, 25000);
      expect(found?.type, 'expense');
      expect(await repository.getAll(), hasLength(1));
    });

    test('updates an existing transaction preserving the id', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = FinanceRepository(database);

      await repository.insert(
        Transaction(
          id: 't1',
          type: 'expense',
          category: 'Food',
          amount: 25000,
          description: 'Lunch',
          date: DateTime(2026, 9, 8),
        ),
      );

      await repository.update(
        Transaction(
          id: 't1',
          type: 'expense',
          category: 'Transport',
          amount: 15000,
          description: 'Bus',
          date: DateTime(2026, 9, 8),
        ),
      );

      final found = await repository.byId('t1');
      expect(found?.category, 'Transport');
      expect(found?.amount, 15000);
      expect(await repository.getAll(), hasLength(1));
    });

    test('deletes a transaction', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = FinanceRepository(database);

      await repository.insert(
        Transaction(
          id: 't1',
          type: 'income',
          category: 'Salary',
          amount: 5000000,
          date: DateTime(2026, 9, 1),
        ),
      );
      await repository.delete('t1');

      expect(await repository.byId('t1'), isNull);
      expect(await repository.getAll(), isEmpty);
    });

    test('derived balance, income and expense totals', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = FinanceRepository(database);

      await repository.insert(
        Transaction(
          id: 'in1',
          type: 'income',
          category: 'Salary',
          amount: 5000000,
          date: DateTime(2026, 9, 1),
        ),
      );
      await repository.insert(
        Transaction(
          id: 'ex1',
          type: 'expense',
          category: 'Food',
          amount: 1500000,
          date: DateTime(2026, 9, 2),
        ),
      );

      final stats = await repository.getStatistics();
      expect(stats['totalIncome'], 5000000);
      expect(stats['totalExpense'], 1500000);
      expect(stats['balance'], 3500000);
      expect(stats['transactionCount'], 2);
    });

    test('balance updates when a transaction is added', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = FinanceRepository(database);

      await repository.insert(
        Transaction(
          id: 'in1',
          type: 'income',
          category: 'Salary',
          amount: 5000000,
          date: DateTime(2026, 9, 1),
        ),
      );
      expect((await repository.getStatistics())['balance'], 5000000);

      await repository.insert(
        Transaction(
          id: 'ex1',
          type: 'expense',
          category: 'Food',
          amount: 1500000,
          date: DateTime(2026, 9, 2),
        ),
      );
      expect((await repository.getStatistics())['balance'], 3500000);
      expect((await repository.getStatistics())['expenseCount'], 1);
    });

    test('empty database has zero balance and totals', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = FinanceRepository(database);

      final stats = await repository.getStatistics();
      expect(stats['balance'], 0);
      expect(stats['totalIncome'], 0);
      expect(stats['totalExpense'], 0);
      expect(await repository.getAll(), isEmpty);
    });
  });

  group('Finance screen flow', () {
    testWidgets('renders empty state', (tester) async {
      final container = ProviderContainer(
        overrides: [inMemoryDatabaseOverride()],
      );
      addTearDown(container.dispose);
      final database = container.read(databaseProvider);
      addTearDown(database.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DailyLifeApp(),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go('/finance');
      await tester.pumpAndSettle();

      expect(find.text('Keuangan'), findsOneWidget);
      expect(find.text('Belum ada transaksi.'), findsOneWidget);
    });

    testWidgets('segment filter narrows the transaction list', (tester) async {
      final container = ProviderContainer(
        overrides: [inMemoryDatabaseOverride()],
      );
      addTearDown(container.dispose);
      final database = container.read(databaseProvider);
      addTearDown(database.close);

      await database.insertTransaction(
        db.Transaction(
          id: 'inc',
          type: 'income',
          category: 'salary',
          amount: 100,
          date: DateTime(2026, 9, 8),
          createdAt: DateTime.now(),
        ),
      );
      await database.insertTransaction(
        db.Transaction(
          id: 'exp',
          type: 'expense',
          category: 'food',
          amount: 50,
          date: DateTime(2026, 9, 8),
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DailyLifeApp(),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go('/finance');
      await tester.pumpAndSettle();

      // All: both categories are listed.
      expect(find.text('salary'), findsOneWidget);
      expect(find.text('food'), findsOneWidget);

      // Income: only the income row remains.
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('finance-filter')),
          matching: find.text('Pemasukan'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('salary'), findsOneWidget);
      expect(find.text('food'), findsNothing);

      // Expense: only the expense row remains.
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('finance-filter')),
          matching: find.text('Pengeluaran'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('food'), findsOneWidget);
      expect(find.text('salary'), findsNothing);

      // Back to All restores both rows.
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('finance-filter')),
          matching: find.text('Semua'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('salary'), findsOneWidget);
      expect(find.text('food'), findsOneWidget);
    });
  });
}
