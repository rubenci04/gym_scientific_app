import 'package:hive/hive.dart';

part 'hydration_settings_model.g.dart';

@HiveType(typeId: 12)
class HydrationSettings extends HiveObject {
  @HiveField(0)
  bool enabled;

  @HiveField(1)
  int intervalMinutes; // Intervalo en minutos

  @HiveField(2)
  int startHour; // Hora de inicio (0-23)

  @HiveField(3)
  int endHour; // Hora de fin (0-23)

  HydrationSettings({
    this.enabled = false,
    this.intervalMinutes = 60,
    this.startHour = 8,
    this.endHour = 22,
  });
}
