import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../activities/activity_providers.dart';
import '../activities/domain/activity.dart';
import '../activities/domain/activity_status.dart';
import 'dashboard_providers.dart';
import 'domain/dashboard_summary.dart';

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

Color _colorForCategory(String category) {
  switch (category.trim().toLowerCase()) {
    case 'study':
      return ActivusColors.primaryBlue;
    case 'workout':
    case 'exercise':
      return ActivusColors.category;
    case 'finance':
    case 'money':
      return ActivusColors.success;
    case 'meal':
    case 'nutrition':
      return ActivusColors.category2;
    default:
      return ActivusColors.primaryBlueLight;
  }
}

Color _statusColor(ActivityStatus status) {
  switch (status) {
    case ActivityStatus.completed:
      return ActivusColors.statusCompleted;
    case ActivityStatus.inProgress:
      return ActivusColors.statusInProgress;
    case ActivityStatus.skipped:
      return ActivusColors.statusSoon;
    case ActivityStatus.upcoming:
    case ActivityStatus.scheduled:
      return ActivusColors.statusUpcoming;
  }
}

String _statusLabel(ActivityStatus status, bool isCurrent, bool isUpcoming) {
  switch (status) {
    case ActivityStatus.completed:
      return 'Selesai';
    case ActivityStatus.skipped:
      return 'Dilewati';
    case ActivityStatus.inProgress:
      return 'Sedang Berlangsung';
    case ActivityStatus.upcoming:
    case ActivityStatus.scheduled:
      if (isCurrent) return 'Sedang Berlangsung';
      if (isUpcoming) return 'Segera';
      return 'Akan Datang';
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final studyMinutes = ref.watch(todayStudyMinutesProvider);
    final nutritionAsync = ref.watch(todayNutritionSummaryProvider);
    final now = ref.watch(clockProvider);

    return Scaffold(
      body: summaryAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Gagal memuat hari ini.',
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
          child: _TodayContent(
            summary: summary,
            now: now,
            studyMinutes: studyMinutes,
            nutritionAsync: nutritionAsync,
          ),
        ),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  final DashboardSummary summary;
  final DateTime now;
  final AsyncValue<int> studyMinutes;
  final AsyncValue<Map<String, dynamic>> nutritionAsync;

  const _TodayContent({
    required this.summary,
    required this.now,
    required this.studyMinutes,
    required this.nutritionAsync,
  });

  @override
  Widget build(BuildContext context) {
    final current = summary.currentActivityAt(now);
    final next = summary.nextActivityAfter(now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _GreetingHeader(day: now),
        const SizedBox(height: 20),
        _DailyProgressGauge(summary: summary, now: now),
        if (current != null) ...[
          const SizedBox(height: 16),
          _NowCard(activity: current),
        ],
        if (next != null) ...[
          const SizedBox(height: 12),
          _NextUpCard(activity: next),
        ],
        const SizedBox(height: 20),
        _SectionTitle(title: 'Jadwal Hari Ini'),
        const SizedBox(height: 8),
        if (summary.totalActivities == 0)
          const EmptyState(
            message: 'Belum ada aktivitas hari ini.',
            icon: Icons.event,
          )
        else
          _Timeline(activities: summary.activities, now: now),
        const SizedBox(height: 20),
        _CompactFinanceSummary(finance: summary.finance),
        const SizedBox(height: 12),
        _CompactStudySummary(studyMinutes: studyMinutes),
        const SizedBox(height: 12),
        _CompactNutritionSummary(nutritionAsync: nutritionAsync),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final DateTime day;

  const _GreetingHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingFor(day.hour),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(day),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: ActivusColors.textSecondary),
              ),
            ],
          ),
        ),
        _SmallIconButton(
          icon: Icons.calendar_month_outlined,
          tooltip: 'Kalender & riwayat',
          onTap: () => context.push('/calendar'),
        ),
        const SizedBox(width: 4),
        _SmallIconButton(
          icon: Icons.notifications_outlined,
          tooltip: 'Pengingat',
          onTap: () => context.push('/reminders'),
        ),
      ],
    );
  }

  String _greetingFor(int hour) {
    if (hour < 12) return 'Selamat pagi';
    if (hour < 18) return 'Selamat siang';
    return 'Selamat malam';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ActivusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ActivusColors.border, width: 1),
      ),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _DailyProgressGauge extends StatelessWidget {
  final DashboardSummary summary;
  final DateTime now;

  const _DailyProgressGauge({required this.summary, required this.now});

  @override
  Widget build(BuildContext context) {
    final percent = (summary.progress * 100).round();
    final remaining = summary.totalActivities - summary.completedActivities;
    final inProgress = summary.activities
        .where((a) => a.status == ActivityStatus.inProgress)
        .length;

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _GaugePainter(
                progress: summary.progress,
                color: ActivusColors.primaryBlue,
                bgColor: ActivusColors.border,
              ),
              child: Center(
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ActivusColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progres Hari Ini',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ProgressStat(
                      label: 'Selesai',
                      value: '${summary.completedActivities}',
                      color: ActivusColors.success,
                    ),
                    const SizedBox(width: 12),
                    _ProgressStat(
                      label: 'Berlangsung',
                      value: '$inProgress',
                      color: ActivusColors.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    _ProgressStat(
                      label: 'Tersisa',
                      value: '$remaining',
                      color: ActivusColors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: ActivusColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _GaugePainter({
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
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _NowCard extends StatelessWidget {
  final Activity activity;

  const _NowCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CategoryIconContainer(
            icon: iconForCategory(activity.category),
            color: ActivusColors.statusInProgress,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(
                  label: 'SEKARANG',
                  color: ActivusColors.statusInProgress,
                ),
                const SizedBox(height: 6),
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeRange(activity),
                  style: const TextStyle(
                    fontSize: 13,
                    color: ActivusColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  final Activity activity;

  const _NextUpCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CategoryIconContainer(
            icon: iconForCategory(activity.category),
            color: _colorForCategory(activity.category),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(
                  label: 'BERIKUTNYA',
                  color: ActivusColors.warning,
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatTime(activity.startTime)} · ${activity.title}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    );
  }
}

class _Timeline extends ConsumerWidget {
  final List<Activity> activities;
  final DateTime now;

  const _Timeline({required this.activities, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final activity in activities) ...[
          _TimelineRow(
            activity: activity,
            now: now,
            onDone: () => _setStatus(ref, activity, ActivityStatus.completed),
            onSkip: () => _setStatus(ref, activity, ActivityStatus.skipped),
            onReset: () => _setStatus(ref, activity, ActivityStatus.scheduled),
          ),
          if (activity != activities.last) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Activity activity;
  final DateTime now;
  final VoidCallback onDone;
  final VoidCallback onSkip;
  final VoidCallback onReset;

  const _TimelineRow({
    required this.activity,
    required this.now,
    required this.onDone,
    required this.onSkip,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = activity.isCurrentAt(now);
    final isUpcoming = activity.isUpcomingAfter(now);
    final label = _statusLabel(activity.status, isCurrent, isUpcoming);
    final statusColor = _statusColor(activity.status);
    final color = _colorForCategory(activity.category);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CategoryIconContainer(
            icon: iconForCategory(activity.category),
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeRange(activity),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ActivusColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(label: label, color: statusColor),
          const SizedBox(width: 8),
          _CompletionActions(
            activity: activity,
            onDone: onDone,
            onSkip: onSkip,
            onReset: onReset,
          ),
        ],
      ),
    );
  }
}

class _CompletionActions extends StatelessWidget {
  final Activity activity;
  final VoidCallback onDone;
  final VoidCallback onSkip;
  final VoidCallback onReset;

  const _CompletionActions({
    required this.activity,
    required this.onDone,
    required this.onSkip,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (activity.status == ActivityStatus.completed ||
        activity.status == ActivityStatus.skipped) {
      return IconButton(
        tooltip: 'Atur ulang',
        icon: const Icon(Icons.refresh, size: 18),
        onPressed: onReset,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Selesai',
          icon: const Icon(Icons.check_circle_outline, size: 18),
          onPressed: onDone,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: 'Lewati',
          icon: const Icon(Icons.remove_circle_outline, size: 18),
          onPressed: onSkip,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

Future<void> _setStatus(
  WidgetRef ref,
  Activity activity,
  ActivityStatus status,
) async {
  await ref.read(activityRepositoryProvider).updateStatus(activity.id, status);
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(activitiesForDayProvider);
}

class _CompactFinanceSummary extends StatelessWidget {
  final FinanceSummary finance;

  const _CompactFinanceSummary({required this.finance});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => context.push('/finance'),
      child: Row(
        children: [
          const CategoryIconContainer(
            icon: Icons.account_balance_wallet_outlined,
            color: ActivusColors.success,
          ),
          const SizedBox(width: 12),
          const Text(
            'Keuangan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (finance.income == 0 && finance.expense == 0)
            const Text(
              'Belum ada transaksi hari ini',
              style: TextStyle(fontSize: 13, color: ActivusColors.textTertiary),
            )
          else
            Text(
              _formatAmount(finance.balance),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: finance.balance < 0
                    ? ActivusColors.danger
                    : ActivusColors.success,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: ActivusColors.textTertiary,
          ),
        ],
      ),
    );
  }

  String _formatAmount(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final rem = s.length - i - 1;
      if (rem > 0 && rem % 3 == 0) buf.write('.');
    }
    return '${value < 0 ? '-' : ''}Rp $buf';
  }
}

class _CompactStudySummary extends StatelessWidget {
  final AsyncValue<int> studyMinutes;

  const _CompactStudySummary({required this.studyMinutes});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => context.push('/study'),
      child: Row(
        children: [
          const CategoryIconContainer(
            icon: Icons.school_outlined,
            color: ActivusColors.primaryBlue,
          ),
          const SizedBox(width: 12),
          const Text(
            'Belajar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          studyMinutes.when(
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) => const Text(
              '—',
              style: TextStyle(fontSize: 13, color: ActivusColors.textTertiary),
            ),
            data: (minutes) => Text(
              minutes > 0
                  ? '$minutes mnt hari ini'
                  : 'Belum ada sesi belajar hari ini',
              style: const TextStyle(
                fontSize: 13,
                color: ActivusColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 4),
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

class _CompactNutritionSummary extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> nutritionAsync;

  const _CompactNutritionSummary({required this.nutritionAsync});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => context.push('/nutrition'),
      child: Row(
        children: [
          const CategoryIconContainer(
            icon: Icons.restaurant_outlined,
            color: ActivusColors.category2,
          ),
          const SizedBox(width: 12),
          const Text(
            'Nutrisi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          nutritionAsync.when(
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) => const Text(
              '—',
              style: TextStyle(fontSize: 13, color: ActivusColors.textTertiary),
            ),
            data: (s) {
              final kcal = (s['calories'] as num).toDouble().round();
              return Text(
                kcal > 0 ? '$kcal kcal' : 'Belum ada makanan hari ini',
                style: const TextStyle(
                  fontSize: 13,
                  color: ActivusColors.textSecondary,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
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

String _timeRange(Activity activity) {
  final end = activity.endTime;
  if (end == null) {
    return _formatTime(activity.startTime);
  }
  return '${_formatTime(activity.startTime)} – ${_formatTime(end)}';
}

String _formatTime(DateTime t) {
  final hour = t.hour.toString().padLeft(2, '0');
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
