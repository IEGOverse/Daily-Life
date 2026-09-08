import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/features/activities/domain/activity.dart';
import 'package:daily_life/features/activities/domain/activity_status.dart';
import 'package:daily_life/features/reminders/data/notification_rules_repository.dart';
import 'package:daily_life/features/reminders/domain/notification_rule.dart';
import 'package:daily_life/features/reminders/services/notification_service.dart';
import 'package:daily_life/features/reminders/services/reminder_scheduler.dart';

void main() {
  group('ReminderScheduler.buildReminders', () {
    final now = DateTime(2026, 9, 8, 8);
    final scheduler = ReminderScheduler(NotificationService.instance);

    List<Activity> activities() => [
      Activity(
        id: 'a1',
        title: 'Lecture',
        category: 'study',
        startTime: DateTime(2026, 9, 8, 11),
        status: ActivityStatus.scheduled,
      ),
      Activity(
        id: 'a2',
        title: 'Past workout',
        category: 'workout',
        startTime: DateTime(2026, 9, 8, 7),
        status: ActivityStatus.scheduled,
      ),
    ];

    List<NotificationRule> defaultRules() => [
      NotificationRule.defaultValue(ReminderRuleIds.activity),
      NotificationRule.defaultValue(ReminderRuleIds.habit),
      NotificationRule.defaultValue(ReminderRuleIds.finance),
    ];

    test('schedules one reminder per upcoming activity with lead time', () {
      final reminders = scheduler.buildReminders(
        now,
        activities(),
        defaultRules(),
      );

      // a1 (11:00) with 15-min lead → one-shot at 10:45.
      // a2 is already in the past → no reminder.
      final activityReminders = reminders.where((r) => r.timeOfDay == null);
      expect(activityReminders, hasLength(1));
      final reminder = activityReminders.first;
      expect(reminder.scheduledAt, DateTime(2026, 9, 8, 10, 45));
      expect(reminder.title, 'Upcoming: Lecture');
    });

    test('uses the configured lead minutes', () {
      final reminders = scheduler.buildReminders(
        now,
        [activities().first],
        [
          const NotificationRule(
            ruleId: ReminderRuleIds.activity,
            enabled: true,
            minutesBefore: 120,
          ),
        ],
      );
      // 11:00 - 2h = 09:00, still after now (08:00) → scheduled at 09:00.
      expect(reminders, hasLength(1));
      expect(reminders.first.scheduledAt, DateTime(2026, 9, 8, 9));
    });

    test('habit and finance rules produce daily reminders', () {
      final reminders = scheduler.buildReminders(now, const [], defaultRules());

      final daily = reminders.where((r) => r.timeOfDay != null).toList();
      expect(daily, hasLength(2));
      expect(daily.any((r) => r.id == ReminderIds.habit), isTrue);
      expect(daily.any((r) => r.id == ReminderIds.finance), isTrue);

      final habit = daily.firstWhere((r) => r.id == ReminderIds.habit);
      expect(habit.timeOfDay, '20:00');
      expect(habit.title, 'Habit time');
    });

    test('disabled rules produce no reminders', () {
      final rules = [
        const NotificationRule(
          ruleId: ReminderRuleIds.activity,
          enabled: false,
        ),
        const NotificationRule(ruleId: ReminderRuleIds.habit, enabled: false),
        const NotificationRule(ruleId: ReminderRuleIds.finance, enabled: false),
      ];
      final reminders = scheduler.buildReminders(now, activities(), rules);
      expect(reminders, isEmpty);
    });

    test('missing rules default activity enabled, daily reminders off', () {
      final reminders = scheduler.buildReminders(now, activities(), const []);
      // Activity lead defaults to 15 min but only fires for upcoming items;
      // habit/finance are off by default when no rule row exists.
      expect(reminders, hasLength(1));
      expect(reminders.first.timeOfDay, isNull);
    });
  });

  group('NotificationRulesRepository', () {
    test('seeds default rules on first read', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repo = NotificationRulesRepository(database);

      final rules = await repo.getRules();
      expect(rules, hasLength(3));
      final activity = rules.firstWhere(
        (r) => r.ruleId == ReminderRuleIds.activity,
      );
      expect(activity.enabled, isTrue);
      expect(activity.minutesBefore, 15);
      final habit = rules.firstWhere((r) => r.ruleId == ReminderRuleIds.habit);
      expect(habit.timeOfDay, '20:00');
    });

    test('saveRule persists changes and getRule returns them', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repo = NotificationRulesRepository(database);

      await repo.saveRule(
        const NotificationRule(
          ruleId: ReminderRuleIds.activity,
          enabled: false,
          minutesBefore: 30,
        ),
      );

      final rule = await repo.getRule(ReminderRuleIds.activity);
      expect(rule, isNotNull);
      expect(rule!.enabled, isFalse);
      expect(rule.minutesBefore, 30);
    });

    test(
      'defaults persist to the database (not stored back in memory only)',
      () async {
        final database = db.AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final repo = NotificationRulesRepository(database);

        await repo.getRules();
        final rows = await database.getAllNotificationRules();
        expect(rows, hasLength(3));
      },
    );
  });
}
