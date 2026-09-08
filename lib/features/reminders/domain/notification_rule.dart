import '../../../core/database/database.dart' as db;

/// Stable rule ids used by the reminder scheduler (PRD §13).
abstract final class ReminderRuleIds {
  /// 'N minutes before a scheduled activity' reminder.
  static const activity = 'activity';

  /// Fixed daily 'time to review habits' reminder.
  static const habit = 'habit';

  /// Fixed daily 'time to record finance' reminder.
  static const finance = 'finance';

  static const all = [activity, habit, finance];
}

/// A configurable local reminder rule.
///
/// The rule only configures the LOCAL notification service; none of these
/// values leave the device (PRD §15).
class NotificationRule {
  final String ruleId;
  final bool enabled;

  /// Lead time in minutes before a scheduled activity ([activity] rule).
  final int minutesBefore;

  /// "HH:mm" local time for fixed daily reminders ([habit]/[finance] rules).
  final String? timeOfDay;

  const NotificationRule({
    required this.ruleId,
    required this.enabled,
    this.minutesBefore = 15,
    this.timeOfDay,
  });

  factory NotificationRule.fromRow(db.NotificationRule row) => NotificationRule(
    ruleId: row.ruleId,
    enabled: row.enabled == 1,
    minutesBefore: row.minutesBefore,
    timeOfDay: row.timeOfDay,
  );

  /// Default configuration, used to seed an empty rules table.
  static NotificationRule defaultValue(String ruleId) {
    switch (ruleId) {
      case ReminderRuleIds.activity:
        return const NotificationRule(
          ruleId: ReminderRuleIds.activity,
          enabled: true,
          minutesBefore: 15,
        );
      case ReminderRuleIds.habit:
        return const NotificationRule(
          ruleId: ReminderRuleIds.habit,
          enabled: true,
          timeOfDay: '20:00',
        );
      case ReminderRuleIds.finance:
        return const NotificationRule(
          ruleId: ReminderRuleIds.finance,
          enabled: true,
          timeOfDay: '21:00',
        );
    }
    throw ArgumentError.value(ruleId, 'ruleId', 'Unknown reminder rule');
  }
}
