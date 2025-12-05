import 'package:hive/hive.dart';
import '../models/routine_model.dart';

class RoutineRepository {
  static const String _boxName = 'routineBox';

  static Future<void> saveRoutine(WeeklyRoutine routine) async {
    final box = await Hive.openBox<WeeklyRoutine>(_boxName);
    await box.put(routine.id, routine);
  }

  static Future<List<WeeklyRoutine>> getAllRoutines() async {
    final box = await Hive.openBox<WeeklyRoutine>(_boxName);
    return box.values.toList();
  }

  static Future<void> deleteRoutine(String id) async {
    final box = await Hive.openBox<WeeklyRoutine>(_boxName);
    await box.delete(id);
  }

  static Future<void> setActiveRoutine(String id) async {
    final box = await Hive.openBox<WeeklyRoutine>(_boxName);
    final routines = box.values.toList();

    for (var routine in routines) {
      if (routine.id == id) {
        routine.isActive = true;
      } else {
        routine.isActive = false;
      }
      await routine.save();
    }
  }

  static WeeklyRoutine? getActiveRoutine() {
    // Nota: Hive.box debe estar abierto antes de llamar a esto síncronamente
    // En main.dart ya abrimos las cajas, pero por seguridad usamos openBox si es async
    if (!Hive.isBoxOpen(_boxName)) return null;

    final box = Hive.box<WeeklyRoutine>(_boxName);
    try {
      return box.values.firstWhere((r) => r.isActive);
    } catch (e) {
      return null;
    }
  }

  // Método para inicializar la caja si es necesario
  static Future<void> init() async {
    await Hive.openBox<WeeklyRoutine>(_boxName);
  }
}
