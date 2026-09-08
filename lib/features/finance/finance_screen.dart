import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'domain/transaction.dart';
import 'finance_providers.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  _TransactionFilter _filter = _TransactionFilter.all;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(financeStatsProvider);
    final transactions = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ActivusColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _openTransactionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(allTransactionsProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            stats.when(
              loading: () => const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const SizedBox.shrink(),
              data: (s) => _BalanceCard(stats: s),
            ),
            const SizedBox(height: 16),
            _SegmentFilter(
              transactionType: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 12),
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const Center(child: Text('Failed to load transactions.')),
              data: (items) {
                final visible = items
                    .where(
                      (t) => switch (_filter) {
                        _TransactionFilter.all => true,
                        _TransactionFilter.income => t.type == 'income',
                        _TransactionFilter.expense => t.type == 'expense',
                      },
                    )
                    .toList();
                if (visible.isEmpty) {
                  return const Center(child: Text('No transactions yet.'));
                }
                return Column(
                  children: [
                    for (final t in visible)
                      _TransactionRow(
                        transaction: t,
                        onEdit: () => _openTransactionDialog(context, ref, t),
                        onDelete: () => _deleteTransaction(context, ref, t),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTransactionDialog(
    BuildContext context,
    WidgetRef ref, [
    Transaction? existing,
  ]) async {
    final repo = ref.read(financeRepositoryProvider);
    await showDialog<void>(
      context: context,
      builder: (context) => _TransactionDialog(
        existing: existing,
        onSave: (tx) async {
          if (existing == null) {
            await repo.insert(tx);
          } else {
            await repo.update(tx);
          }
          ref.invalidate(allTransactionsProvider);
          ref.invalidate(financeStatsProvider);
        },
      ),
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    await ref.read(financeRepositoryProvider).delete(transaction.id);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(financeStatsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Transaction deleted')));
    }
  }
}

enum _TransactionFilter { all, income, expense }

class _SegmentFilter extends StatelessWidget {
  final _TransactionFilter transactionType;
  final ValueChanged<_TransactionFilter> onChanged;

  const _SegmentFilter({
    required this.transactionType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('finance-filter'),
      children: [
        _SegmentButton(
          label: 'All',
          isActive: transactionType == _TransactionFilter.all,
          onTap: () => onChanged(_TransactionFilter.all),
        ),
        const SizedBox(width: 8),
        _SegmentButton(
          label: 'Income',
          isActive: transactionType == _TransactionFilter.income,
          onTap: () => onChanged(_TransactionFilter.income),
        ),
        const SizedBox(width: 8),
        _SegmentButton(
          label: 'Expense',
          isActive: transactionType == _TransactionFilter.expense,
          onTap: () => onChanged(_TransactionFilter.expense),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? ActivusColors.primaryBlue
                : ActivusColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? ActivusColors.primaryBlue
                  : ActivusColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.white : ActivusColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final balance = (stats['balance'] as num).toInt();
    final income = (stats['totalIncome'] as num).toInt();
    final expense = (stats['totalExpense'] as num).toInt();
    final balanceColor = balance < 0
        ? ActivusColors.danger
        : ActivusColors.success;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(fontSize: 13, color: ActivusColors.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            _formatAmount(balance),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: balanceColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _IncomeExpenseRow(
                label: 'Income',
                amount: income,
                color: ActivusColors.success,
                icon: Icons.arrow_downward,
              ),
              const SizedBox(width: 12),
              _IncomeExpenseRow(
                label: 'Expense',
                amount: expense,
                color: ActivusColors.danger,
                icon: Icons.arrow_upward,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  const _IncomeExpenseRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatAmount(amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ActivusColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? ActivusColors.success : ActivusColors.danger;
    final sign = isIncome ? '+' : '-';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CategoryIconContainer(
            icon: isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description?.isNotEmpty == true
                      ? transaction.description!
                      : transaction.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ActivusColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign ${_formatAmount(transaction.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({this.existing, required this.onSave});

  final Transaction? existing;
  final Future<void> Function(Transaction tx) onSave;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  static const _incomeCategories = [
    'Salary',
    'Allowance',
    'Bonus',
    'Investment',
    'Other Income',
  ];
  static const _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Other Expense',
  ];

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _type;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? 'expense';
    _category =
        existing?.category ??
        (_type == 'income'
            ? _incomeCategories.first
            : _expenseCategories.first);
    _date = existing?.date ?? DateTime.now();
    if (existing != null) {
      _amountController.text = existing.amount.toString();
      _descriptionController.text = existing.description ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _type == 'income' ? _incomeCategories : _expenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final tx = Transaction(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      category: _category,
      amount: amount,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _date,
    );
    await widget.onSave(tx);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add transaction' : 'Edit transaction',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  _category = _type == 'income'
                      ? _incomeCategories.first
                      : _expenseCategories.first;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (Rp)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(_formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

String _formatAmount(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final rem = s.length - i - 1;
    if (rem > 0 && rem % 3 == 0) buf.write('.');
  }
  return 'Rp $buf';
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
