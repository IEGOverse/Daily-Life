import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/workout_set_log.dart';
import 'workout_providers.dart';

class WorkoutSetLoggingScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const WorkoutSetLoggingScreen({super.key, required this.sessionId});

  @override
  ConsumerState<WorkoutSetLoggingScreen> createState() =>
      _WorkoutSetLoggingScreenState();
}

class _WorkoutSetLoggingScreenState
    extends ConsumerState<WorkoutSetLoggingScreen> {
  final Map<String, _SetDraft> _drafts = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(workoutSetLogsProvider(widget.sessionId));
    final session = ref.watch(workoutSessionByIdProvider(widget.sessionId));
    final planId = session.valueOrNull?.workoutPlanId;
    final planned = planId == null
        ? const AsyncValue.data([])
        : ref.watch(workoutPlanExercisesProvider(planId));
    final names = {
      for (final item in planned.valueOrNull ?? [])
        item.exerciseId: item.exercise?.name ?? item.exerciseId,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Set')),
      body: logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Gagal memuat catatan set.')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Tidak ada set untuk sesi ini.'));
          }
          for (final log in items) {
            _drafts.putIfAbsent(log.id, () => _SetDraft.fromLog(log));
          }
          final groups = <String, List<WorkoutSetLog>>{};
          for (final log in items) {
            groups.putIfAbsent(log.exerciseId, () => []).add(log);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final entry in groups.entries) ...[
                Text(
                  names[entry.key] ?? entry.key,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final log in entry.value) _setCard(log),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : () => _save(logs.valueOrNull ?? const []),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan Catatan Set'),
        ),
      ),
    );
  }

  Widget _setCard(WorkoutSetLog log) {
    final draft = _drafts[log.id]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: draft.completed,
              onChanged: (value) =>
                  setState(() => draft.completed = value ?? false),
            ),
            Text('Set ${log.setNumber}'),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: '${draft.reps}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Repetisi',
                  isDense: true,
                ),
                onChanged: (value) => draft.reps = int.tryParse(value) ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: draft.weight?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Beban',
                  suffixText: 'kg',
                  isDense: true,
                ),
                onChanged: (value) =>
                    draft.weight = double.tryParse(value.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(List<WorkoutSetLog> logs) async {
    setState(() => _saving = true);
    try {
      final repository = ref.read(workoutSetLogRepositoryProvider);
      for (final log in logs) {
        final draft = _drafts[log.id]!;
        await repository.update(
          WorkoutSetLog(
            id: log.id,
            workoutSessionId: log.workoutSessionId,
            exerciseId: log.exerciseId,
            setNumber: log.setNumber,
            reps: draft.reps,
            weight: draft.weight,
            completed: draft.completed,
          ),
        );
      }
      ref.invalidate(workoutSetLogsProvider(widget.sessionId));
      ref.invalidate(workoutHistoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Catatan set tersimpan')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SetDraft {
  int reps;
  double? weight;
  bool completed;

  _SetDraft({required this.reps, this.weight, required this.completed});

  factory _SetDraft.fromLog(WorkoutSetLog log) =>
      _SetDraft(reps: log.reps, weight: log.weight, completed: log.completed);
}
