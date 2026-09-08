import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart' as db;
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'schedule_providers.dart';

/// Abbreviations for each weekday.
const _dayAbbr = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Full names for each weekday.
const _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final schedulesAsync = ref.watch(schedulesForDayProvider);

    return Scaffold(
      body: Column(
        children: [
          const _Header(),
          _DaySelector(selectedDay: selectedDay, ref: ref),
          const Divider(),
          Expanded(
            child: schedulesAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: 'Gagal memuat jadwal.',
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Jadwal',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: i + 1 == selectedDay
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: i + 1 == selectedDay
                            ? ActivusColors.primaryBlue
                            : ActivusColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: i + 1 == selectedDay
                            ? ActivusColors.primaryBlue
                            : ActivusColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: i + 1 == selectedDay
                              ? Colors.white
                              : ActivusColors.textSecondary,
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

/// Scrollable list of schedule entries for the selected day.
class _ScheduleList extends StatelessWidget {
  final List<db.Schedule> schedules;
  final String dayName;

  const _ScheduleList({required this.schedules, required this.dayName});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return EmptyState(
        message: 'Tidak ada jadwal pada hari $dayName.',
        icon: Icons.event_busy_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ScheduleRow(schedule: schedule),
        );
      },
    );
  }
}

/// A compact schedule row: category icon container, time range, title.
class _ScheduleRow extends StatelessWidget {
  final db.Schedule schedule;

  const _ScheduleRow({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final startTime = _parseTime(schedule.startTime);
    final endTime = _parseTime(schedule.endTime);
    final timeDisplay = '${_formatTime(startTime)} – ${_formatTime(endTime)}';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const CategoryIconContainer(
            icon: Icons.school_outlined,
            color: ActivusColors.primaryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ActivusColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: ActivusColors.textTertiary,
          ),
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

/// Formats a [DateTime] into a 24-hour string like "10:10".
String _formatTime(DateTime t) {
  final hour = t.hour.toString().padLeft(2, '0');
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
