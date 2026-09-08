import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'domain/daily_score.dart';
import 'domain/insight_generator.dart';
import 'domain/time_analytics.dart';
import 'domain/weekly_summary.dart';
import 'insights_providers.dart';

enum _InsightTab { overview, analytics, trends }

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: _InsightsBody());
  }
}

class _InsightsBody extends ConsumerStatefulWidget {
  const _InsightsBody();

  @override
  ConsumerState<_InsightsBody> createState() => _InsightsBodyState();
}

class _InsightsBodyState extends ConsumerState<_InsightsBody> {
  _InsightTab _tab = _InsightTab.overview;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Insights',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _TabButton(
                label: 'Overview',
                isActive: _tab == _InsightTab.overview,
                onTap: () => setState(() => _tab = _InsightTab.overview),
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: 'Analytics',
                isActive: _tab == _InsightTab.analytics,
                onTap: () => setState(() => _tab = _InsightTab.analytics),
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: 'Trends',
                isActive: _tab == _InsightTab.trends,
                onTap: () => setState(() => _tab = _InsightTab.trends),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dailyScoreProvider);
              ref.invalidate(weeklySummaryProvider);
              ref.invalidate(weeklyTimeProvider);
              ref.invalidate(personalInsightsProvider);
              await ref.read(weeklySummaryProvider.future);
            },
            child: Builder(
              builder: (context) {
                switch (_tab) {
                  case _InsightTab.overview:
                    return _OverviewTab(ref: ref);
                  case _InsightTab.analytics:
                    return _AnalyticsTab(ref: ref);
                  case _InsightTab.trends:
                    return _TrendsTab(ref: ref);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive
                ? ActivusColors.primaryBlue
                : ActivusColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? ActivusColors.primaryBlue
                  : ActivusColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.white : ActivusColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final WidgetRef ref;

  const _OverviewTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final dailyScore = ref.watch(dailyScoreProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _ScoreGaugeCard(score: dailyScore),
        const SizedBox(height: 16),
        _PersonalInsightsCard(insights: ref.watch(personalInsightsProvider)),
        const SizedBox(height: 16),
        const _ModuleLinks(),
      ],
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  final WidgetRef ref;

  const _AnalyticsTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final weekly = ref.watch(weeklySummaryProvider);
    final time = ref.watch(weeklyTimeProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _WeeklySummaryCard(summary: weekly),
        const SizedBox(height: 16),
        _TimeDistributionCard(time: time),
      ],
    );
  }
}

class _TrendsTab extends StatelessWidget {
  final WidgetRef ref;

  const _TrendsTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(personalInsightsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [_InsightListCard(insights: insights)],
    );
  }
}

class _ScoreGaugeCard extends StatelessWidget {
  const _ScoreGaugeCard({required this.score});

  final AsyncValue<DailyScore> score;

