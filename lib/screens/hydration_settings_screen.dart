import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/hydration_settings_model.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class HydrationSettingsScreen extends StatefulWidget {
  const HydrationSettingsScreen({super.key});

  @override
  State<HydrationSettingsScreen> createState() =>
      _HydrationSettingsScreenState();
}

class _HydrationSettingsScreenState extends State<HydrationSettingsScreen> {
  late Box<HydrationSettings> _box;
  late HydrationSettings _settings;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<HydrationSettings>('hydrationBox');
    _settings = _box.get('settings') ?? HydrationSettings();
  }

  Future<void> _saveSettings() async {
    await _box.put('settings', _settings);
    if (_settings.enabled) {
      final granted = await NotificationService.requestPermissions();
      if (granted) {
        await NotificationService.scheduleHydrationReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recordatorios de hidratación activados'),
            ),
          );
        }
      }
    } else {
      await NotificationService.cancelAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recordatorios desactivados')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recordatorios de Hidratación'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.surface,
            child: SwitchListTile(
              title: const Text(
                'Activar recordatorios',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Recibe notificaciones para mantenerte hidratado',
                style: TextStyle(color: Colors.white70),
              ),
              value: _settings.enabled,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _settings.enabled = value;
                });
                _saveSettings();
              },
            ),
          ),

          if (_settings.enabled) ...[
            const SizedBox(height: 20),

            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intervalo: ${_settings.intervalMinutes} minutos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: _settings.intervalMinutes.toDouble(),
                      min: 15,
                      max: 180,
                      divisions: 11,
                      activeColor: AppColors.primary,
                      label: '${_settings.intervalMinutes} min',
                      onChanged: (value) {
                        setState(() {
                          _settings.intervalMinutes = value.round();
                        });
                      },
                      onChangeEnd: (value) => _saveSettings(),
                    ),
                    const Text(
                      'Cada cuánto tiempo recibirás un recordatorio',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              color: AppColors.surface,
              child: ListTile(
                title: const Text(
                  'Hora de inicio',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${_settings.startHour.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
                trailing: const Icon(Icons.access_time, color: Colors.white54),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: _settings.startHour,
                      minute: 0,
                    ),
                    builder: (context, child) {
                      return Theme(data: ThemeData.dark(), child: child!);
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _settings.startHour = picked.hour;
                    });
                    _saveSettings();
                  }
                },
              ),
            ),

            Card(
              color: AppColors.surface,
              child: ListTile(
                title: const Text(
                  'Hora de fin',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${_settings.endHour.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
                trailing: const Icon(Icons.access_time, color: Colors.white54),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: _settings.endHour, minute: 0),
                    builder: (context, child) {
                      return Theme(data: ThemeData.dark(), child: child!);
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _settings.endHour = picked.hour;
                    });
                    _saveSettings();
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Consejos de hidratación',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• Bebe 2-3 litros de agua al día\n'
                    '• Más agua durante entrenamientos\n'
                    '• Hidrata antes de sentir sed\n'
                    '• Agua fresca, no helada',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
