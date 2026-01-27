import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive/hive.dart';
import '../models/hydration_settings_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ID del canal constante para asegurar consistencia
  static const String _channelId = 'hydration_channel_id';
  static const String _channelName = 'Hidratación y Recordatorios';
  static const String _channelDesc = 'Recordatorios programados para beber agua';

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Inicializar Timezones
      tz.initializeTimeZones();
      try {
        // Intentar configurar zona horaria de Argentina como pidió el usuario
        tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
      } catch (e) {
        // Fallback a la zona local del dispositivo si falla
        tz.setLocalLocation(tz.local);
      }

      // 2. Configuración Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // 3. Configuración iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // Lo pediremos manualmente después
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("🔔 Notificación tocada: ${details.payload}");
        },
      );

      // 4. CREAR CANAL DE NOTIFICACIONES (Crítico para Android 8+)
      if (Platform.isAndroid) {
        final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max, // Máxima prioridad para que suene
            playSound: true,
          ),
        );
      }

      _initialized = true;
      debugPrint("✅ NotificationService inicializado correctamente.");
    } catch (e) {
      debugPrint("⚠️ Error fatal inicializando notificaciones: $e");
    }
  }

  static Future<void> scheduleHydrationReminders() async {
    await initialize();

    // Abrir caja de configuración
    final box = await Hive.openBox<HydrationSettings>('hydrationBox');
    final settings = box.get('settings') ?? HydrationSettings();

    // 1. Cancelar todo lo anterior para evitar duplicados
    await cancelAllNotifications();

    // Si está desactivado, salimos después de cancelar
    if (!settings.enabled) {
      debugPrint("🔕 Notificaciones de hidratación desactivadas.");
      return;
    }

    // Validación de seguridad para evitar bucles infinitos
    if (settings.intervalMinutes < 15) {
      debugPrint("⚠️ Intervalo muy corto (${settings.intervalMinutes} min). Forzando a 60 min.");
      settings.intervalMinutes = 60; 
    }

    final now = DateTime.now();
    
    // Crear fechas base para HOY
    final startTime = DateTime(
      now.year, now.month, now.day, settings.startHour, 0,
    );
    final endTime = DateTime(
      now.year, now.month, now.day, settings.endHour, 0,
    );

    int id = 100; // ID base para hidratación
    DateTime nextSchedule = startTime;

    debugPrint("📅 Programando hidratación de ${settings.startHour}:00 a ${settings.endHour}:00 cada ${settings.intervalMinutes} min.");

    // Bucle de programación
    while (nextSchedule.isBefore(endTime)) {
      
      // Ajuste de fecha:
      // Queremos programar una alerta recurrente diaria a esta HORA.
      // tz.TZDateTime maneja la fecha exacta. 
      // Si la hora ya pasó hoy, scheduledDate debe ser mañana para la primera ejecución,
      // PERO como usamos matchDateTimeComponents: DateTimeComponents.time,
      // lo importante es la HORA.
      
      tz.TZDateTime scheduledDate = tz.TZDateTime.from(nextSchedule, tz.local);
      
      // Si la fecha calculada ya pasó hoy, la librería a veces falla si no le damos futuro.
      // Le sumamos un día si ya pasó, para que la primera sea mañana.
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _scheduleNotification(
        id: id,
        title: '💧 Hora de Hidratarse',
        body: 'Tu cuerpo necesita agua para rendir al máximo. ¡Bebe un vaso!',
        scheduledTime: scheduledDate,
      );

      id++;
      nextSchedule = nextSchedule.add(Duration(minutes: settings.intervalMinutes));
    }
    
    debugPrint("✅ Se programaron ${id - 100} alarmas de hidratación.");
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            // Icono grande opcional si tienes assets, si no usa el default
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBanner: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Crítico para que suene aunque el móvil duerma
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // REPETIR DIARIAMENTE A ESTA HORA
      );
    } catch (e) {
      debugPrint("❌ Error programando notificación ID $id: $e");
    }
  }

  static Future<bool> requestPermissions() async {
    await initialize();

    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      // Permiso de Notificaciones (Android 13+)
      final bool? grantedNotif = await androidImplementation?.requestNotificationsPermission();
      
      // Permiso de Alarmas Exactas (Android 12+) - A veces requiere ir a ajustes, 
      // pero requestExactAlarmsPermission no existe en todas las versiones del plugin.
      // Normalmente se maneja en el AndroidManifest.xml con <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
      
      return grantedNotif ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
          
      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint("🗑️ Todas las notificaciones canceladas.");
  }
}