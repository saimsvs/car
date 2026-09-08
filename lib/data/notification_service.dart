import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';

/// Schedules the local notifications that back maintenance reminders.
///
/// Everything is a no-op until [init] succeeds, so widget tests and unsupported
/// platforms can use [AppStore] without a plugin being available.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'cartrack_reminders';
  static const _channelName = 'Maintenance reminders';
  static const _channelDescription =
      'Alerts when a service or renewal is coming due.';

  /// Reminders fire at 9am local time rather than midnight.
  static const _hourOfDay = 9;

  /// How many days before the due date to send a heads-up.
  static const _advanceDays = 3;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  Future<void> init() async {
    if (_ready || !isSupported) return;
    try {
      tz_data.initializeTimeZones();
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName.identifier));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        // Asked for explicitly when the user turns reminders on.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );

      _ready = true;
    } catch (error, stack) {
      debugPrint('Notifications unavailable: $error\n$stack');
    }
  }

  /// Asks the OS for permission to post notifications.
  /// Returns false when the user declines or the platform has no support.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission() ?? false;
        if (granted) {
          // Best effort: without this reminders still arrive, just less precisely.
          await android?.requestExactAlarmsPermission();
        }
        return granted;
      }
      if (Platform.isIOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
      if (Platform.isMacOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    MacOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
      return false;
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
      return false;
    }
  }

  /// Rebuilds every scheduled notification from the current reminder list.
  ///
  /// Called after any reminder change so the OS queue never drifts from the
  /// data the user sees.
  Future<void> syncReminders({
    required List<ReminderItem> reminders,
    required Map<String, String> vehicleNames,
    required bool enabled,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (!enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      for (final reminder in reminders) {
        if (reminder.done) continue;
        final vehicle = vehicleNames[reminder.vehicleId];
        if (vehicle == null) continue;

        final due = tz.TZDateTime(
          tz.local,
          reminder.dueDate.year,
          reminder.dueDate.month,
          reminder.dueDate.day,
          _hourOfDay,
        );

        await _scheduleOne(
          id: _idFor(reminder.id, 0),
          when: due.subtract(const Duration(days: _advanceDays)),
          now: now,
          title: '${reminder.title} due soon',
          body: '$vehicle · due in $_advanceDays days',
        );
        await _scheduleOne(
          id: _idFor(reminder.id, 1),
          when: due,
          now: now,
          title: '${reminder.title} is due today',
          body: '$vehicle · tap to log it',
        );
      }
    } catch (error) {
      debugPrint('Could not sync reminders: $error');
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required tz.TZDateTime when,
    required tz.TZDateTime now,
    required String title,
    required String body,
  }) async {
    if (!when.isAfter(now)) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Posts a notification immediately so the user can confirm delivery works.
  Future<bool> sendTestNotification() async {
    if (!_ready) return false;
    try {
      await _plugin.show(
        id: 0x7FFFFFFF,
        title: 'Reminders are on',
        body: 'This is how a maintenance alert will look.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
      return true;
    } catch (error) {
      debugPrint('Test notification failed: $error');
      return false;
    }
  }

  Future<int> pendingCount() async {
    if (!_ready) return 0;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.length;
    } catch (error) {
      return 0;
    }
  }

  /// Two stable, distinct ids per reminder: the heads-up and the due-date alert.
  int _idFor(String reminderId, int slot) =>
      ((reminderId.hashCode & 0x3FFFFFFF) << 1) | slot;
}
