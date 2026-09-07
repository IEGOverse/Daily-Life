import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'workout_providers.dart';

/// Exercise detail with description and instructions (PRD §7).
class WorkoutExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;

  const WorkoutExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: exerciseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('Failed to load exercise.')),
        data: (exercise) {
          if (exercise == null) {
            return const Center(child: Text('Exercise not found.'));
          }
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  Icons.fitness_center,
                  size: 32,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                exercise.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                exercise.muscleGroupLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              if (exercise.description != null) ...[
                const SizedBox(height: 20),
                _Section(
                  title: 'Description',
                  child: Text(exercise.description!),
                ),
              ],
              if (exercise.instructions != null) ...[
                const SizedBox(height: 20),
                _Section(
                  title: 'Instructions',
                  child: Text(exercise.instructions!),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      ],
    );
  }
}
