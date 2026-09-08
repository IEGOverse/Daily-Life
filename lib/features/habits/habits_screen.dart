import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../dashboard/dashboard_providers.dart';
import 'domain/habit.dart';
import 'domain/habit_with_status.dart';
import 'habit_providers.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(habitsWithStatusProvider);
    final now = ref.watch(clockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kebiasaan')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ActivusColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _openAddHabitDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kebiasaan'),
      ),
      body: statuses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Gagal memuat kebiasaan.')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Belum ada kebiasaan.'),
                    SizedBox(height: 8),
                    Text(
                      'Tambahkan kebiasaan pertama untuk mulai membangun konsistensi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ActivusColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _HabitRow(
                    item: item,
                    onToggle: () => _toggle(context, ref, item.habit, now),
                    onDelete: () => _delete(context, ref, item.habit),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _openAddHabitDialog(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(habitRepositoryProvider);
    await showDialog<void>(
      context: context,
      builder: (context) => _AddHabitDialog(
        onSave: (habit) async {
          await repo.insertHabit(habit);
          ref.invalidate(habitsWithStatusProvider);
        },
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    DateTime day,
  ) async {
    final repo = ref.read(habitRepositoryProvider);
    final current = ref.read(habitsWithStatusProvider).value;
    final status =
        current?.where((s) => s.habit.id == habit.id).toList().isNotEmpty ==
            true
        ? current!.firstWhere((s) => s.habit.id == habit.id)
        : null;
    final completedToday = status?.completedToday ?? false;
    await repo.setCompleted(habit.id, day, !completedToday);
    ref.invalidate(habitsWithStatusProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Habit habit) async {
    await ref.read(habitRepositoryProvider).deleteHabit(habit.id);
    ref.invalidate(habitsWithStatusProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${habit.name} dihapus')));
    }
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final HabitWithStatus item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final habit = item.habit;
    final completedToday = item.completedToday;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    (completedToday
                            ? ActivusColors.success
                            : ActivusColors.primaryBlue)
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                completedToday ? Icons.check : Icons.repeat,
                size: 20,
                color: completedToday
                    ? ActivusColors.success
                    : ActivusColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: completedToday
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_frequencyLabel(habit.frequency)} · target ${habit.target}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ActivusColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '🔥 ${item.currentStreak}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'hari',
                style: TextStyle(
                  fontSize: 10,
                  color: ActivusColors.textTertiary,
                ),
              ),
            ],
          ),
          StatusPill(
            label: completedToday ? 'Selesai' : 'Hari Ini',
            color: completedToday
                ? ActivusColors.success
                : ActivusColors.textTertiary,
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

class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog({required this.onSave});

  final Future<void> Function(Habit habit) onSave;

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  static const _frequencies = ['daily', 'weekly'];
  final _nameController = TextEditingController();
  late String _frequency;
  late int _target;

  @override
  void initState() {
    super.initState();
    _frequency = 'daily';
    _target = 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan nama kebiasaan')));
      return;
    }
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      frequency: _frequency,
      target: _target,
      createdAt: DateTime.now(),
    );
    await widget.onSave(habit);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Kebiasaan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frekuensi',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final f in _frequencies)
                  DropdownMenuItem(value: f, child: Text(_frequencyLabel(f))),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _frequency = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Target harian')),
                SizedBox(
                  width: 104,
                  child: DropdownButtonFormField<int>(
                    initialValue: _target,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (var i = 1; i <= 5; i++)
                        DropdownMenuItem(value: i, child: Text('$i')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _target = value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}

String _frequencyLabel(String frequency) =>
    frequency == 'daily' ? 'harian' : 'mingguan';
