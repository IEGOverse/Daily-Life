import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A reminder to hand to the local notification service.
class PendingReminder {
  final int id;
  final String title;
  final String body;

  /// For one-shot reminders, the exact local time to fire at.
  final DateTime? scheduledAt;

  /// For fixed daily reminders, the local "HH:mm" trigger time.
  final String? timeOfDay;

  const PendingReminder.oneShot({
    required this.id,
    required this.title,
    required this.body,
    required DateTime when,
  }) : scheduledAt = when,
       timeOfDay = null;

  const PendingReminder.daily({
    required this.id,
    required this.title,
    required this.body,
    required String time,
  }) : scheduledAt = null,
       timeOfDay = time;
}

/// Thin wrapper around [FlutterLocalNotificationsPlugin].
///
/// All platform calls are guarded so the app and its tests work on every
/// host: initialization is idempotent, every method no-ops unless the plugin
/// is actually available, and any platform exception is swallowed. Widget
/// tests never touch real notifications.
class NotificationService {
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _checkedNoop = false;

  NotificationService._();

  /// Widget tests and non-Android hosts never touch the real plugin.
  bool get _isDevice => Platform.isAndroid;

  /// Initializes the plugin (idempotent). Safe to call from app startup.
  Future<void> init() async {
    if (_ready || _checkedNoop) return;
    _checkedNoop = true;
    if (!_isDevice) return;

    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        if (info.identifier.isNotEmpty) {
          tz.setLocalLocation(tz.getLocation(info.identifier));
        }
      } catch (_) {
        // Keep tz.local defaults when the timezone look-up fails.
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      // Plugin not available on this host; leave _ready false.
    }
  }

  /// Cancels previously scheduled (pending) notifications.
  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (_) {}
  }

  /// Schedules [reminders]. One-shot reminders fire at [PendingReminder.scheduledAt];
  /// daily reminders repeat every day at [PendingReminder.timeOfDay].
  Future<void> schedule(List<PendingReminder> reminders) async {
    if (!_ready) return;
    for (final reminder in reminders) {
      try {
        await _scheduleOne(reminder);
      } catch (_) {
        // Skip reminders the platform refuses without failing the batch.
      }
    }
  }

  Future<void> _scheduleOne(PendingReminder reminder) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_life_reminders',
        'Daily Life reminders',
        channelDescription:
            'Reminders for scheduled activities, habits and finance.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    if (reminder.timeOfDay != null) {
      final now = tz.TZDateTime.now(tz.local);
      final parts = reminder.timeOfDay!.split(':');
      var when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return;
    }

    final at = reminder.scheduledAt;
    if (at == null || !at.isAfter(DateTime.now())) return;
    final when = tz.TZDateTime.from(at, tz.local);
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
