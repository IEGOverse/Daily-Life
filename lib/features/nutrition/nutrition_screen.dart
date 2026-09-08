import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/food.dart';
import 'domain/meal.dart';
import 'domain/meal_food.dart';
import 'nutrition_providers.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final summary = ref.watch(dailyNutritionProvider(day));

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddMealDialog(context, ref, day),
        icon: const Icon(Icons.add),
        label: const Text('Add meal'),
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Failed to load nutrition.')),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            _NutritionSummary(summary: s),
            const SizedBox(height: 16),
            Text('Meals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if ((s['meals'] as List).isEmpty)
              const Center(child: Text('No meals recorded today yet.'))
            else
              for (final mealEntry in s['meals'] as List)
                _MealCard(
                  mealEntry: mealEntry,
                  onDelete: () async {
                    final repo = ref.read(nutritionRepositoryProvider);
                    final meal = mealEntry['meal'] as Meal;
                    await repo.deleteMeal(meal.id);
                    ref.invalidate(dailyNutritionProvider(day));
                  },
                ),
            const SizedBox(height: 16),
            Text(
              'Nutrition values are estimates, not medical-grade measurements.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddMealDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
  ) async {
    final repo = ref.read(nutritionRepositoryProvider);
    final foods = await ref.read(foodsProvider.future);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _AddMealDialog(
        foods: foods,
        day: day,
        onSave: (meal) async {
          // Meal with no foods is invalid; return early.
          if (meal.items.isEmpty) {
            Navigator.of(context).pop();
            return;
          }
          await repo.insertMeal(meal.meal);
          for (final item in meal.items) {
            await repo.addMealFood(item);
          }
          ref.invalidate(dailyNutritionProvider(day));
          ref.invalidate(foodsProvider);
        },
      ),
    );
  }
}

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final calories = (summary['calories'] as num).toDouble().round();
    final protein = (summary['protein'] as num).toDouble().round();
    final carbs = (summary['carbohydrate'] as num).toDouble().round();
    final fat = (summary['fat'] as num).toDouble().round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Calories',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 4),
            Text(
              '$calories kcal',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Macro(label: 'Protein', value: '$protein g'),
                _Macro(label: 'Carbs', value: '$carbs g'),
                _Macro(label: 'Fat', value: '$fat g'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.mealEntry, required this.onDelete});

  final Map<String, dynamic> mealEntry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final meal = mealEntry['meal'] as Meal;
    final calories = (mealEntry['calories'] as num).toDouble().round();
    final entries = mealEntry['entries'] as List;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.mealType,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entries.isEmpty
                        ? 'No foods'
                        : entries
                              .map(
                                (e) =>
                                    '${(e['food'] as Food).name} (${(e['quantity'] as num)} ${e['unit']})',
                              )
                              .join(', '),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$calories kcal',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMealDialog extends StatefulWidget {
  const _AddMealDialog({
    required this.foods,
    required this.day,
    required this.onSave,
  });

  final List<Food> foods;
  final DateTime day;
  final Future<void> Function(_DraftMeal meal) onSave;

  @override
  State<_AddMealDialog> createState() => _AddMealDialogState();
}

class _DraftMeal {
  _DraftMeal({required this.meal, required this.items});
  final Meal meal;
  final List<MealFood> items;
}

class _AddMealDialogState extends State<_AddMealDialog> {
  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  String _mealType = 'Breakfast';
  final List<({Food food, double quantity})> _selected = [];
  Food? _food;
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _addSelected() {
    final food = _food;
    final quantity = double.tryParse(_quantityController.text.trim());
    if (food == null || quantity == null || quantity <= 0) return;
    setState(() => _selected.add((food: food, quantity: quantity)));
    _quantityController.text = '1';
  }

  Future<void> _submit() async {
    final now = DateTime.now();
    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mealType: _mealType,
      date: widget.day,
      time: now,
      notes: null,
    );
    final items = <MealFood>[];
    for (var i = 0; i < _selected.length; i++) {
      final entry = _selected[i];
      items.add(
        MealFood(
          id: '${meal.id}_$i',
          mealId: meal.id,
          foodId: entry.food.id,
          quantity: entry.quantity,
          unit: entry.food.servingUnit,
        ),
      );
    }
    await widget.onSave(_DraftMeal(meal: meal, items: items));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add meal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _mealType,
              decoration: const InputDecoration(
                labelText: 'Meal type',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final t in _mealTypes)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _mealType = value);
              },
            ),
            const SizedBox(height: 12),
            if (widget.foods.isEmpty)
              const Text('No foods in the database yet.')
            else ...[
              DropdownButtonFormField<Food>(
                initialValue: _food,
                decoration: const InputDecoration(
                  labelText: 'Food',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final f in widget.foods)
                    DropdownMenuItem(value: f, child: Text(f.name)),
                ],
                onChanged: (value) => setState(() => _food = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity (${_food?.servingUnit ?? ''})',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addSelected,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selected.isEmpty)
                const Text('No items added yet.')
              else
                for (final e in _selected)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.food.name),
                    trailing: Text('${e.quantity} ${e.food.servingUnit}'),
                  ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save meal')),
      ],
    );
  }
}
