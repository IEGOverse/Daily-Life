import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import 'dashboard_providers.dart';
import 'domain/dashboard_summary.dart';
import 'domain/today_activity.dart';

/// Maps an activity category to a representative icon.
IconData iconForCategory(String category) {
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
    case 'personal':
      return Icons.person_outline;
    default:
      return Icons.event_note_outlined;
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Life'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Could not load today.',
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
          child: _TodayContent(summary: summary, now: ref.watch(clockProvider)),
        ),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  final DashboardSummary summary;
  final DateTime now;

  const _TodayContent({required this.summary, required this.now});

  @override
  Widget build(BuildContext context) {
    final current = summary.currentActivityAt(now);
    final next = summary.nextActivityAfter(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Greeting(day: now),
        const SizedBox(height: 16),
        _DailyProgress(summary: summary),
        if (current != null) ...[
          const SizedBox(height: 16),
          _CurrentActivity(activity: current),
        ],
        if (next != null) ...[
          const SizedBox(height: 16),
          _NextUp(activity: next),
        ],
        const SizedBox(height: 16),
        const SectionHeader(title: "Today's Timeline"),
        const SizedBox(height: 4),
        if (summary.totalActivities == 0)
          const EmptyState(message: 'Nothing planned today.', icon: Icons.event)
        else
          _Timeline(activities: summary.activities, now: now),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Finance'),
        const SizedBox(height: 4),
        _FinanceSummary(finance: summary.finance),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  final DateTime day;

  const _Greeting({required this.day});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_greetingFor(day.hour), style: textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(_formatDate(day), style: textTheme.bodyMedium),
      ],
    );
  }

  String _greetingFor(int hour) {
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  String _formatDate(DateTime d) {
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
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

class _DailyProgress extends StatelessWidget {
  final DashboardSummary summary;

  const _DailyProgress({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (summary.progress * 100).round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Progress',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text('$percent%', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${summary.completedActivities} of ${summary.totalActivities} activities completed',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CurrentActivity extends StatelessWidget {
  final TodayActivity activity;

  const _CurrentActivity({required this.activity});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.play_circle_fill, size: 36, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOW',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _timeRange(activity),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextUp extends StatelessWidget {
  final TodayActivity activity;

  const _NextUp({required this.activity});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            iconForCategory(activity.category),
            size: 32,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT UP',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatTime(activity.startTime)} - ${activity.title}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<TodayActivity> activities;
  final DateTime now;

  const _Timeline({required this.activities, required this.now});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final activity in activities) ...[
          ActivityCard(
            title: activity.title,
            subtitle: activity.notes ?? activity.category,
            time: _timeRange(activity),
            status: _statusLabel(activity, now),
            icon: iconForCategory(activity.category),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _statusLabel(TodayActivity activity, DateTime now) {
    if (activity.status == ActivityStatus.completed) {
      return 'Completed';
    }
    if (activity.status == ActivityStatus.skipped) {
      return 'Skipped';
    }
    if (activity.isCurrentAt(now)) {
      return 'In Progress';
    }
    if (activity.isUpcomingAfter(now)) {
      return 'Upcoming';
    }
    return 'Scheduled';
  }
}

class _FinanceSummary extends StatelessWidget {
  final FinanceSummary finance;

  const _FinanceSummary({required this.finance});

  @override
  Widget build(BuildContext context) {
    if (finance.income == 0 && finance.expense == 0) {
      return const EmptyState(
        message: 'No transactions today.',
        icon: Icons.account_balance_wallet_outlined,
      );
    }
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Balance',
            value: _formatAmount(finance.balance),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Income',
            value: _formatAmount(finance.income),
            icon: Icons.south_west,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Spent',
            value: _formatAmount(finance.expense),
            icon: Icons.north_east,
          ),
        ),
      ],
    );
  }

  String _formatAmount(int value) {
    final sign = value < 0 ? '-' : '';
    return '$sign\$${value.abs()}';
  }
}

String _timeRange(TodayActivity activity) {
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
