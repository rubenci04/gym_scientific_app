import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive/hive.dart';
import '../models/hydration_settings_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));

    // Configurar Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configurar iOS (opcional)
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    _initialized = true;
  }

  static Future<void> scheduleHydrationReminders() async {
    await initialize();

    final box = await Hive.openBox<HydrationSettings>('hydrationBox');
    final settings = box.get('settings') ?? HydrationSettings();

    // Cancel all existing notifications
    await _notifications.cancelAll();

    if (!settings.enabled) return;

    // Schedule notifications for each interval
    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      settings.startHour,
    );
    final endTime = DateTime(now.year, now.month, now.day, settings.endHour);

    int id = 0;
    DateTime scheduledTime = startTime;

    while (scheduledTime.isBefore(endTime)) {
      if (scheduledTime.isAfter(now)) {
        await _scheduleNotification(
          id: id,
          title: '💧 Hidratación',
          body:
              '¡Recuerda beber agua! Mantente hidratado para un mejor rendimiento.',
          scheduledTime: scheduledTime,
        );
        id++;
      }
      scheduledTime = scheduledTime.add(
        Duration(minutes: settings.intervalMinutes),
      );
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'hydration_channel',
      'Hidratación',
      channelDescription: 'Recordatorios para beber agua',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  static Future<bool> requestPermissions() async {
    await initialize();

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      await android.requestNotificationsPermission();
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }

    return true;
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
