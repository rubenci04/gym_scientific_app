import 'package:hive/hive.dart';
import '../models/routine_model.dart';

class RoutineRepository {
  static final Box<WeeklyRoutine> _box = Hive.box<WeeklyRoutine>('routineBox');

  static List<WeeklyRoutine> getAllRoutines() {
    return _box.values.toList();
  }

  static WeeklyRoutine? getActiveRoutine() {
    try {
      return _box.values.firstWhere((r) => r.isActive);
    } catch (e) {
      // Fallback: check 'currentRoutine' key if no active flag found (legacy support)
      return _box.get('currentRoutine');
    }
  }

  static Future<void> saveRoutine(WeeklyRoutine routine) async {
    await _box.put(routine.id, routine);
  }

  static Future<void> setActiveRoutine(String routineId) async {
    // Deactivate all
    for (var routine in _box.values) {
      if (routine.isActive) {
        routine.isActive = false;
        await routine.save();
      }
    }

    // Activate selected
    final routine = _box.get(routineId);
    if (routine != null) {
      routine.isActive = true;
      await routine.save();
      // Update legacy key for compatibility
      await _box.put('currentRoutine', routine);
    }
  }

  static Future<void> deleteRoutine(String routineId) async {
    await _box.delete(routineId);
  }
}
