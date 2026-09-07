import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'workout_providers.dart';

class WorkoutPlanDetailScreen extends ConsumerWidget {
  final String planId;

  const WorkoutPlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(workoutPlanByIdProvider(planId));
    final links = ref.watch(workoutPlanExercisesProvider(planId));
    return Scaffold(
      appBar: AppBar(title: const Text('Workout plan')),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Failed to load plan.')),
        data: (value) {
          if (value == null) {
            return const Center(child: Text('Workout plan not found.'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                value.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (value.dayLabel != null) ...[
                const SizedBox(height: 4),
                Text(value.dayLabel!),
              ],
              if (value.description != null) ...[
                const SizedBox(height: 16),
                Text(value.description!),
              ],
              const SizedBox(height: 24),
              Text('Exercises', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              links.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const Text('Failed to load exercises.'),
                data: (items) => items.isEmpty
                    ? const Text('No exercises in this plan.')
                    : Column(
                        children: [
                          for (final item in items)
                            Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${item.sortOrder + 1}'),
                                ),
                                title: Text(
                                  item.exercise?.name ?? item.exerciseId,
                                ),
                                subtitle: Text(
                                  '${item.sets} sets x ${item.reps} reps'
                                  '${item.restSeconds == null ? '' : '  •  ${item.restSeconds}s rest'}',
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final session = await ref
                      .read(workoutSessionRepositoryProvider)
                      .start(workoutPlanId: value.id);
                  ref.invalidate(workoutSessionsProvider);
                  if (context.mounted) {
                    context.push('/workout/sessions/${session.id}');
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start workout'),
              ),
            ],
          );
        },
      ),
    );
  }
}
