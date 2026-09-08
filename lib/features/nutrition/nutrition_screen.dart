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
      appBar: AppBar(title: const Text('Nutrisi')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ActivusColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _openAddMealDialog(context, ref, day),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Makanan'),
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Gagal memuat nutrisi.')),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _NutritionSummary(summary: s),
            const SizedBox(height: 20),
            _SectionLabel(label: 'Makanan'),
            if ((s['meals'] as List).isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Belum ada makanan yang tercatat hari ini.'),
                ),
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
              'Nilai gizi adalah perkiraan, bukan pengukuran tingkat medis.',
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
    await ref.read(foodsProvider.future);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _AddMealDialog(
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
                  label: 'Karbohidrat',
                  value: '$carbs g',
                  color: ActivusColors.category2,
                ),
                const SizedBox(height: 8),
                _MacroRow(
                  label: 'Lemak',
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
                      ? 'Tidak ada makanan'
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
                    'Ide Makanan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.lightbulb_outline, size: 18),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Dihasilkan lokal dari makanan Anda — perkiraan, bukan saran medis.',
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

class _AddMealDialog extends ConsumerStatefulWidget {
  const _AddMealDialog({required this.day, required this.onSave});

  final DateTime day;
  final Future<void> Function(_DraftMeal meal) onSave;

  @override
  ConsumerState<_AddMealDialog> createState() => _AddMealDialogState();
}

class _DraftMeal {
  _DraftMeal({required this.meal, required this.items});
  final Meal meal;
  final List<MealFood> items;
}

class _AddMealDialogState extends ConsumerState<_AddMealDialog> {
  static const _mealTypes = [
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Camilan',
  ];

  String _mealType = 'Sarapan';
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

  Future<void> _createFood() async {
    final repo = ref.read(nutritionRepositoryProvider);
    final created = await showDialog<Food>(
      context: context,
      builder: (context) => _AddFoodDialog(
        onSave: (food) async {
          await repo.insertFood(food);
          return food;
        },
      ),
    );
    if (created != null) {
      ref.invalidate(foodsProvider);
      ref.invalidate(mealSuggestionsProvider);
      ref.invalidate(dailyNutritionProvider(widget.day));
    }
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
    final foodsAsync = ref.watch(foodsProvider);
    return AlertDialog(
      title: const Text('Tambah Makanan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _mealType,
              decoration: const InputDecoration(
                labelText: 'Jenis Makanan',
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
            foodsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const Text('Gagal memuat makanan.'),
              data: (foods) {
                if (foods.isEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Belum ada makanan di database.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tambahkan makanan dulu untuk mulai mencatat menu Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: ActivusColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _createFood,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Makanan Baru'),
                      ),
                    ],
                  );
                }
                _food = foods.firstWhere(
                  (f) => f.id == _food?.id,
                  orElse: () => foods.first,
                );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Food>(
                      key: ValueKey(foods),
                      initialValue: _food,
                      decoration: const InputDecoration(
                        labelText: 'Makanan',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final f in foods)
                          DropdownMenuItem(value: f, child: Text(f.name)),
                      ],
                      onChanged: (value) => setState(() => _food = value),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _createFood,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah Makanan Baru'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Jumlah (${_food?.servingUnit ?? ''})',
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
                          child: const Text('Tambah'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selected.isEmpty)
                      const Text('Belum ada item ditambahkan.')
                    else
                      for (final e in _selected)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.food.name),
                          trailing: Text('${e.quantity} ${e.food.servingUnit}'),
                        ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan Makanan')),
      ],
    );
  }
}

class _AddFoodDialog extends StatefulWidget {
  const _AddFoodDialog({required this.onSave});

  final Future<Food> Function(Food food) onSave;

  @override
  State<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '1');
  final _servingUnitController = TextEditingController(text: 'porsi');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _servingSizeController.dispose();
    _servingUnitController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final food = Food(
      id: 'food_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      servingSize: double.tryParse(_servingSizeController.text.trim()) ?? 1,
      servingUnit: _servingUnitController.text.trim(),
      calories: _num(_caloriesController),
      protein: _num(_proteinController),
      carbohydrate: _num(_carbsController),
      fat: _num(_fatController),
    );
    try {
      await widget.onSave(food);
      if (mounted) Navigator.of(context).pop(food);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Makanan Baru'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Masukkan nama makanan.'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _servingSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Ukuran Porsi',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          (double.tryParse(value?.trim() ?? '') ?? 0) > 0
                          ? null
                          : 'Porsi tidak valid.',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _servingUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Satuan',
                        hintText: 'mis. porsi, g, buah',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Kalori (per porsi)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Karbo (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Lemak (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan Makanan'),
        ),
      ],
    );
  }
}
