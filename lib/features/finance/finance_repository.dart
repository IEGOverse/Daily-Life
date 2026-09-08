import 'package:drift/drift.dart';
import 'package:daily_life/core/database/database.dart' as db;

import 'domain/transaction.dart';

/// Repository for Finance transactions.
///
/// Maps between the domain [Transaction] model and the Drift
/// [`db.Transaction`] row. Balance is always DERIVED via
/// `SUM(income) - SUM(expense)`; no authoritative balance is stored.
class FinanceRepository {
  final db.AppDatabase _database;

  FinanceRepository(this._database);

  Future<List<Transaction>> getAll() async =>
      (await _database.getAllTransactions()).map(Transaction.fromRow).toList();

  Future<Transaction?> byId(String id) async {
    final row = await _database.getTransactionById(id);
    return row == null ? null : Transaction.fromRow(row);
  }

  Future<void> insert(Transaction transaction) => _database.insertTransaction(
    db.Transaction(
      id: transaction.id,
      type: transaction.type,
      category: transaction.category,
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.date,
      createdAt: transaction.date,
    ),
  );

  Future<void> update(Transaction transaction) async {
    await _database.updateTransaction(
      transaction.id,
      db.TransactionsCompanion(
        type: Value(transaction.type),
        category: Value(transaction.category),
        amount: Value(transaction.amount),
        description: Value(transaction.description),
        date: Value(transaction.date),
      ),
    );
  }

  Future<void> delete(String id) => _database.deleteTransaction(id);

  /// Derived finance statistics.
  ///
  /// Balance is computed as `SUM(income) - SUM(expense)` and is never stored.
  Future<Map<String, dynamic>> getStatistics() async {
    final transactions = await getAll();
    final income = transactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final balance = income - expense;

    return {
      'totalIncome': income,
      'totalExpense': expense,
      'balance': balance,
      'transactionCount': transactions.length,
      'incomeCount': transactions.where((t) => t.type == 'income').length,
      'expenseCount': transactions.where((t) => t.type == 'expense').length,
    };
  }
}
