import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'workout_providers.dart';

class WorkoutSessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  const WorkoutSessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workoutSessionByIdProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Sesi Olahraga')),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Gagal memuat sesi.')),
        data: (value) {
          if (value == null) {
            return const Center(child: Text('Sesi olahraga tidak ditemukan.'));
          }
          final status = value.completed ? 'Selesai' : 'Berlangsung';
          final exercises = ref.watch(
            workoutPlanExercisesProvider(value.workoutPlanId),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                value.plan?.name ?? 'Sesi olahraga',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Chip(label: Text(status)),
              const SizedBox(height: 16),
              Text('Mulai: ${value.startTime}'),
              if (value.endTime != null) Text('Selesai: ${value.endTime}'),
              if (value.durationSeconds != null)
                Text('Durasi: ${value.durationSeconds} detik'),
              if (value.notes != null) ...[
                const SizedBox(height: 16),
                Text(value.notes!),
              ],
              const SizedBox(height: 24),
              Text(
                'Gerakan yang direncanakan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              exercises.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const Text('Gagal memuat gerakan yang direncanakan.'),
                data: (items) => items.isEmpty
                    ? const Text('Tidak ada gerakan dalam rencana ini.')
                    : Column(
                        children: [
                          for (final item in items)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                child: Text('${item.sortOrder + 1}'),
                              ),
                              title: Text(
                                item.exercise?.name ?? item.exerciseId,
                              ),
                              subtitle: Text(
                                '${item.sets} set x ${item.reps} repetisi',
                              ),
                            ),
                        ],
                      ),
              ),
              if (!value.completed) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/workout/sessions/${value.id}/sets'),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Catat Set'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(workoutSessionRepositoryProvider)
                        .complete(value.id);
                    ref.invalidate(workoutSessionByIdProvider(value.id));
                    ref.invalidate(workoutSessionsProvider);
                    ref.invalidate(workoutHistoryProvider);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Selesaikan Olahraga'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
