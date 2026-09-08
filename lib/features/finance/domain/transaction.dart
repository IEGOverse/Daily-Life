import '../../../core/database/database.dart' as db;

/// Domain model for a Finance Transaction.
///
/// This is the pure Dart model used throughout the Finance feature.
/// It does NOT contain any repository or database logic.
/// Balance is always DERIVED: SUM(income) - SUM(expense).
/// No authoritative balance field is stored.
class Transaction {
  final String id;
  final String type; // 'income' or 'expense'
  final String category;
  final int amount;
  final String? description;
  final DateTime date;

  const Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.description,
    required this.date,
  });

  /// Create a domain [Transaction] from a Drift [`db.Transaction`] row.
  factory Transaction.fromRow(db.Transaction row) => Transaction(
    id: row.id,
    type: row.type,
    category: row.category,
    amount: row.amount,
    description: row.description,
    date: row.date,
  );
}
