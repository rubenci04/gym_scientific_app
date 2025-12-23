import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart'; // Necesario para el ThemeProvider
import '../main.dart'; // Para acceder al ThemeProvider
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
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      await NotificationService.cancelAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recordatorios desactivados'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Recordatorios de Hidratación', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        actions: [
          // Botón de Tema
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.orangeAccent : Colors.indigo,
            ),
            tooltip: "Cambiar Tema",
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: Text(
                'Activar recordatorios',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Recibe notificaciones para mantenerte hidratado',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
              color: theme.cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intervalo: ${_settings.intervalMinutes} minutos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: _settings.intervalMinutes.toDouble(),
                      min: 15,
                      max: 180,
                      divisions: 11,
                      activeColor: AppColors.primary,
                      inactiveColor: theme.dividerColor,
                      label: '${_settings.intervalMinutes} min',
                      onChanged: (value) {
                        setState(() {
                          _settings.intervalMinutes = value.round();
                        });
                      },
                      onChangeEnd: (value) => _saveSettings(),
                    ),
                    Text(
                      'Cada cuánto tiempo recibirás un recordatorio',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tarjeta de Horarios
            Card(
              color: theme.cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Hora de inicio',
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      '${_settings.startHour.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(Icons.access_time, color: theme.iconTheme.color?.withOpacity(0.5)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: _settings.startHour,
                          minute: 0,
                        ),
                        builder: (context, child) {
                          // Adaptar el picker al tema actual
                          return Theme(
                            data: isDark ? ThemeData.dark() : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), 
                            child: child!
                          );
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
                  Divider(height: 1, color: theme.dividerColor),
                  ListTile(
                    title: Text(
                      'Hora de fin',
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      '${_settings.endHour.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(Icons.access_time, color: theme.iconTheme.color?.withOpacity(0.5)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: _settings.endHour, minute: 0),
                        builder: (context, child) {
                          return Theme(
                            data: isDark ? ThemeData.dark() : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), 
                            child: child!
                          );
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
                ],
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
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Consejos de hidratación',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white : Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• Bebe 2-3 litros de agua al día\n'
                    '• Más agua durante entrenamientos\n'
                    '• Hidrata antes de sentir sed\n'
                    '• Agua fresca, no helada',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.blueGrey[800]
                    ),
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