  @override
  Widget build(BuildContext context) {
    return score.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (s) {
        final fraction = s.hasData ? s.score / 100.0 : 0.0;
        return AppCard(
          child: Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CustomPaint(
                  painter: _ScoreGaugePainter(
                    progress: fraction.clamp(0.0, 1.0),
                    color: ActivusColors.primaryBlue,
                    bgColor: ActivusColors.border,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.hasData ? '${s.score}' : '—',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: ActivusColors.primaryBlue,
                          ),
                        ),
                        const Text(
                          '/ 100',
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
                    const Text(
                      "Today's score",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!s.hasData)
                      const Text(
                        'No activities or habits recorded today yet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: ActivusColors.textTertiary,
                        ),
                      )
                    else ...[
                      const SizedBox(height: 4),
                      _GaugeBar(
                        label: 'Tasks',
                        fraction: s.taskScore,
                        color: ActivusColors.primaryBlue,
                      ),
                      const SizedBox(height: 6),
                      _GaugeBar(
                        label: 'Habits',
                        fraction: s.habitScore,
                        color: ActivusColors.category2,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _scoreHint(s.score),
                        style: const TextStyle(
                          fontSize: 12,
                          color: ActivusColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _scoreHint(int score) {
    if (score >= 90) return 'Great day';
    if (score >= 70) return 'Solid day';
    if (score >= 50) return 'On track';
    return 'Room to grow';
  }
}

class _ScoreGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _ScoreGaugePainter({
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
  bool shouldRepaint(covariant _ScoreGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GaugeBar extends StatelessWidget {
  final String label;
  final double fraction;
  final Color color;

  const _GaugeBar({
    required this.label,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: ActivusColors.textSecondary,
              ),
            ),
            Text(
              '${(fraction * 100).round()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({required this.summary});

  final AsyncValue<WeeklySummary> summary;

  @override
  Widget build(BuildContext context) {
    return summary.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (s) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This week',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatBlock(
                    label: 'Avg score',
                    value: s.scoredDays == 0 ? '—' : '${s.averageScore}',
                  ),
                  const SizedBox(width: 12),
                  _StatBlock(
                    label: 'Tasks',
                    value: '${s.completedActivities}/${s.plannedActivities}',
                  ),
                  const SizedBox(width: 12),
                  _StatBlock(
                    label: 'Study',
                    value: s.studySessions > 0
                        ? '${s.studyMinutes.round()}m'
                        : '—',
                  ),
                  const SizedBox(width: 12),
                  _StatBlock(label: 'Workouts', value: '${s.workouts}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatBlock(label: 'Meals', value: '${s.mealCount}'),
                  const SizedBox(width: 12),
                  _StatBlock(label: 'Income', value: _money(s.income)),
                  const SizedBox(width: 12),
                  _StatBlock(label: 'Expense', value: _money(s.expense)),
                  const SizedBox(width: 12),
                  _StatBlock(
                    label: 'Habits',
                    value: '${s.habitCompletions}/${s.habitLogDays}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _money(double value) {
    final v = value.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < v.length; i++) {
      buf.write(v[i]);
      final rem = v.length - i - 1;
      if (rem > 0 && rem % 3 == 0) buf.write('.');
    }
    return 'Rp $buf';
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ActivusColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TimeDistributionCard extends StatelessWidget {
  const _TimeDistributionCard({required this.time});

  final AsyncValue<TimeAnalytics> time;

  @override
  Widget build(BuildContext context) {
    return time.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (t) {
        if (t.isEmpty) {
          return const AppCard(child: Text('No time recorded this week yet.'));
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time this week',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (final entry in t.entries) ...[
                _TimeBar(entry: entry),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              Text(
                '${t.totalMinutes.round()} minutes tracked',
                style: const TextStyle(
                  fontSize: 12,
                  color: ActivusColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimeBar extends StatelessWidget {
  const _TimeBar({required this.entry});

  final TimeEntry entry;

  @override
  Widget build(BuildContext context) {
    final minutes = entry.minutes.round();
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    final label = hours > 0 ? '${hours}h ${rem}m' : '${rem}m';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              entry.label,
              style: const TextStyle(
                fontSize: 12,
                color: ActivusColors.textSecondary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: entry.fraction,
            minHeight: 6,
            color: ActivusColors.primaryBlue,
            backgroundColor: ActivusColors.primaryBlue.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

class _PersonalInsightsCard extends StatelessWidget {
  const _PersonalInsightsCard({required this.insights});

  final AsyncValue<List<PersonalInsight>> insights;

  @override
  Widget build(BuildContext context) {
    return _InsightListCard(insights: insights);
  }
}

class _InsightListCard extends StatelessWidget {
  const _InsightListCard({required this.insights});

  final AsyncValue<List<PersonalInsight>> insights;

  @override
  Widget build(BuildContext context) {
    return insights.when(
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
              const Text(
                'Personal insights',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Generated locally from your records — nothing leaves this device.',
                style: TextStyle(
                  fontSize: 12,
                  color: ActivusColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              for (final insight in list) ...[
                _InsightRow(insight: insight),
                if (insight != list.last) const Divider(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final PersonalInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.direction) {
      TrendDirection.up => ActivusColors.success,
      TrendDirection.down => ActivusColors.warning,
      TrendDirection.flat => ActivusColors.primaryBlue,
    };
    final icon = switch (insight.direction) {
      TrendDirection.up => Icons.trending_up,
      TrendDirection.down => Icons.trending_down,
      TrendDirection.flat => Icons.trending_flat,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                insight.detail,
                style: const TextStyle(
                  fontSize: 12,
                  color: ActivusColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleLinks extends StatelessWidget {
  const _ModuleLinks();

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      ('Workout', '/workout', Icons.fitness_center),
      ('Study', '/study', Icons.menu_book),
      ('Finance', '/finance', Icons.account_balance_wallet),
      ('Nutrition', '/nutrition', Icons.restaurant),
      ('Habits', '/habits', Icons.check_circle_outline),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modules',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final (label, route, icon) in items)
            InkWell(
              onTap: () => context.push(route),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ActivusColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: ActivusColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: ActivusColors.textTertiary,
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
