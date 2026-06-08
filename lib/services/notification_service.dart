import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:intl/intl.dart'; // додади го import-от


/*class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    // Земаме локален timezone од системот (пример: "Europe/Skopje")
    final localTzName = DateTime.now().timeZoneName;

    // На некои уреди враќа кратенки (CET/CEST). Ако не е валидно,
    // само ставаме UTC за да не падне апликацијата.
    try {
      tz.setLocalLocation(tz.getLocation(localTzName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    _initialized = true;
  }

  // Идентификатор за notification (мора да е int)
  int _idFromString(String s) {
    // стабилно, без да е огромно
    return s.hashCode.abs() % 2147483647;
  }

  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String title,
    required DateTime appointmentDateTime,
    required int minutesBefore,
    String? location,
  }) async {
    await init();

    /*final scheduled = appointmentDateTime.subtract(Duration(minutes: minutesBefore));
    if (scheduled.isBefore(DateTime.now())) {
      // Ако веќе поминало времето за потсетник, не закажувај.
      return;
    }*/
    final scheduled = appointmentDateTime.subtract(
      Duration(minutes: minutesBefore),
    );

// ✅ DEBUG PRINTS — додај ги овие
    print("NOW: ${DateTime.now()}");
    print("APPOINTMENT: $appointmentDateTime");
    print("REMINDER AT: $scheduled");
    print("TIMEZONE: ${DateTime.now().timeZoneName} offset=${DateTime.now().timeZoneOffset}");

    if (scheduled.isBefore(DateTime.now())) {
      print("❌ Reminder time is already in the past — NOT scheduling");
      return;
    }

    final id = _idFromString(appointmentId);

    const androidDetails = AndroidNotificationDetails(
      'appointments_channel',
      'Appointments',
      channelDescription: 'Reminders for pet appointments',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    final body = (location != null && location.trim().isNotEmpty)
        ? 'Локација: $location'
        : 'Имаш закажано appointment за милениче.';

    await _plugin.zonedSchedule(
      id,
      'Потсетник: $title',
      'За 10 минути. $body',
      tz.TZDateTime.from(scheduled, tz.local),
      details,

      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancelAppointmentReminder(String appointmentId) async {
    await init();
    final id = _idFromString(appointmentId);
    await _plugin.cancel(id);
  }

  Future<void> testNow() async {
    await init();

    await _plugin.show(
      999,
      "TEST NOTIFICATION",
      "If you see this → notifications work ✅",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "test_channel",
          "Test Channel",
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }


}*/

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    // ✅ локален timezone (Europe/Skopje)
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    final String tzName = tzInfo.identifier;
    tz.setLocalLocation(tz.getLocation(tzName));
    print("🕒 TZ identifier: $tzName | tz.local: ${tz.local.name}");

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // ✅ notification permission
    final notifGranted = await android?.requestNotificationsPermission();
    print("🔔 Notifications permission result: $notifGranted");

    // ✅ ПРОВЕРИ дали имаш право за EXACT alarms
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    print("⏰ canScheduleExactNotifications = $canExact");

    // ✅ ако не е дозволено -> побарај / отвори settings
    if (!canExact) {
      print("⚠️ Requesting exact alarms permission...");
      await android?.requestExactAlarmsPermission();

      // провери пак после барањето
      final canExactAfter = await android?.canScheduleExactNotifications() ?? false;
      print("⏰ canScheduleExactNotifications AFTER = $canExactAfter");
    }

    _initialized = true;
  }
  // Notification ID мора int
  int _idFromString(String s) => s.hashCode.abs() % 2147483647;

  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String title,
    required DateTime appointmentDateTime,
    required int minutesBefore,
    String? location,
  }) async {
    await init();

    final scheduled =
    appointmentDateTime.subtract(Duration(minutes: minutesBefore));

    // ✅ DEBUG
    print("NOW: ${DateTime.now()}");
    print("APPOINTMENT: $appointmentDateTime");
    print("REMINDER AT: $scheduled");
    print("TZ local: ${tz.local.name}");

    if (scheduled.isBefore(DateTime.now())) {
      print("❌ Reminder time is already in the past — NOT scheduling");
      return;
    }

    final id = _idFromString(appointmentId);

    const androidDetails = AndroidNotificationDetails(
      'appointments_channel',
      'Appointments',
      channelDescription: 'Reminders for pet appointments',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    final body = (location != null && location.trim().isNotEmpty)
        ? 'Локација: $location'
        : 'Имаш закажано appointment за милениче.';

    final tzTime = tz.TZDateTime.from(scheduled, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Потсетник: $title',
      'За $minutesBefore минути. $body',
      tzTime,
      details,
      // ✅ EXACT (за кратки интервали 3-5 минути)
      //androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    // ✅ Debug: провери дали се појавува во pending
    final pending = await _plugin.pendingNotificationRequests();
    print("✅ Pending count: ${pending.length}");
  }

  Future<void> cancelAppointmentReminder(String appointmentId) async {
    await init();
    final id = _idFromString(appointmentId);
    await _plugin.cancel(id);
  }

  /*Future<void> testNow() async {
    await init();

    await _plugin.show(
      999,
      "TEST NOTIFICATION",
      "If you see this → notifications work ✅",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "test_channel",
          "Test Channel",
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
*/

  // (опционално) корисно за дебаг
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}