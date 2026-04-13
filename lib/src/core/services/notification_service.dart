import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_timezone/system_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart';

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    tz.initializeTimeZones();
    final timezone = SystemTimezone.getTimezoneName()?.trim();
    if (timezone?.isNotEmpty ?? false) {
      try {
        tz.setLocalLocation(tz.getLocation(timezone!));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    } else {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> syncProfileNotifications(
    BodyProfile profile,
    NotificationPreferences preferences,
  ) async {
    await initialize();
    await _plugin.cancelAll();
    if (!preferences.enabled) {
      return;
    }

    if (preferences.weighInEnabled) {
      await _scheduleDaily(
        100,
        'Weigh-in, champion',
        'Before you start bargaining with gravity, log the number. Fifteen seconds. You can survive it.',
        profile.wakeMinutes + 15,
      );
    }
    if (preferences.breakfastEnabled) {
      await _scheduleDaily(
        101,
        'Breakfast log',
        'Eat the meal. Log the meal. Revolutionary stuff, I know.',
        preferences.breakfastMinutes,
      );
    }
    if (preferences.lunchEnabled) {
      await _scheduleDaily(
        102,
        'Lunch check',
        'Midday audit. Try entering lunch before pretending the calories are classified.',
        preferences.lunchMinutes,
      );
    }
    if (preferences.dinnerEnabled) {
      await _scheduleDaily(
        103,
        'Dinner report',
        'Dinner happened. Your app would love to hear about it, assuming we still care about accuracy.',
        preferences.dinnerMinutes,
      );
    }
    if (preferences.randomOneEnabled) {
      await _scheduleDaily(
        104,
        'System poke',
        'Friendly reminder from your deeply burdened AI: water, protein, discipline. Pick at least two.',
        preferences.randomOneMinutes,
      );
    }
    if (preferences.randomTwoEnabled) {
      await _scheduleDaily(
        105,
        'Status check',
        'You said you wanted progress. Annoying how that requires consistency, isn’t it?',
        preferences.randomTwoMinutes,
      );
    }
    if (preferences.weeklyCheckInEnabled) {
      await _scheduleWeekly(
        200,
        'Weekly check-in',
        'Measurements and progress photos. Let’s collect evidence instead of vibes.',
        preferences.weeklyCheckInWeekday,
        preferences.weeklyCheckInMinutes,
      );
    }
  }

  Future<void> _scheduleDaily(
    int id,
    String title,
    String body,
    int minutes,
  ) async {
    final scheduled = _nextInstance(minutes, null);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitness_os_daily',
          'Fitness OS Daily',
          channelDescription: 'Daily nutrition, workout, and logging reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly(
    int id,
    String title,
    String body,
    int weekday,
    int minutes,
  ) async {
    final scheduled = _nextInstance(minutes, weekday);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitness_os_weekly',
          'Fitness OS Weekly',
          channelDescription: 'Weekly measurement and progress reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstance(int minutes, int? weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (weekday != null) {
      while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
