import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/notification_rule.dart';
import 'reminders_providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(reminderRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Failed to load reminders.')),
        data: (rules) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _RuleCard(
              ruleId: ReminderRuleIds.activity,
              icon: Icons.schedule,
              title: 'Upcoming activities',
              subtitle: 'Remind before a scheduled activity starts',
              enabled: _enabled(rules, ReminderRuleIds.activity),
              onChanged: (value) =>
                  _setEnabled(ref, ReminderRuleIds.activity, value),
              valueWidget: _LeadTimeSelektor(
                minutes: _minutes(rules, ReminderRuleIds.activity),
                onChanged: (minutes) =>
                    _setMinutes(ref, ReminderRuleIds.activity, minutes),
              ),
            ),
            const SizedBox(height: 8),
            _RuleCard(
              ruleId: ReminderRuleIds.habit,
              icon: Icons.check_circle_outline,
              title: 'Habit reminders',
              subtitle: 'Daily reminder to complete your habits',
              enabled: _enabled(rules, ReminderRuleIds.habit),
              onChanged: (value) =>
                  _setEnabled(ref, ReminderRuleIds.habit, value),
              valueWidget: _TimeSelektor(
                time: _time(rules, ReminderRuleIds.habit) ?? '20:00',
                onChanged: (time) => _setTime(ref, ReminderRuleIds.habit, time),
              ),
            ),
            const SizedBox(height: 8),
            _RuleCard(
              ruleId: ReminderRuleIds.finance,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Finance recording',
              subtitle: 'Daily reminder to record transactions',
              enabled: _enabled(rules, ReminderRuleIds.finance),
              onChanged: (value) =>
                  _setEnabled(ref, ReminderRuleIds.finance, value),
              valueWidget: _TimeSelektor(
                time: _time(rules, ReminderRuleIds.finance) ?? '21:00',
                onChanged: (time) =>
                    _setTime(ref, ReminderRuleIds.finance, time),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reminders are scheduled locally on this device and never '
              'leave it.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }

  bool _enabled(List<NotificationRule> rules, String id) =>
      rules.any((r) => r.ruleId == id && r.enabled);

  int _minutes(List<NotificationRule> rules, String id) {
    for (final r in rules) {
      if (r.ruleId == id) return r.minutesBefore;
    }
    return 15;
  }

  String? _time(List<NotificationRule> rules, String id) {
    for (final r in rules) {
      if (r.ruleId == id) return r.timeOfDay;
    }
    return null;
  }

  Future<void> _setEnabled(WidgetRef ref, String id, bool value) async {
    final repo = ref.read(notificationRulesRepositoryProvider);
    final rules = await ref.read(reminderRulesProvider.future);
    NotificationRule current = NotificationRule.defaultValue(id);
    for (final r in rules) {
      if (r.ruleId == id) {
        current = r;
        break;
      }
    }
    await repo.saveRule(
      NotificationRule(
        ruleId: id,
        enabled: value,
        minutesBefore: current.minutesBefore,
        timeOfDay: current.timeOfDay,
      ),
    );
    ref.invalidate(reminderRulesProvider);
    ref.invalidate(refreshRemindersProvider);
  }

  Future<void> _setMinutes(WidgetRef ref, String id, int minutes) async {
    final repo = ref.read(notificationRulesRepositoryProvider);
    final rules = await ref.read(reminderRulesProvider.future);
    NotificationRule current = NotificationRule.defaultValue(id);
    for (final r in rules) {
      if (r.ruleId == id) {
        current = r;
        break;
      }
    }
    await repo.saveRule(
      NotificationRule(
        ruleId: id,
        enabled: current.enabled,
        minutesBefore: minutes,
        timeOfDay: current.timeOfDay,
      ),
    );
    ref.invalidate(reminderRulesProvider);
    ref.invalidate(refreshRemindersProvider);
  }

  Future<void> _setTime(WidgetRef ref, String id, String time) async {
    final repo = ref.read(notificationRulesRepositoryProvider);
    final rules = await ref.read(reminderRulesProvider.future);
    NotificationRule current = NotificationRule.defaultValue(id);
    for (final r in rules) {
      if (r.ruleId == id) {
        current = r;
        break;
      }
    }
    await repo.saveRule(
      NotificationRule(
        ruleId: id,
        enabled: current.enabled,
        minutesBefore: current.minutesBefore,
        timeOfDay: time,
      ),
    );
    ref.invalidate(reminderRulesProvider);
    ref.invalidate(refreshRemindersProvider);
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.ruleId,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
    required this.valueWidget,
  });

  final String ruleId;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final Widget valueWidget;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: Switch(value: enabled, onChanged: onChanged),
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: valueWidget,
            ),
        ],
      ),
    );
  }
}

class _LeadTimeSelektor extends StatelessWidget {
  const _LeadTimeSelektor({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Remind me',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        DropdownButton<int>(
          value: minutes,
          items: [
            for (final m in const [5, 10, 15, 30, 60])
              DropdownMenuItem(value: m, child: Text('$m min before')),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _TimeSelektor extends StatelessWidget {
  const _TimeSelektor({required this.time, required this.onChanged});

  final String time;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Time', style: Theme.of(context).textTheme.bodyMedium),
        ),
        TextButton.icon(
          onPressed: () async {
            final parts = time.split(':');
            final initial = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
            );
            if (picked == null) return;
            final value =
                '${picked.hour.toString().padLeft(2, '0')}:'
                '${picked.minute.toString().padLeft(2, '0')}';
            onChanged(value);
          },
          icon: const Icon(Icons.access_time),
          label: Text(time),
        ),
      ],
    );
  }
}
