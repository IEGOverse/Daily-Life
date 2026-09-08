import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddHabitDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add habit'),
      ),
      body: statuses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Failed to load habits.')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No habits yet.'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _HabitTile(
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
          .showSnackBar(SnackBar(content: Text('${habit.name} deleted')));
    }
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
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
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        value: completedToday,
        onChanged: (_) => onToggle(),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: primary,
        title: Text(
          habit.name,
          style: TextStyle(
            decoration: completedToday ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${habit.frequency} · target ${habit.target} · '
          '🔥 ${item.currentStreak} day streak',
        ),
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a habit name')));
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
      title: const Text('Add habit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final f in _frequencies)
                  DropdownMenuItem(value: f, child: Text(f)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _frequency = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Daily target')),
                DropdownButtonFormField<int>(
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
              ],
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
