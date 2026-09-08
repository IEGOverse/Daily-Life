import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'domain/food.dart';
import 'domain/meal.dart';
import 'domain/meal_food.dart';
import 'domain/meal_suggestion.dart';
import 'nutrition_providers.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final summary = ref.watch(dailyNutritionProvider(day));
    final suggestions = ref.watch(mealSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ActivusColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _openAddMealDialog(context, ref, day),
        icon: const Icon(Icons.add),
        label: const Text('Add meal'),
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Failed to load nutrition.')),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _NutritionSummary(summary: s),
            const SizedBox(height: 20),
            _SectionLabel(label: 'Meals'),
            if ((s['meals'] as List).isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No meals recorded today yet.')),
              )
            else
              for (final mealEntry in s['meals'] as List)
                _MealRow(
                  mealEntry: mealEntry,
                  onDelete: () async {
                    final repo = ref.read(nutritionRepositoryProvider);
                    final meal = mealEntry['meal'] as Meal;
                    await repo.deleteMeal(meal.id);
                    ref.invalidate(dailyNutritionProvider(day));
                  },
                ),
            const SizedBox(height: 20),
            _MealSuggestionsCard(suggestions: suggestions),
            const SizedBox(height: 16),
            Text(
              'Nutrition values are estimates, not medical-grade measurements.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: ActivusColors.textTertiary),
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

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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

    const target = 2000;
    final progress = (calories / target).clamp(0.0, 1.0);

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: CustomPaint(
              painter: _CircularKcalGauge(
                progress: progress,
                color: ActivusColors.primaryBlue,
                bgColor: ActivusColors.border,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$calories',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ActivusColors.primaryBlue,
                      ),
                    ),
                    const Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 10,
                        color: ActivusColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MacroRow(
                  label: 'Protein',
                  value: '$protein g',
                  color: ActivusColors.primaryBlue,
                ),
                const SizedBox(height: 8),
                _MacroRow(
                  label: 'Carbs',
                  value: '$carbs g',
                  color: ActivusColors.category2,
                ),
                const SizedBox(height: 8),
                _MacroRow(
                  label: 'Fat',
                  value: '$fat g',
                  color: ActivusColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularKcalGauge extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _CircularKcalGauge({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      2 * 3.14159265 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularKcalGauge oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: ActivusColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.mealEntry, required this.onDelete});

  final Map<String, dynamic> mealEntry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final meal = mealEntry['meal'] as Meal;
    final calories = (mealEntry['calories'] as num).toDouble().round();
    final entries = mealEntry['entries'] as List;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const CategoryIconContainer(
            icon: Icons.restaurant_outlined,
            color: ActivusColors.category2,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entries.isEmpty
                      ? 'No foods'
                      : entries
                            .map(
                              (e) =>
                                  '${(e['food'] as Food).name} (${(e['quantity'] as num)} ${e['unit']})',
                            )
                            .join(', '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ActivusColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$calories kcal',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ActivusColors.primaryBlue,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _MealSuggestionsCard extends StatelessWidget {
  const _MealSuggestionsCard({required this.suggestions});

  final AsyncValue<List<MealSuggestion>> suggestions;

  @override
  Widget build(BuildContext context) {
    return suggestions.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Meal ideas',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.lightbulb_outline, size: 18),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Generated locally from your foods — estimates, not medical advice.',
                style: TextStyle(
                  fontSize: 12,
                  color: ActivusColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              for (final s in list) ...[
                _SuggestionTile(suggestion: s),
                if (s != list.last) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion});

  final MealSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          suggestion.mealType,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          suggestion.foods.map((f) => f.name).join(' + '),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          suggestion.reason,
          style: const TextStyle(
            fontSize: 12,
            color: ActivusColors.textTertiary,
          ),
        ),
      ],
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
