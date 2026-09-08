import 'weekly_summary.dart';

/// A single explainable, locally-generated personal insight.
///
/// Generated on-device by comparing the current and previous weeks'
/// [WeeklySummary]s. No data ever leaves the device for this (PRD §14).
class PersonalInsight {
  /// Trend direction used only for UI accents.
  final TrendDirection direction;
  final String title;
  final String detail;

  const PersonalInsight({
    required this.direction,
    required this.title,
    required this.detail,
  });
}

enum TrendDirection { up, down, flat }

/// Compares current vs previous [WeeklySummary] and produces short, neutral,
/// factual insights (PRD §14 example: "Your study time increased this week
/// compared with last week").
class InsightGenerator {
  const InsightGenerator();

  List<PersonalInsight> generate(
    WeeklySummary current,
    WeeklySummary previous,
  ) {
    final insights = <PersonalInsight>[];
    if (current.scoredDays == 0) return insights;

    _addComparison(
      insights,
      title: 'Activities',
      current: current.completedActivities.toDouble(),
      previous: previous.completedActivities.toDouble(),
      unit: 'tasks completed',
    );

    if (current.studySessions > 0 || previous.studySessions > 0) {
      _addComparison(
        insights,
        title: 'Study time',
        current: current.studyMinutes,
        previous: previous.studyMinutes,
        unit: 'study minutes',
        round: true,
      );
    }

    if (current.workouts > 0 || previous.workouts > 0) {
      _addComparison(
        insights,
        title: 'Workouts',
        current: current.workouts.toDouble(),
        previous: previous.workouts.toDouble(),
        unit: 'workouts',
      );
    }

    if (current.habitCompletions > 0 || previous.habitCompletions > 0) {
      _addComparison(
        insights,
        title: 'Habits',
        current: current.habitCompletions.toDouble(),
        previous: previous.habitCompletions.toDouble(),
        unit: 'habit completions',
      );
    }

    _addComparison(
      insights,
      title: 'Daily score',
      current: current.avgScoreOrZero,
      previous: previous.avgScoreOrZero,
      unit: 'pts average',
      round: true,
    );

    if (current.income > 0 || previous.income > 0) {
      _addComparison(
        insights,
        title: 'Income',
        current: current.income,
        previous: previous.income,
        unit: 'income',
        money: true,
      );
    }

    return insights;
  }

  void _addComparison(
    List<PersonalInsight> insights, {
    required String title,
    required double current,
    required double previous,
    required String unit,
    bool round = false,
    bool money = false,
  }) {
    if (current == previous) {
      insights.add(
        PersonalInsight(
          direction: TrendDirection.flat,
          title: '$title is steady',
          detail:
              '$title this week matches last week (${_fmt(current, round: round, money: money)}).',
        ),
      );
      return;
    }
    final up = current > previous;
    final delta = (current - previous).abs();
    insights.add(
      PersonalInsight(
        direction: up ? TrendDirection.up : TrendDirection.down,
        title: '$title ${up ? 'increased' : 'decreased'}',
        detail:
            '$title ${_deltaPhrase(delta, unit, round: round, money: money)} this week compared with last week.',
      ),
    );
  }

  String _deltaPhrase(
    double delta,
    String unit, {
    bool round = false,
    bool money = false,
  }) {
    final d = _fmt(delta, round: round, money: money);
    return 'changed by $d ($unit)';
  }

  String _fmt(double value, {bool round = false, bool money = false}) {
    if (money) return _money(value);
    return round ? '${value.round()}' : _trim(value);
  }

  String _trim(double value) {
    if (value == value.roundToDouble()) return '${value.round()}';
    return value.toStringAsFixed(1);
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
