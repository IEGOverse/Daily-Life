import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/exercise.dart';
import 'workout_providers.dart';

/// Workout exercise library (PRD §7). Browse by muscle group, search, and open
/// exercise details with instructions.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  String? _selectedGroup;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        actions: [
          IconButton(
            tooltip: 'Add exercise',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/workout/add'),
          ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load exercises.')),
        data: (exercises) {
          return _ExerciseLibrary(
            exercises: exercises,
            selectedGroup: _selectedGroup,
            searchController: _searchController,
            onGroupChanged: (group) => setState(() => _selectedGroup = group),
            onSearchChanged: (_) => setState(() {}),
          );
        },
      ),
    );
  }
}

class _ExerciseLibrary extends StatelessWidget {
  final List<Exercise> exercises;
  final String? selectedGroup;
  final TextEditingController searchController;
  final ValueChanged<String?> onGroupChanged;
  final ValueChanged<String> onSearchChanged;

  const _ExerciseLibrary({
    required this.exercises,
    required this.selectedGroup,
    required this.searchController,
    required this.onGroupChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final filtered = exercises.where((e) {
      final matchesGroup = selectedGroup == null || e.muscleGroup == selectedGroup;
      final matchesQuery = query.isEmpty || e.name.toLowerCase().contains(query);
      return matchesGroup && matchesQuery;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search exercises',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _GroupChip(
                label: 'All',
                selected: selectedGroup == null,
                onTap: () => onGroupChanged(null),
              ),
              for (final group in exerciseMuscleGroups)
                _GroupChip(
                  label: _labelFor(group),
                  selected: selectedGroup == group,
                  onTap: () => onGroupChanged(group),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    exercises.isEmpty ? 'Your library is empty.' : 'No exercises match.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final exercise = filtered[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(exercise.name),
                        subtitle: Text(exercise.muscleGroupLabel),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/workout/exercise/${exercise.id}',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static String _labelFor(String group) =>
      group[0].toUpperCase() + group.substring(1);
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GroupChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}