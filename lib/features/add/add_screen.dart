import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../activities/activity_providers.dart';
import '../activities/domain/activity.dart';
import '../activities/domain/activity_status.dart';
import '../dashboard/dashboard_providers.dart';

/// Category choices for a manually added activity.
const List<String> _categories = [
  'study',
  'workout',
  'work',
  'finance',
  'nutrition',
  'habit',
  'personal',
];

/// Form to manually create a one-off activity.
///
/// Minimal fields per PRD "record in as few steps as possible": title,
/// category, date, start time, optional end time, optional notes.
class AddActivityScreen extends ConsumerStatefulWidget {
  const AddActivityScreen({super.key});

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = _categories.first;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay? _endTime;
  bool _hasEndTime = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider);
    _date = DateTime(now.year, now.month, now.day);
    _startTime = TimeOfDay(hour: now.hour, minute: now.minute);
    _endTime = null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = _hasEndTime && _endTime != null
        ? DateTime(
            _date.year,
            _date.month,
            _date.day,
            _endTime!.hour,
            _endTime!.minute,
          )
        : null;

    final activity = Activity(
      id: _newActivityId(),
      title: _titleController.text.trim(),
      category: _category,
      startTime: start,
      endTime: end,
      status: ActivityStatus.scheduled,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await ref.read(activityRepositoryProvider).insert(activity);
      // Refresh everywhere the new activity could appear.
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(activitiesForDayProvider);
      ref.invalidate(
        activitiesForMonthProvider(DateTime(_date.year, _date.month)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Activity added')));
        context.go('/today');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _newActivityId() {
    final now = DateTime.now();
    final micro = now.microsecondsSinceEpoch;
    final seed = _titleController.text.trim().toLowerCase();
    final suffix = seed.isEmpty
        ? 'manual'
        : seed.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return 'act_${micro}_$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Group study session',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a title'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'Date',
                      value: _formatDate(_date),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeTile(
                      label: 'Start',
                      value: _formatTimeOfDay(_startTime),
                      onTap: _pickStartTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _hasEndTime,
                    onChanged: (value) => setState(() => _hasEndTime = value),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeTile(
                      label: 'End (optional)',
                      value: _endTime == null
                          ? '—'
                          : _formatTimeOfDay(_endTime!),
                      onTap: _hasEndTime ? _pickEndTime : () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final period = t.hour < 12 ? 'AM' : 'PM';
    final displayHour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$displayHour:${t.minute.toString().padLeft(2, '0')} $period';
  }
}

/// Tappable box that shows a label and a value.
class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FieldTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(value),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldTile(label: label, value: value, onTap: onTap);
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldTile(label: label, value: value, onTap: onTap);
  }
}
