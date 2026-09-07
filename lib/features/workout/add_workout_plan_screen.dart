import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/exercise.dart';
import 'domain/workout_plan.dart';
import 'workout_providers.dart';

class AddWorkoutPlanScreen extends ConsumerStatefulWidget {
  const AddWorkoutPlanScreen({super.key});

  @override
  ConsumerState<AddWorkoutPlanScreen> createState() =>
      _AddWorkoutPlanScreenState();
}

class _AddWorkoutPlanScreenState extends ConsumerState<AddWorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dayController = TextEditingController();
  final Map<String, WorkoutPlanDraftExercise> _selected = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selected.isEmpty) {
      if (_selected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one exercise.')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    final planId = 'plan_${DateTime.now().microsecondsSinceEpoch}';
    final plan = WorkoutPlan(
      id: planId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dayLabel: _dayController.text.trim().isEmpty
          ? null
          : _dayController.text.trim(),
    );
    try {
      await ref
          .read(workoutPlanRepositoryProvider)
          .insert(plan: plan, exercises: _selected.values.toList());
      ref.invalidate(workoutPlansProvider);
      ref.invalidate(workoutPlanByIdProvider);
      ref.invalidate(workoutPlanExercisesProvider);
      if (mounted) {
        context.pop();
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save workout plan.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('New workout plan')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save plan'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          key: const ValueKey('workout-plan-form'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Plan name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a plan name.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dayController,
              decoration: const InputDecoration(
                labelText: 'Day label (optional)',
                hintText: 'e.g. Monday or Push day',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Exercises', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'New exercises use 3 sets, 10 reps, and 60 seconds rest.',
            ),
            const SizedBox(height: 8),
            exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Text('Failed to load exercises.'),
              data: (items) => Column(
                children: [
                  for (final exercise in items) _exerciseTile(exercise),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseTile(Exercise exercise) {
    return CheckboxListTile(
      value: _selected.containsKey(exercise.id),
      title: Text(exercise.name),
      subtitle: Text(exercise.muscleGroupLabel),
      contentPadding: EdgeInsets.zero,
      onChanged: (selected) {
        setState(() {
          if (selected == true) {
            _selected[exercise.id] = WorkoutPlanDraftExercise(
              exercise: exercise,
            );
          } else {
            _selected.remove(exercise.id);
          }
        });
      },
    );
  }
}
