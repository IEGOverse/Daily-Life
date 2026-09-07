import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Schedules,
    Activities,
    Habits,
    HabitLogs,
    Exercises,
    WorkoutPlans,
    WorkoutPlanExercises,
    WorkoutSessions,
    WorkoutSetLogs,
    StudySessions,
    StudyTopics,
    Transactions,
    Foods,
    Meals,
    MealFoods,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'daily_life'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 1) {
        await m.createAll();
      }
    },
  );

  Future<List<Schedule>> getAllSchedules() => select(schedules).get();
  Future<List<Schedule>> getSchedulesByDay(int dayOfWeek) =>
      (select(schedules)..where((t) => t.dayOfWeek.equals(dayOfWeek))).get();
  Future<void> insertSchedule(Schedule schedule) =>
      into(schedules).insert(schedule);
  Future<void> updateSchedule(String id, Schedule schedule) =>
      (schedules.update()..where((t) => t.id.equals(id))).write(schedule);
  Future<void> deleteSchedule(String id) =>
      (delete(schedules)..where((t) => t.id.equals(id))).go();

  Future<List<Activity>> getAllActivities() => select(activities).get();
  Future<List<Activity>> getActivitiesByStatus(String status) =>
      (select(activities)..where((t) => t.status.equals(status))).get();
  Future<void> insertActivity(Activity activity) =>
      into(activities).insert(activity);
  Future<void> updateActivity(String id, Activity activity) =>
      (activities.update()..where((t) => t.id.equals(id))).write(activity);
  Future<void> deleteActivity(String id) =>
      (delete(activities)..where((t) => t.id.equals(id))).go();
}

class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  IntColumn get dayOfWeek => integer()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get repeatType => text()();
  TextColumn get location => text()();
  TextColumn get notes => text()();
  IntColumn get isActive => integer().withDefault(Constant(1))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get scheduleId => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get status => text()();
  TextColumn get referenceId => text()();
  TextColumn get referenceType => text()();
  TextColumn get notes => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get frequency => text()();
  IntColumn get target => integer()();
  IntColumn get isActive => integer().withDefault(Constant(1))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get completed => integer().withDefault(Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get description => text()();
  TextColumn get instructions => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutPlans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get dayLabel => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutPlanExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutPlanId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get sets => integer()();
  IntColumn get reps => integer()();
  IntColumn get restSeconds => integer()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get workoutPlanId => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get durationSeconds => integer()();
  IntColumn get completed => integer().withDefault(Constant(0))();
  TextColumn get notes => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSetLogs extends Table {
  TextColumn get id => text()();
  TextColumn get workoutSessionId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();
  RealColumn get weight => real()();
  IntColumn get completed => integer().withDefault(Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class StudySessions extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get durationSeconds => integer()();
  IntColumn get understanding => integer()();
  TextColumn get notes => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class StudyTopics extends Table {
  TextColumn get id => text()();
  TextColumn get studySessionId => text()();
  TextColumn get topic => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get category => text()();
  IntColumn get amount => integer()();
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Foods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get servingSize => real()();
  TextColumn get servingUnit => text()();
  RealColumn get calories => real()();
  RealColumn get protein => real()();
  RealColumn get carbohydrate => real()();
  RealColumn get fat => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class Meals extends Table {
  TextColumn get id => text()();
  TextColumn get mealType => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get time => dateTime()();
  TextColumn get notes => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class MealFoods extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text()();
  TextColumn get foodId => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();

  @override
  Set<Column> get primaryKey => {id};
}
