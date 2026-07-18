// The Robin - Hopeling's notification system (NATIVE.md + slice 7 spec).
// One orchestrator owns scheduling, quiet hours, permission, actions and
// deep links. Feature screens only express intent. The constitution:
// one proactive notification per day, no guilt, no urgency, no marketing,
// quiet hours 21:00 to 08:00, and every line in the Robin's calm voice.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/rules.dart' as rules;
import '../data/save.dart';
import 'clock.dart';

// ---------- preferences ----------
class RobinPrefs {
  bool enabled = false;
  int hour = 18;
  int minute = 30;
  bool silentSunday = false;
  bool privatePreview = false;
  bool offered = false; // the contextual invitation was shown
  bool denied = false; // OS permission was refused; never nag again

  static Future<RobinPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    final r = RobinPrefs();
    r.enabled = p.getBool('robin_enabled') ?? false;
    r.hour = p.getInt('robin_hour') ?? 18;
    r.minute = p.getInt('robin_minute') ?? 30;
    r.silentSunday = p.getBool('robin_sunday') ?? false;
    r.privatePreview = p.getBool('robin_private') ?? false;
    r.offered = p.getBool('robin_offered') ?? false;
    r.denied = p.getBool('robin_denied') ?? false;
    return r;
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('robin_enabled', enabled);
    await p.setInt('robin_hour', hour);
    await p.setInt('robin_minute', minute);
    await p.setBool('robin_sunday', silentSunday);
    await p.setBool('robin_private', privatePreview);
    await p.setBool('robin_offered', offered);
    await p.setBool('robin_denied', denied);
  }
}

// ---------- pure, tested logic ----------
/// Quiet hours: 21:00 to 08:00 local. No proactive sound inside them.
bool inQuietHours(int hour) => hour >= 21 || hour < 8;

/// The next moment the daily robin may tap: today at h:m if still ahead,
/// otherwise tomorrow. Times inside quiet hours are nudged to 08:00.
DateTime nextDaily(DateTime now, int hour, int minute) {
  var h = hour, m = minute;
  if (inQuietHours(h)) {
    h = 8;
    m = 0;
  }
  var at = DateTime(now.year, now.month, now.day, h, m);
  if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
  return at;
}

/// "Tonight": one gentle reschedule. Before evening → 19:30 today.
/// Evening → two hours later if that stays outside quiet hours.
/// Too late → tomorrow at the chosen time (never inside quiet hours).
DateTime tonightAt(DateTime now, int prefHour, int prefMinute) {
  if (now.hour < 19) {
    return DateTime(now.year, now.month, now.day, 19, 30);
  }
  final later = now.add(const Duration(hours: 2));
  if (!inQuietHours(later.hour)) return later;
  return nextDaily(
      DateTime(now.year, now.month, now.day, 23, 59), prefHour, prefMinute);
}

/// Silent Sunday's weekly line, computed from the real log. Reflective,
/// never evaluative: no "you missed" statistics, ever.
String sundaySummary(Save s, DateTime now) {
  var acts = 0, days = 0;
  for (var i = 0; i < 7; i++) {
    final d = todayStr(now.subtract(Duration(days: i)));
    final n = s.log[d] ?? 0;
    if (n > 0) {
      days++;
      acts += n;
    }
  }
  final lessons = (s.extra['lessons'] as Map?)?.length ?? 0;
  if (acts == 0) {
    return 'The grove rested this week. It is still yours, whenever today has room.';
  }
  return 'This week you kept $acts ${acts == 1 ? 'promise' : 'promises'} across $days ${days == 1 ? 'day' : 'days'}'
      '${lessons > 0 ? ', with $lessons chapters in your library' : ''}. The grove noticed.';
}

// ---------- the Robin's voice ----------
class RobinCopy {
  static const dailyTitle = 'The robin, at the window';
  static const dailyBody = "Today's promise is waiting whenever you are.";
  static const tonightTitle = 'As you asked';
  static const tonightBody = 'You asked me to remind you this evening.';
  static const sundayTitle = 'A quiet Sunday note';
  static const privateBody = 'Hopeling has something small for you.';

  static String body(RobinPrefs p, String full) =>
      p.privatePreview ? privateBody : full;
}

// ---------- the orchestrator ----------
class Robin {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _dailyId = 1001;
  static const _tonightId = 1002;
  static const _sundayId = 1003;
  static GlobalKey<NavigatorState>? navKey;
  static void Function(String deepLink)? onDeepLink;

