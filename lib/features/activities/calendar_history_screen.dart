import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../activities/activity_providers.dart';
import '../activities/domain/activity.dart';
import '../activities/domain/activity_status.dart';
import '../dashboard/dashboard_providers.dart';

/// Activity count per day-of-month for a given [month].
final activitiesForMonthProvider =
    FutureProvider.family<Map<int, int>, DateTime>((ref, month) async {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);
      final activities = await ref
          .read(activityRepositoryProvider)
          .getForRange(start, end);
      final counts = <int, int>{};
      for (final activity in activities) {
        final day = activity.startTime.day;
        counts[day] = (counts[day] ?? 0) + 1;
      }
      return counts;
    });

/// A day in the calendar grid that is independently selectable.
class _DayCell {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final int? activityCount;

  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    this.activityCount,
  });
}

/// Calendar + history screen: month grid on top, selected day's activities
/// below, with the same Done/Skip/Reset actions as the dashboard.
class CalendarHistoryScreen extends ConsumerStatefulWidget {
  const CalendarHistoryScreen({super.key});

  @override
  ConsumerState<CalendarHistoryScreen> createState() =>
      _CalendarHistoryScreenState();
}

class _CalendarHistoryScreenState extends ConsumerState<CalendarHistoryScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = ref.read(clockProvider);
    _focusedMonth = DateTime(today.year, today.month);
    _selectedDay = DateTime(today.year, today.month, today.day);
  }

  @override
  Widget build(BuildContext context) {
    final monthActivitiesAsync = ref.watch(
      activitiesForMonthProvider(_focusedMonth),
    );
    final dayActivitiesAsync = ref.watch(
      activitiesForDayProvider(_selectedDay),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today),
            onPressed: () {
              final today = ref.read(clockProvider);
              setState(() {
                _focusedMonth = DateTime(today.year, today.month);
                _selectedDay = DateTime(today.year, today.month, today.day);
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _MonthHeader(
            month: _focusedMonth,
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          monthActivitiesAsync.when(
            loading: () => const LoadingState(),
            error: (e, _) => ErrorState(
              message: 'Could not load calendar.',
              onRetry: () =>
                  ref.invalidate(activitiesForMonthProvider(_focusedMonth)),
            ),
            data: (byDay) => _CalendarGrid(
              month: _focusedMonth,
              selectedDay: _selectedDay,
              counts: byDay,
              onSelectDay: (day) => setState(() => _selectedDay = day),
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatDayHeading(_selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          dayActivitiesAsync.when(
            loading: () => const LoadingState(),
            error: (e, _) => ErrorState(
              message: 'Could not load activities.',
              onRetry: () =>
                  ref.invalidate(activitiesForDayProvider(_selectedDay)),
            ),
            data: (activities) =>
                _DayActivityList(activities: activities, ref: ref),
          ),
        ],
      ),
    );
  }

  void _shiftMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      // Keep the selected day within the new month.
      final lastDay = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
        0,
      ).day;
      final clamped = _selectedDay.day > lastDay ? lastDay : _selectedDay.day;
      _selectedDay = DateTime(_focusedMonth.year, _focusedMonth.month, clamped);
    });
  }
}

/// Month title with previous/next arrows.
class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(
            '${months[month.month - 1]} ${month.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

/// A 7-column monthly grid with weekday headers and selectable day cells.
class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final Map<int, int> counts;
  final ValueChanged<DateTime> onSelectDay;

  const _CalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.counts,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();

    final leadingBlanks = firstWeekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    final cells = <_DayCell>[];
    for (var i = 0; i < totalCells; i++) {
      final dayNumber = i - leadingBlanks + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        continue;
      }
      final date = DateTime(month.year, month.month, dayNumber);
      cells.add(
        _DayCell(
          date: date,
          isSelected: _isSameDay(date, selectedDay),
          isToday: _isSameDay(date, today),
          activityCount: counts[dayNumber],
        ),
      );
    }

    return Column(
      children: [
        // Weekday header row.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 44,
          ),
          itemCount: cells.length,
          itemBuilder: (context, index) {
            final cell = cells[index];
            return _DayCellWidget(
              cell: cell,
              onTap: () => onSelectDay(cell.date),
            );
          },
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// A single calendar day cell.
class _DayCellWidget extends StatelessWidget {
  final _DayCell cell;
  final VoidCallback onTap;

  const _DayCellWidget({required this.cell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = cell.isSelected ? colorScheme.primary : Colors.transparent;
    final fg = cell.isSelected
        ? colorScheme.onPrimary
        : cell.isToday
        ? colorScheme.primary
        : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: cell.isToday && !cell.isSelected
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${cell.date.day}',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: fg),
            ),
            if (cell.activityCount != null && cell.activityCount! > 0)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: cell.isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The selected day's activities with completion actions.
class _DayActivityList extends StatelessWidget {
  final List<Activity> activities;
  final WidgetRef ref;

  const _DayActivityList({required this.activities, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const EmptyState(
        message: 'No activities for this day.',
        icon: Icons.calendar_today_outlined,
      );
    }
    return Column(
      children: [
        for (final activity in activities)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ActivityCard(
              title: activity.title,
              subtitle: activity.notes ?? activity.category,
              time: _timeRange(activity),
              status: activity.status.label,
              icon: _iconForCategory(activity.category),
              trailing: _HistoryActions(activity: activity, ref: ref),
            ),
          ),
      ],
    );
  }
}

/// Shared Done/Skip/Reset actions, reusing dashboard invalidation helpers.
class _HistoryActions extends StatelessWidget {
  final Activity activity;
  final WidgetRef ref;

  const _HistoryActions({required this.activity, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (!activity.status.isActionable) {
      return IconButton(
        tooltip: 'Reset',
        icon: const Icon(Icons.refresh),
        onPressed: () => _setStatus(ref, activity.id, ActivityStatus.scheduled),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Mark done',
          icon: const Icon(Icons.check_circle_outline),
          onPressed: () =>
              _setStatus(ref, activity.id, ActivityStatus.completed),
        ),
        IconButton(
          tooltip: 'Skip',
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => _setStatus(ref, activity.id, ActivityStatus.skipped),
        ),
      ],
    );
  }
}

Future<void> _setStatus(
  WidgetRef ref,
  String activityId,
  ActivityStatus status,
) async {
  await ref.read(activityRepositoryProvider).updateStatus(activityId, status);
  ref.invalidate(dashboardSummaryProvider);
  final day = ref.read(clockProvider);
  ref.invalidate(activitiesForDayProvider);
  ref.invalidate(activitiesForMonthProvider(DateTime(day.year, day.month)));
}

IconData _iconForCategory(String category) {
  switch (category.trim().toLowerCase()) {
    case 'study':
      return Icons.school_outlined;
    case 'workout':
    case 'exercise':
      return Icons.fitness_center;
    case 'work':
      return Icons.work_outline;
    case 'finance':
    case 'money':
      return Icons.account_balance_wallet_outlined;
    case 'meal':
    case 'nutrition':
      return Icons.restaurant_outlined;
    case 'habit':
      return Icons.repeat;
    default:
      return Icons.event_note_outlined;
  }
}

String _timeRange(Activity activity) {
  final end = activity.endTime;
  if (end == null) {
    return _formatTime(activity.startTime);
  }
  return '${_formatTime(activity.startTime)} - ${_formatTime(end)}';
}

String _formatTime(DateTime t) {
  final hour = t.hour;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:$minute $period';
}

String _formatDayHeading(DateTime day) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${days[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}, ${day.year}';
}
