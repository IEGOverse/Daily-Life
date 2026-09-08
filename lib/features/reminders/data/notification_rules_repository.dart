import 'package:drift/drift.dart';
import 'package:daily_life/core/database/database.dart' as db;

import '../domain/notification_rule.dart';

/// Repository for local notification-rule settings (PRD §13).
///
/// Reads and updates the `notification_rules` table. The table is seeded with
/// defaults on first access so the reminder screen always has rows to render.
class NotificationRulesRepository {
  final db.AppDatabase _database;

  NotificationRulesRepository(this._database);

  /// Returns every rule; seeds default rows on the first read.
  Future<List<NotificationRule>> getRules() async {
    final existing = await _database.getAllNotificationRules();
    final byId = {for (final r in existing) r.ruleId: r};
    final rules = <NotificationRule>[];
    for (final ruleId in ReminderRuleIds.all) {
      final row = byId[ruleId];
      if (row == null) {
        final defaults = NotificationRule.defaultValue(ruleId);
        await _database.upsertNotificationRule(
          ruleId,
          db.NotificationRulesCompanion(
            enabled: Value(defaults.enabled ? 1 : 0),
            minutesBefore: Value(defaults.minutesBefore),
            timeOfDay: Value(defaults.timeOfDay),
          ),
        );
        rules.add(defaults);
      } else {
        rules.add(NotificationRule.fromRow(row));
      }
    }
    return rules;
  }

  Future<NotificationRule?> getRule(String ruleId) async {
    final rows = await getRules();
    for (final rule in rows) {
      if (rule.ruleId == ruleId) return rule;
    }
    return null;
  }

  /// Persists a rule; inserts when it does not exist yet.
  Future<void> saveRule(NotificationRule rule) =>
      _database.upsertNotificationRule(
        rule.ruleId,
        db.NotificationRulesCompanion(
          enabled: Value(rule.enabled ? 1 : 0),
          minutesBefore: Value(rule.minutesBefore),
          timeOfDay: Value(rule.timeOfDay),
        ),
      );
}
