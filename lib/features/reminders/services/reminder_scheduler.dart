import '../../activities/domain/activity.dart';
import '../../activities/domain/activity_status.dart';
import '../domain/notification_rule.dart';
import 'notification_service.dart';

/// Id prefix reserved for daily fixed reminders (id must be an int for the
/// plugin). One-shot ids are derived from the activity id.
abstract final class ReminderIds {
  static const habit = 9100;
  static const finance = 9200;
}

/// Computes which LOCAL reminders to schedule for [now]'s day from the current
/// rules and the day's activities (PRD §13 examples: upcoming activity/workout/
/// study, habit reminder, finance recording reminder).
class ReminderScheduler {
  ReminderScheduler(this._service);

  final NotificationService _service;

  /// Reschedules all reminders. Call after the day's activities are known and
  /// after any rule change.
  Future<void> refresh(
    DateTime now,
    List<Activity> activities,
    List<NotificationRule> rules,
  ) async {
    await _service.init();
    await _service.cancelAll();
    final reminders = buildReminders(now, activities, rules);
    await _service.schedule(reminders);
  }

  /// Pure decision step, kept separate for unit tests.
  List<PendingReminder> buildReminders(
    DateTime now,
    List<Activity> activities,
    List<NotificationRule> rules,
  ) {
    final reminders = <PendingReminder>[];

    final activityRule = rules
        .where((r) => r.ruleId == ReminderRuleIds.activity)
        .cast<NotificationRule?>()
        .firstWhere((r) => true, orElse: () => null);
    if (activityRule?.enabled ?? true) {
      final lead = Duration(minutes: activityRule?.minutesBefore ?? 15);
      final upcoming = activities.where((a) {
        return a.status == ActivityStatus.scheduled &&
            a.startTime.isAfter(now.add(lead));
      });
      for (final activity in upcoming) {
        reminders.add(
          PendingReminder.oneShot(
            id: activity.id.hashCode,
            title: 'Segera: ${activity.title}',
            body: _categoryHint(activity),
            when: activity.startTime.subtract(lead),
          ),
        );
      }
    }

    final habitRule = rules
        .where((r) => r.ruleId == ReminderRuleIds.habit)
        .cast<NotificationRule?>()
        .firstWhere((r) => true, orElse: () => null);
    if (habitRule?.enabled ?? false) {
      final time = habitRule?.timeOfDay ?? '20:00';
      reminders.add(
        PendingReminder.daily(
          id: ReminderIds.habit,
          title: 'Waktu kebiasaan',
          body: 'Luangkan waktu untuk menyelesaikan kebiasaan hari ini.',
          time: time,
        ),
      );
    }

    final financeRule = rules
        .where((r) => r.ruleId == ReminderRuleIds.finance)
        .cast<NotificationRule?>()
        .firstWhere((r) => true, orElse: () => null);
    if (financeRule?.enabled ?? false) {
      final time = financeRule?.timeOfDay ?? '21:00';
      reminders.add(
        PendingReminder.daily(
          id: ReminderIds.finance,
          title: 'Catat hari Anda',
          body: 'Catat transaksi hari ini sebelum hari berakhir.',
          time: time,
        ),
      );
    }

    return reminders;
  }

  String _categoryHint(Activity activity) {
    switch (activity.category.trim().toLowerCase()) {
      case 'workout':
      case 'exercise':
        return 'Olahraga Anda akan segera dimulai.';
      case 'study':
        return 'Sesi belajar Anda akan segera dimulai.';
      default:
        return 'Dimulai pada ${_formatTime(activity.startTime)}.';
    }
  }

  String _formatTime(DateTime t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
