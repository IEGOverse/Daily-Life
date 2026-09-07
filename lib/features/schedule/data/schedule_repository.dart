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
/// the result to UTC for drift storage.
DateTime _combineDayAndTime(DateTime day, String time) {
  final parts = time.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return DateTime.utc(day.year, day.month, day.day, hour, minute);
}
