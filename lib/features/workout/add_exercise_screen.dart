import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/exercise.dart';
import 'workout_providers.dart';

/// Form to add a personal exercise to the workout library.
class AddExerciseScreen extends ConsumerStatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  String? _muscleGroup;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final micros = (DateTime.now().microsecondsSinceEpoch % 1000000000)
        .toString();
    final slug = _nameController.text.trim().toLowerCase().replaceAll(' ', '_');
    final exercise = Exercise(
      id: 'exercise_${micros}_$slug',
      name: _nameController.text.trim(),
      muscleGroup: _muscleGroup!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
    );
    try {
      await ref.read(exerciseRepositoryProvider).insert(exercise);
      ref.invalidate(exercisesProvider);
      ref.invalidate(exerciseByIdProvider);
      if (mounted) {
        setState(() => _saving = false);
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Gerakan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Masukkan nama gerakan.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _muscleGroup,
              decoration: const InputDecoration(
                labelText: 'Kelompok otot',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final group in exerciseMuscleGroups)
                  DropdownMenuItem(
                    value: group,
                    child: Text(muscleGroupLabelFor(group)),
                  ),
              ],
              onChanged: (value) => setState(() => _muscleGroup = value),
              validator: (value) =>
                  value == null ? 'Pilih kelompok otot.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionsController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Instruksi (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Gerakan'),
            ),
          ],
        ),
      ),
    );
  }
}
