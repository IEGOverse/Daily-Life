import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'workout_providers.dart';

class WorkoutPlansScreen extends ConsumerWidget {
  const WorkoutPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(workoutPlansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Workout plans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workout/plans/add'),
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
      ),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Failed to load workout plans.')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No workout plans yet. Create one to get started.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final plan = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.view_list_outlined),
                  ),
                  title: Text(plan.name),
                  subtitle: Text(plan.dayLabel ?? 'Flexible schedule'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/workout/plans/${plan.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
