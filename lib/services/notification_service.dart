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
    // Nota para mí: Dejo fijo Buenos Aires como pidió el usuario.
    try {
      tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
    } catch (e) {
      // Fallback por si falla la location específica
      tz.setLocalLocation(tz.local);
    }

    // Configurar Android
    // Nota: Asegúrate de que el icono 'ic_launcher' exista en android/app/src/main/res/mipmap-*
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

    // Cancel all existing notifications para evitar duplicados
    await _notifications.cancelAll();

    if (!settings.enabled) return;

    // Schedule notifications for each interval
    final now = DateTime.now();
    
    // Construimos la hora de inicio para "HOY"
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      settings.startHour,
    );
    
    // Construimos la hora de fin para "HOY"
    final endTime = DateTime(now.year, now.month, now.day, settings.endHour);

    int id = 0;
    DateTime scheduledTime = startTime;

    // Nota para mí: Aquí estaba el error. Si 'scheduledTime' es menor a 'endTime', 
    // iteramos por los bloques de tiempo.
    while (scheduledTime.isBefore(endTime)) {
      
      DateTime notificationDate = scheduledTime;

      // CORRECCIÓN CLAVE:
      // Si la hora calculada ya pasó hoy (ej: son las 4pm y el turno era a las 10am),
      // lo programamos para MAÑANA a las 10am.
      // Si no hacemos esto, flutter_local_notifications no crea la repetición diaria.
      if (notificationDate.isBefore(now)) {
        notificationDate = notificationDate.add(const Duration(days: 1));
      }

      await _scheduleNotification(
        id: id,
        title: '💧 Hidratación',
        body: '¡Recuerda beber agua! Mantente hidratado para un mejor rendimiento.',
        scheduledTime: notificationDate,
      );
      
      id++;
      
      // Avanzamos al siguiente intervalo
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

    // Nota para mí: matchDateTimeComponents: DateTimeComponents.time 
    // hace que se repita todos los días a la misma hora.
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, 
    );
  }

  static Future<bool> requestPermissions() async {
    await initialize();

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      // Pedimos permiso explícito en Android 13+
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