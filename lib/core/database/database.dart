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
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'daily_life'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // v1 was a pre-release development schema. v2 fixes nullability and
        // adds foreign-key declarations. Recreating is safe pre-release.
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
      }
    },
  );

  // --- Schedules ----------------------------------------------------------
  Future<List<Schedule>> getAllSchedules() => select(schedules).get();
  Future<List<Schedule>> getSchedulesByDay(int dayOfWeek) =>
      (select(schedules)..where((t) => t.dayOfWeek.equals(dayOfWeek))).get();
  Future<List<Schedule>> getActiveSchedules() =>
      (select(schedules)..where((t) => t.isActive.equals(1))).get();
  Future<Schedule?> getScheduleById(String id) =>
      (select(schedules)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> insertSchedule(Schedule schedule) =>
      into(schedules).insert(schedule);
  Future<void> updateSchedule(String id, Schedule schedule) =>
      (schedules.update()..where((t) => t.id.equals(id))).write(schedule);
  Future<void> deleteSchedule(String id) =>
      (delete(schedules)..where((t) => t.id.equals(id))).go();

  // --- Activities ---------------------------------------------------------
  Future<List<Activity>> getAllActivities() => select(activities).get();
  Future<List<Activity>> getActivitiesByStatus(String status) =>
      (select(activities)..where((t) => t.status.equals(status))).get();
  Future<Activity?> getActivityById(String id) =>
      (select(activities)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> insertActivity(Activity activity) =>
      into(activities).insert(activity);
  Future<void> updateActivity(String id, Activity activity) =>
      (activities.update()..where((t) => t.id.equals(id))).write(activity);
  Future<void> deleteActivity(String id) =>
      (delete(activities)..where((t) => t.id.equals(id))).go();

  /// Whether an activity already exists for [scheduleId] starting at
  /// [start]. Used to keep recurrent activity generation idempotent across
  /// restarts.
  Future<bool> hasActivityForSchedule(String scheduleId, DateTime start) async {
    final matches =
        await (select(activities)..where(
              (t) =>
                  t.scheduleId.equals(scheduleId) & t.startTime.equals(start),
            ))
            .get();
    return matches.isNotEmpty;
  }

  /// Returns activities whose start time falls within the local day [day].
  ///
  /// Drift stores date times normalized to UTC. These queries therefore build
  /// their boundaries from the local start/end of the requested day, converted
  /// to UTC, so matching is correct regardless of the device time zone.
  Future<List<Activity>> getActivitiesForDay(DateTime day) async {
    final start = _localStartOfDay(day);
    final end = _localStartOfDay(day.add(const Duration(days: 1)));
    return (select(activities)
          ..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(start) &
                t.startTime.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  /// Returns activities with start time in [startInclusive, endExclusive),
  /// ordered by start time. Boundaries are interpreted as local and converted
  /// to UTC for storage comparison.
  Future<List<Activity>> getActivitiesForRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return (select(activities)
          ..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(startInclusive.toUtc()) &
                t.startTime.isSmallerThanValue(endExclusive.toUtc()),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  Future<List<Activity>> getActivitiesForSchedule(String scheduleId) =>
      (select(activities)..where((t) => t.scheduleId.equals(scheduleId))).get();

  Future<void> setActivityStatus(String id, String status) async {
    await (activities.update()..where((t) => t.id.equals(id))).write(
      ActivitiesCompanion(status: Value(status)),
    );
  }

  // --- Exercises (workout library) ----------------------------------------
  Future<List<Exercise>> getAllExercises() =>
      (select(exercises)..orderBy([
            (t) => OrderingTerm.asc(t.muscleGroup),
            (t) => OrderingTerm.asc(t.name),
          ]))
          .get();
  Future<Exercise?> getExerciseById(String id) =>
      (select(exercises)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) =>
      (select(
        exercises,
      )..where((t) => t.muscleGroup.equals(muscleGroup))).get();
  Future<void> insertExercise(Exercise exercise) =>
      into(exercises).insert(exercise);
  Future<void> deleteExercise(String id) =>
      (delete(exercises)..where((t) => t.id.equals(id))).go();

  // --- Workout plans ------------------------------------------------------
  Future<List<WorkoutPlan>> getAllWorkoutPlans() =>
      (select(workoutPlans)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  Future<WorkoutPlan?> getWorkoutPlanById(String id) =>
      (select(workoutPlans)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> insertWorkoutPlan(WorkoutPlan plan) =>
      into(workoutPlans).insert(plan);
  Future<void> deleteWorkoutPlan(String id) =>
      (delete(workoutPlans)..where((t) => t.id.equals(id))).go();
  Future<List<WorkoutPlanExercise>> getWorkoutPlanExercises(String planId) =>
      (select(workoutPlanExercises)
            ..where((t) => t.workoutPlanId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
  Future<void> insertWorkoutPlanExercise(WorkoutPlanExercise exercise) =>
      into(workoutPlanExercises).insert(exercise);
  Future<void> deleteWorkoutPlanExercises(String planId) => (delete(
    workoutPlanExercises,
  )..where((t) => t.workoutPlanId.equals(planId))).go();

  // --- Workout sessions ---------------------------------------------------
  Future<List<WorkoutSession>> getAllWorkoutSessions() => (select(
    workoutSessions,
  )..orderBy([(t) => OrderingTerm.desc(t.startTime)])).get();
  Future<WorkoutSession?> getWorkoutSessionById(String id) => (select(
    workoutSessions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<List<WorkoutSession>> getWorkoutSessionsForPlan(String planId) =>
      (select(workoutSessions)
            ..where((t) => t.workoutPlanId.equals(planId))
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
          .get();
  Future<void> insertWorkoutSession(WorkoutSession session) =>
      into(workoutSessions).insert(session);
  Future<void> completeWorkoutSession(
    String id,
    DateTime endTime,
    int durationSeconds,
  ) => (workoutSessions.update()..where((t) => t.id.equals(id))).write(
    WorkoutSessionsCompanion(
      endTime: Value(endTime),
      durationSeconds: Value(durationSeconds),
      completed: const Value(1),
    ),
  );

  // --- Study sessions -----------------------------------------------------
  Future<List<StudySession>> getAllStudySessions() => (select(
    studySessions,
  )..orderBy([(t) => OrderingTerm.desc(t.startTime)])).get();
  Future<StudySession?> getStudySessionById(String id) =>
      (select(studySessions)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> insertStudySession(StudySession session) =>
      into(studySessions).insert(session);
  Future<void> updateStudySession(String id, StudySessionsCompanion values) =>
      (studySessions.update()..where((t) => t.id.equals(id))).write(values);
  Future<void> deleteStudySession(String id) =>
      (delete(studySessions)..where((t) => t.id.equals(id))).go();

  // --- Study topics -----------------------------------------------------
  Future<List<StudyTopic>> getAllStudyTopics() => (select(studyTopics)).get();
  Future<StudyTopic?> getStudyTopicById(String id) =>
      (select(studyTopics)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> insertStudyTopic(StudyTopic topic) =>
      into(studyTopics).insert(topic);
  Future<void> updateStudyTopic(String id, StudyTopicsCompanion values) =>
      (studyTopics.update()..where((t) => t.id.equals(id))).write(values);
  Future<void> deleteStudyTopic(String id) =>
      (delete(studyTopics)..where((t) => t.id.equals(id))).go();

  // --- Workout set logs ---------------------------------------------------
  Future<List<WorkoutSetLog>> getWorkoutSetLogs(String sessionId) =>
      (select(workoutSetLogs)
            ..where((t) => t.workoutSessionId.equals(sessionId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.exerciseId),
              (t) => OrderingTerm.asc(t.setNumber),
            ]))
          .get();
  Future<List<WorkoutSetLog>> getAllWorkoutSetLogs() =>
      select(workoutSetLogs).get();
  Future<void> insertWorkoutSetLog(WorkoutSetLog log) =>
      into(workoutSetLogs).insert(log);
  Future<void> updateWorkoutSetLog(
    String id,
    int reps,
    double? weight,
    bool completed,
  ) => (workoutSetLogs.update()..where((t) => t.id.equals(id))).write(
    WorkoutSetLogsCompanion(
      reps: Value(reps),
      weight: Value(weight),
      completed: Value(completed ? 1 : 0),
    ),
  );

  // --- Transactions -------------------------------------------------------
  Future<List<Transaction>> getAllTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> insertTransaction(Transaction transaction) =>
      into(transactions).insert(transaction);
  Future<void> updateTransaction(String id, TransactionsCompanion values) =>
      (transactions.update()..where((t) => t.id.equals(id))).write(values);
  Future<void> deleteTransaction(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();
  Future<List<Transaction>> getTransactionsForDay(DateTime day) async {
    final start = _localStartOfDay(day);
    final end = _localStartOfDay(day.add(const Duration(days: 1)));
    return (select(transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getTransactionsForRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return (select(transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(startInclusive.toUtc()) &
                t.date.isSmallerThanValue(endExclusive.toUtc()),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  // --- Nutrition: Foods ---------------------------------------------------
  Future<List<Food>> getAllFoods() =>
      (select(foods)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  Future<Food?> getFoodById(String id) =>
      (select(foods)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> insertFood(Food food) => into(foods).insert(food);

  // --- Nutrition: Meals ---------------------------------------------------
  Future<List<Meal>> getAllMeals() => (select(meals)).get();
  Future<List<Meal>> getMealsForDay(DateTime day) async {
    final start = _localStartOfDay(day);
    final end = _localStartOfDay(day.add(const Duration(days: 1)));
    return (select(meals)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.time)]))
        .get();
  }

  Future<Meal?> getMealById(String id) =>
      (select(meals)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> insertMeal(Meal meal) => into(meals).insert(meal);
  Future<void> deleteMeal(String id) =>
      (delete(meals)..where((t) => t.id.equals(id))).go();

  // --- Nutrition: Meal foods ----------------------------------------------
  Future<List<MealFood>> getMealFoods(String mealId) =>
      (select(mealFoods)..where((t) => t.mealId.equals(mealId))).get();
  Future<void> insertMealFood(MealFood mealFood) =>
      into(mealFoods).insert(mealFood);
  Future<void> deleteMealFoods(String mealId) =>
      (delete(mealFoods)..where((t) => t.mealId.equals(mealId))).go();

  DateTime _localStartOfDay(DateTime day) =>
      DateTime(day.year, day.month, day.day).toUtc();
}

class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  IntColumn get dayOfWeek => integer()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get repeatType => text()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get isActive => integer().withDefault(Constant(1))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get scheduleId => text().nullable().references(Schedules, #id)();
  TextColumn get title => text()();
  TextColumn get category => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get referenceType => text().nullable()();
  TextColumn get notes => text().nullable()();
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
  TextColumn get habitId => text().references(Habits, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get completed => integer().withDefault(Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get description => text().nullable()();
  TextColumn get instructions => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutPlans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get dayLabel => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutPlanExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutPlanId => text().references(WorkoutPlans, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get sets => integer()();
  IntColumn get reps => integer()();
  IntColumn get restSeconds => integer().nullable()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get workoutPlanId => text().references(WorkoutPlans, #id)();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get completed => integer().withDefault(Constant(0))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSetLogs extends Table {
  TextColumn get id => text()();
  TextColumn get workoutSessionId => text().references(WorkoutSessions, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();
  RealColumn get weight => real().nullable()();
  IntColumn get completed => integer().withDefault(Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class StudySessions extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get understanding => integer().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class StudyTopics extends Table {
  TextColumn get id => text()();
  TextColumn get studySessionId => text().references(StudySessions, #id)();
  TextColumn get topic => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get category => text()();
  IntColumn get amount => integer()();
  TextColumn get description => text().nullable()();
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
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MealFoods extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text().references(Meals, #id)();
  TextColumn get foodId => text().references(Foods, #id)();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();

  @override
  Set<Column> get primaryKey => {id};
}
