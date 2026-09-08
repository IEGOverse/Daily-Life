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
      title: 'Aktivitas',
      current: current.completedActivities.toDouble(),
      previous: previous.completedActivities.toDouble(),
      unit: 'tugas selesai',
    );

    if (current.studySessions > 0 || previous.studySessions > 0) {
      _addComparison(
        insights,
        title: 'Waktu belajar',
        current: current.studyMinutes,
        previous: previous.studyMinutes,
        unit: 'menit belajar',
        round: true,
      );
    }

    if (current.workouts > 0 || previous.workouts > 0) {
      _addComparison(
        insights,
        title: 'Olahraga',
        current: current.workouts.toDouble(),
        previous: previous.workouts.toDouble(),
        unit: 'sesi olahraga',
      );
    }

    if (current.habitCompletions > 0 || previous.habitCompletions > 0) {
      _addComparison(
        insights,
        title: 'Kebiasaan',
        current: current.habitCompletions.toDouble(),
        previous: previous.habitCompletions.toDouble(),
        unit: 'penyelesaian kebiasaan',
      );
    }

    _addComparison(
      insights,
      title: 'Skor harian',
      current: current.avgScoreOrZero,
      previous: previous.avgScoreOrZero,
      unit: 'rata-rata poin',
      round: true,
    );

    if (current.income > 0 || previous.income > 0) {
      _addComparison(
        insights,
        title: 'Pemasukan',
        current: current.income,
        previous: previous.income,
        unit: 'pemasukan',
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
          title: '$title stabil',
          detail:
              'Minggu ini $title sama dengan minggu lalu (${_fmt(current, round: round, money: money)}).',
        ),
      );
      return;
    }
    final up = current > previous;
    final delta = (current - previous).abs();
    insights.add(
      PersonalInsight(
        direction: up ? TrendDirection.up : TrendDirection.down,
        title: '$title ${up ? 'meningkat' : 'menurun'}',
        detail:
            'Minggu ini $title ${_deltaPhrase(delta, unit, round: round, money: money)} dibandingkan minggu lalu.',
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
    return 'berubah $d ($unit)';
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
