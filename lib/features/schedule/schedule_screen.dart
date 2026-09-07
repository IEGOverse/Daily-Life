import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart' as db;
import '../../core/widgets/widgets.dart';
import 'schedule_providers.dart';

/// Abbreviations for each weekday.
const _dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Full names for each weekday.
const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final schedulesAsync = ref.watch(schedulesForDayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: Column(
        children: [
          _DaySelector(selectedDay: selectedDay, ref: ref),
          Expanded(
            child: schedulesAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: 'Could not load schedule.',
                onRetry: () => ref.invalidate(schedulesForDayProvider),
              ),
              data: (schedules) => _ScheduleList(
                schedules: schedules,
                dayName: _dayNames[selectedDay - 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal row of day-of-week chips; the currently selected day is
/// highlighted and centered.
class _DaySelector extends StatelessWidget {
  final int selectedDay;
  final WidgetRef ref;

  const _DaySelector({required this.selectedDay, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    ref.read(selectedDayProvider.notifier).state = i + 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayAbbr[i],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: i + 1 == selectedDay
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: i + 1 == selectedDay
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: i + 1 == selectedDay
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Scrollable list of schedule cards for the selected day.
class _ScheduleList extends StatelessWidget {
  final List<db.Schedule> schedules;
  final String dayName;

  const _ScheduleList({required this.schedules, required this.dayName});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return EmptyState(
        message: 'No classes on $dayName.',
        icon: Icons.event_busy_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ScheduleCard(schedule: schedule),
        );
      },
    );
  }
}

/// A single schedule entry card showing time range, title, and class icon.
class _ScheduleCard extends StatelessWidget {
  final db.Schedule schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startTime = _parseTime(schedule.startTime);
    final endTime = _parseTime(schedule.endTime);
    final timeDisplay = '${_formatTime(startTime)} – ${_formatTime(endTime)}';

    return AppCard(
      child: Row(
        children: [
          Icon(Icons.school_outlined, size: 32, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  timeDisplay,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Parses "HH:MM" into a [DateTime] for display purposes.
DateTime _parseTime(String time) {
  final parts = time.split(':');
  return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
}

/// Formats a [DateTime] into a human-readable time like "10:10 AM".
String _formatTime(DateTime t) {
  final hour = t.hour;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:$minute $period';
}
