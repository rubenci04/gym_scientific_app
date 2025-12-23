import 'package:hive/hive.dart';
import '../models/routine_model.dart';

class RoutineRepository {
  static const String _boxName = 'routineBox';

  // --- MÉTODO CORREGIDO: GESTIÓN INTELIGENTE DE ESTADO ---
  // Ahora este método asegura que las rutinas nuevas nazcan desactivadas
  // a menos que sea la PRIMERA (Onboarding).
  static Future<void> addRoutine(WeeklyRoutine routine) async {
    final box = await Hive.openBox<WeeklyRoutine>(_boxName);
    
    if (box.isEmpty) {
      // Caso 1: Es la primera rutina de toda la app (ej: Onboarding).
      // Debe ser activa por defecto para que el usuario vea algo.
      routine.isActive = true;
    } else {
      // Caso 2: Ya existen rutinas (ej: Usuario crea una nueva "Fuerza").
      // Debe nacer desactivada para no superponerse a la actual.
      // El usuario podrá activarla manualmente cuando quiera.
      routine.isActive = false;
    }

    await box.put(routine.id, routine);
  }

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

    // Recorremos todas para asegurar que SOLO UNA quede activa
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
    // Verificamos si la caja está abierta para evitar crash
    if (!Hive.isBoxOpen(_boxName)) return null;

    final box = Hive.box<WeeklyRoutine>(_boxName);
    try {
      // Retorna la primera que encuentre activa
      return box.values.firstWhere((r) => r.isActive);
    } catch (e) {
      return null;
    }
  }

  static Future<void> init() async {
    await Hive.openBox<WeeklyRoutine>(_boxName);
  }
}