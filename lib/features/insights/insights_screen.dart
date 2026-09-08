import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/daily_score.dart';
import 'domain/insight_generator.dart';
import 'domain/time_analytics.dart';
import 'domain/weekly_summary.dart';
import 'insights_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyScore = ref.watch(dailyScoreProvider);
    final weekly = ref.watch(weeklySummaryProvider);
    final time = ref.watch(weeklyTimeProvider);
    final insights = ref.watch(personalInsightsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyScoreProvider);
          ref.invalidate(weeklySummaryProvider);
          ref.invalidate(weeklyTimeProvider);
          ref.invalidate(personalInsightsProvider);
          await ref.read(weeklySummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            _ScoreCard(score: dailyScore),
            const SizedBox(height: 16),
            _WeeklySummaryCard(summary: weekly),
            const SizedBox(height: 16),
            _PersonalInsightsCard(insights: insights),
            const SizedBox(height: 16),
            _TimeDistributionCard(time: time),
            const SizedBox(height: 16),
            const _ModuleLinks(),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});

  final AsyncValue<DailyScore> score;

  @override
  Widget build(BuildContext context) {
    return score.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (s) {
        final primary = Theme.of(context).colorScheme.primary;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's score",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!s.hasData) const Icon(Icons.info_outline, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                if (!s.hasData)
                  const Text(
                    'No activities or habits recorded today yet.',
                    style: TextStyle(color: Colors.white70),
                  )
                else ...[
                  Text(
                    '${s.score}',
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold, color: primary),
                  ),
                  const SizedBox(height: 12),
                  _ScoreBar(
                    label: 'Tasks',
                    fraction: s.taskScore,
                    color: primary,
                  ),
                  const SizedBox(height: 8),
                  _ScoreBar(
                    label: 'Habits',
                    fraction: s.habitScore,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scoreHint(s.score),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
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

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.fraction,
    required this.color,
  });

  final String label;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text('${(fraction * 100).round()}%'),
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
        final textTheme = Theme.of(context).textTheme;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This week', style: textTheme.titleMedium),
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
                const SizedBox(height: 16),
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

class _PersonalInsightsCard extends StatelessWidget {
  const _PersonalInsightsCard({required this.insights});

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
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal insights',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Generated locally from your records — nothing leaves this device.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 12),
                for (final insight in list) ...[
                  _InsightRow(insight: insight),
                  if (insight != list.last) const Divider(height: 16),
                ],
              ],
            ),
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
      TrendDirection.up => Colors.teal,
      TrendDirection.down => Colors.orange,
      TrendDirection.flat => Theme.of(context).colorScheme.primary,
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
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                insight.detail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
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
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
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
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No time recorded this week yet.'),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time this week',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final entry in t.entries) ...[
                  _TimeBar(entry: entry),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 4),
                Text(
                  '${t.totalMinutes.round()} minutes tracked',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
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
            Text(entry.label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: entry.fraction,
            minHeight: 6,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.15),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modules', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final (label, route, icon) in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon),
                title: Text(label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(route),
              ),
          ],
        ),
      ),
    );
  }
}
