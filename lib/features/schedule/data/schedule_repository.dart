import 'package:daily_life/core/database/database.dart' as db;

/// Seed data for the initial university schedule (PRD §5).
class ScheduleSeeder {
  /// Returns the initial weekly class schedule as a list of [db.Schedule]
  /// rows ready for insertion. Fields are explicit for clarity.
  static List<db.Schedule> initialSchedules() {
    final now = DateTime.now();
    return [
      // Monday & Wednesday
      _schedule(
        title: 'Business Process Reengineering',
        dayOfWeek: 1,
        start: '10:10',
        end: '11:30',
        now: now,
      ),
      _schedule(
        title: 'Data Mining and Warehousing',
        dayOfWeek: 1,
        start: '13:10',
        end: '14:30',
        now: now,
      ),
      _schedule(
        title: 'Research Method & Scientific Writing',
        dayOfWeek: 1,
        start: '14:40',
        end: '16:00',
        now: now,
      ),
      _schedule(
        title: 'Business Process Reengineering',
        dayOfWeek: 3,
        start: '10:10',
        end: '11:30',
        now: now,
      ),
      _schedule(
        title: 'Data Mining and Warehousing',
        dayOfWeek: 3,
        start: '13:10',
        end: '14:30',
        now: now,
      ),
      _schedule(
        title: 'Research Method & Scientific Writing',
        dayOfWeek: 3,
        start: '14:40',
        end: '16:00',
        now: now,
      ),

      // Tuesday & Thursday
      _schedule(
        title: 'System Analysis and Design',
        dayOfWeek: 2,
        start: '07:10',
        end: '08:30',
        now: now,
      ),
      _schedule(
        title: 'Front-End Web Development',
        dayOfWeek: 2,
        start: '13:10',
        end: '14:30',
        now: now,
      ),
      _schedule(
        title: 'Information System Security',
        dayOfWeek: 2,
        start: '14:40',
        end: '16:00',
        now: now,
      ),
      _schedule(
        title: 'System Analysis and Design',
        dayOfWeek: 4,
        start: '07:10',
        end: '08:30',
        now: now,
      ),
      _schedule(
        title: 'Front-End Web Development',
        dayOfWeek: 4,
        start: '13:10',
        end: '14:30',
        now: now,
      ),
      _schedule(
        title: 'Information System Security',
        dayOfWeek: 4,
        start: '14:40',
        end: '16:00',
        now: now,
      ),

      // Thursday only
      _schedule(
        title: 'Kuliah Umum',
        dayOfWeek: 4,
        start: '10:10',
        end: '11:30',
        now: now,
      ),

      // Friday
      _schedule(
        title: 'Indonesian Civics',
        dayOfWeek: 5,
        start: '13:10',
        end: '15:00',
        now: now,
      ),
      _schedule(
        title: 'Youth and the World',
        dayOfWeek: 5,
        start: '15:10',
        end: '17:00',
        now: now,
      ),
    ];
  }

  static db.Schedule _schedule({
    required String title,
    required int dayOfWeek,
    required String start,
    required String end,
    required DateTime now,
  }) {
    return db.Schedule(
      id: '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_$dayOfWeek',
      title: title,
      type: 'class',
      dayOfWeek: dayOfWeek,
      startTime: start,
      endTime: end,
      repeatType: 'weekly',
      location: null,
      notes: null,
      isActive: 1,
      createdAt: now,
    );
  }
}

/// Activity generation from recurring schedules.
///
/// For each active schedule on [day]'s dayOfWeek, an Activity is created
/// (idempotently via [db.AppDatabase.hasActivityForSchedule]) so restarting
/// the app doesn't produce duplicate entries.
Future<List<db.Activity>> generateActivitiesForDay(
  db.AppDatabase database,
  DateTime day,
) async {
  final dayOfWeek = day.weekday;
  final schedules = await database.getActiveSchedules();
  final targetSchedules = schedules
      .where((s) => s.dayOfWeek == dayOfWeek)
      .toList();

  final created = <db.Activity>[];
  for (final schedule in targetSchedules) {
    final start = _combineDayAndTime(day, schedule.startTime);
    final exists = await database.hasActivityForSchedule(schedule.id, start);
    if (!exists) {
      final activity = db.Activity(
        id: '${schedule.id}_${day.year}_${day.month}_${day.day}',
        scheduleId: schedule.id,
        title: schedule.title,
        category: schedule.type,
        startTime: start,
        endTime: _combineDayAndTime(day, schedule.endTime),
        status: 'scheduled',
        referenceId: null,
        referenceType: null,
        notes: null,
        createdAt: DateTime.now(),
      );
      await database.insertActivity(activity);
      created.add(activity);
    }
  }
  return created;
}

/// Merges a local calendar [day] with a "HH:MM" [time] string and converts
/// the result to the UTC instant drift stores timestamps as. Drift reads
/// timestamps back as local DateTimes, so the local wall-clock time must be
/// preserved as the instant, exactly like `_localStartOfDay` does on the query
/// side: build a local DateTime, then take its UTC instant.
DateTime _combineDayAndTime(DateTime day, String time) {
  final parts = time.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return DateTime(day.year, day.month, day.day, hour, minute).toUtc();
}

/// Seeds the initial university schedule (PRD §5) once, then generates
/// activities for each day in the week containing [now].
///
/// Idempotent: schedules are only inserted when the table is empty and
/// activities are only created when [db.AppDatabase.hasActivityForSchedule]
/// reports none for a schedule/day.
///
/// Concurrent callers share a single in-flight operation so the
/// check-then-insert seed and generation phases can't race (on first launch
/// and at each week rollover both the top-level seeding future and the initial
/// dashboard route run this; a shared lock keeps them from double-inserting
/// and hitting the tables' UNIQUE constraints).
Future<void> ensureSeededAndGenerated(
  db.AppDatabase database, {
  DateTime? now,
}) {
  final inFlight = _seedInFlight;
  if (inFlight != null) {
    return inFlight;
  }
  final reference = now ?? DateTime.now();
  final future = _seedAndGenerate(database, reference).whenComplete(() {
    _seedInFlight = null;
  });
  _seedInFlight = future;
  return future;
}

Future<void>? _seedInFlight;

Future<void> _seedAndGenerate(
  db.AppDatabase database,
  DateTime reference,
) async {
  final existing = await database.getActiveSchedules();
  if (existing.isEmpty) {
    for (final schedule in ScheduleSeeder.initialSchedules()) {
      await database.insertSchedule(schedule);
    }
  }

  final monday = _startOfWeek(reference);
  for (var i = 0; i < 7; i++) {
    final day = DateTime(monday.year, monday.month, monday.day + i);
    await generateActivitiesForDay(database, day);
  }
}

/// Ensures recurring activities exist for [day] when [day] falls in the week
/// containing [now]. Weeks before/after the current one are left untouched so
/// history isn't retroactively populated; they are materialized when they
/// become current (on a fresh launch, dashboard/calendar load, etc.).
Future<void> ensureCurrentWeekActivities(
  db.AppDatabase database,
  DateTime now,
  DateTime day,
) async {
  if (_sameDate(_startOfWeek(day), _startOfWeek(now))) {
    await ensureSeededAndGenerated(database, now: now);
  }
}

DateTime _startOfWeek(DateTime d) {
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
