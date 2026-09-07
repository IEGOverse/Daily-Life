import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'workout_providers.dart';

class WorkoutSessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  const WorkoutSessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workoutSessionByIdProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Workout session')),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Failed to load session.')),
        data: (value) {
          if (value == null) {
            return const Center(child: Text('Workout session not found.'));
          }
          final status = value.completed ? 'Completed' : 'In progress';
          final exercises = ref.watch(
            workoutPlanExercisesProvider(value.workoutPlanId),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                value.plan?.name ?? 'Workout session',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Chip(label: Text(status)),
              const SizedBox(height: 16),
              Text('Started: ${value.startTime}'),
              if (value.endTime != null) Text('Ended: ${value.endTime}'),
              if (value.durationSeconds != null)
                Text('Duration: ${value.durationSeconds} seconds'),
              if (value.notes != null) ...[
                const SizedBox(height: 16),
                Text(value.notes!),
              ],
              const SizedBox(height: 24),
              Text(
                'Planned exercises',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              exercises.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const Text('Failed to load planned exercises.'),
                data: (items) => items.isEmpty
                    ? const Text('No exercises in this plan.')
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
                                '${item.sets} sets x ${item.reps} reps',
                              ),
                            ),
                        ],
                      ),
              ),
              if (!value.completed) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(workoutSessionRepositoryProvider)
                        .complete(value.id);
                    ref.invalidate(workoutSessionByIdProvider(value.id));
                    ref.invalidate(workoutSessionsProvider);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Complete workout'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