  static const _channels = [
    AndroidNotificationChannel('daily', 'Daily promises',
        description: 'One quiet reminder at the time you chose.',
        importance: Importance.defaultImportance),
    AndroidNotificationChannel('letters', 'Guardian letters',
        description: 'Occasional letters about your guardian species.',
        importance: Importance.defaultImportance),
    AndroidNotificationChannel('circle', 'Circle summaries',
        description: 'One grouped daily note from your circles.',
        importance: Importance.low),
    AndroidNotificationChannel('events', 'Global events',
        description: 'Rare, real shared moments.',
        importance: Importance.defaultImportance),
    AndroidNotificationChannel('account', 'Account and sync',
        description: 'Only when something needs you.',
        importance: Importance.defaultImportance),
  ];

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    // Times are computed as local wall-clock DateTimes and scheduled by
    // their UTC instant (_at below). resync() runs on every app launch,
    // so DST and timezone travel self-correct within a day - without a
    // timezone-lookup plugin.

    const android = AndroidInitializationSettings('ic_stat_leaf');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory('daily', actions: [
          DarwinNotificationAction.plain('done', 'Done'),
          DarwinNotificationAction.plain('tonight', 'Tonight'),
          DarwinNotificationAction.plain('why', 'Why this matters',
              options: {DarwinNotificationActionOption.foreground}),
        ]),
      ],
    );
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: robinBackgroundHandler,
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final c in _channels) {
      await androidImpl?.createNotificationChannel(c);
    }
  }

  /// The OS permission dialog - only ever called after the calm
  /// explanation screen, never on first launch.
  static Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      return await androidImpl.requestNotificationsPermission() ?? false;
    }
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      return await iosImpl.requestPermissions(
              alert: true, badge: false, sound: true) ??
          false;
    }
    return false;
  }

  static NotificationDetails _details(String channel) => NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          _channels.firstWhere((c) => c.id == channel).name,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority, // never heads-up by default
          actions: channel == 'daily'
              ? [
                  const AndroidNotificationAction('done', 'Done',
                      showsUserInterface: false),
                  const AndroidNotificationAction('tonight', 'Tonight',
                      showsUserInterface: false),
                  const AndroidNotificationAction('why', 'Why this matters',
                      showsUserInterface: true),
                ]
              : null,
        ),
        iOS: DarwinNotificationDetails(
            categoryIdentifier: channel == 'daily' ? 'daily' : null,
            presentSound: false),
      );

  /// (Re)schedule everything from preferences. Idempotent: cancel, then
  /// schedule exactly one daily (or one Sunday) instance. The one-per-day
  /// rule is structural, not a convention.
  static Future<void> resync() async {
    final p = await RobinPrefs.load();
    await _plugin.cancel(_dailyId);
    await _plugin.cancel(_sundayId);
    if (!p.enabled) return;

    if (p.silentSunday) {
      final s = await Store.load();
      final now = DateTime.now();
      var at = nextDaily(now, p.hour, p.minute);
      while (at.weekday != DateTime.sunday) {
        at = at.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        _sundayId,
        RobinCopy.sundayTitle,
        RobinCopy.body(p, sundaySummary(s, now)),
        tz.TZDateTime.from(at, tz.UTC),
        _details('daily'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'hopeling://today',
      );
      return;
    }

    final at = nextDaily(DateTime.now(), p.hour, p.minute);
    await _plugin.zonedSchedule(
      _dailyId,
      RobinCopy.dailyTitle,
      RobinCopy.body(p, RobinCopy.dailyBody),
      tz.TZDateTime.from(at, tz.UTC),
      _details('daily'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      payload: 'hopeling://today',
    );
  }

  static Future<void> _scheduleTonight() async {
    final p = await RobinPrefs.load();
    final at = tonightAt(DateTime.now(), p.hour, p.minute);
    await _plugin.zonedSchedule(
      _tonightId,
      RobinCopy.tonightTitle,
      RobinCopy.body(p, RobinCopy.tonightBody),
      tz.TZDateTime.from(at, tz.UTC),
      _details('daily'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'hopeling://today',
    );
  }

  static Future<void> disable() async {
    await _plugin.cancelAll();
  }

  static void _onResponse(NotificationResponse r) async {
    await handleAction(r.actionId, r.payload);
  }

  /// Shared by foreground and background paths. Idempotent by design:
  /// "Done" completes only if today is not already kept.
  static Future<void> handleAction(String? action, String? payload) async {
    if (action == 'done') {
      final s = await Store.load();
      if (!s.doneOn(todayStr())) {
        rules.complete(s, todayStr());
        await Store.persist(s);
        saveTick.value++;
      }
      return;
    }
    if (action == 'tonight') {
      await _scheduleTonight();
      return;
    }
    // 'why' or a plain tap: open the app at the right place.
    final link = action == 'why' ? 'hopeling://today/why' : (payload ?? '');
    if (link.isNotEmpty) onDeepLink?.call(link);
  }
}

/// Background isolate entry point (notification action with the app dead).
/// Only safe, storage-level work happens here.
@pragma('vm:entry-point')
void robinBackgroundHandler(NotificationResponse r) {
  Robin.handleAction(r.actionId, r.payload);
}
