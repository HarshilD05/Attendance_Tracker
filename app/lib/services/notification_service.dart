import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _reminderId = 42;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(settings: initSettings);

    // Request Android 13+ notification permission
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Schedule (or reschedule) the attendance reminder at [scheduledTime].
  /// If [scheduledTime] is in the past or within the next 2 minutes, this is a no-op.
  Future<void> scheduleAttendanceReminder(DateTime scheduledTime) async {
    final now = DateTime.now();
    if (scheduledTime.isBefore(now.add(const Duration(minutes: 2)))) return;

    await _plugin.cancel(id: _reminderId);

    const androidDetails = AndroidNotificationDetails(
      'attendance_reminder',
      'Attendance Reminders',
      channelDescription: 'Reminds you to fill in your daily attendance',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id: _reminderId,
      title: '📋 Mark Today\'s Attendance',
      body: 'Your last class ended. Don\'t forget to fill in today\'s attendance!',
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('[NotificationService] Reminder scheduled for $tzScheduled');
  }

  /// Cancel any pending attendance reminder.
  Future<void> cancelAttendanceReminder() async {
    await _plugin.cancel(id: _reminderId);
    debugPrint('[NotificationService] Reminder cancelled');
  }
}
