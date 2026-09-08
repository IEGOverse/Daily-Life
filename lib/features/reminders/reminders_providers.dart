import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../activities/activity_providers.dart';
import '../dashboard/dashboard_providers.dart' show clockProvider;
import 'data/notification_rules_repository.dart';
import 'domain/notification_rule.dart';
import 'services/notification_service.dart';
import 'services/reminder_scheduler.dart';

final notificationRulesRepositoryProvider =
    Provider<NotificationRulesRepository>(
      (ref) => NotificationRulesRepository(ref.watch(databaseProvider)),
    );

/// All reminder rules (seeded with defaults on first read).
final reminderRulesProvider = FutureProvider<List<NotificationRule>>((ref) {
  return ref.watch(notificationRulesRepositoryProvider).getRules();
});

/// Local notification service. Kept as a provider so tests can substitute a
/// no-op implementation.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(ref.watch(notificationServiceProvider)),
);

/// RefreshVisible reminders for today's activities + rules.
/// Loads the day's activities (materializing the current week if needed),
/// reads the rules, and reschedules local notifications. No-ops safely in
/// tests and on non-Android hosts.
final refreshRemindersProvider = FutureProvider<void>((ref) async {
  final now = ref.read(clockProvider);
  final activities = await ref.read(activitiesForDayProvider(now).future);
  final rules = await ref.read(reminderRulesProvider.future);
  final scheduler = ref.read(reminderSchedulerProvider);
  await scheduler.refresh(now, activities, rules);
});

/// Watches the reminder-refresh future. Safe to call from a widget's build
/// method: the first watch triggers the refresh; subsequent watches are
/// no-ops. Only schedules when a real notification backend is available.
void useReminders(WidgetRef ref) {
  ref.watch(refreshRemindersProvider);
}
