import 'package:hive_flutter/hive_flutter.dart';
import '../models/history_model.dart';

class CurrentWorkoutService {
  static const String _boxName = 'currentSessionBox';

  static Future<void> saveSession({
    required String routineId,
    required String dayName,
    required Map<String, List<WorkoutSet>> sessionData,
  }) async {
    final box = await Hive.openBox(_boxName);

    // Convert Map to List<WorkoutExercise> for storage
    // We use WorkoutExercise as a container, even though it's meant for history
    List<WorkoutExercise> exercisesList = [];
    sessionData.forEach((exId, sets) {
      if (sets.isNotEmpty) {
        exercisesList.add(
          WorkoutExercise(
            exerciseId: exId,
            exerciseName:
                '', // Not strictly needed for restoration, can be looked up
            sets: sets,
          ),
        );
      }
    });

    await box.put('routineId', routineId);
    await box.put('dayName', dayName);
    await box.put('exercises', exercisesList);
    await box.put('timestamp', DateTime.now());
  }

  static Future<Map<String, dynamic>?> getSession() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);

    if (box.isEmpty) return null;

    final String? routineId = box.get('routineId');
    final String? dayName = box.get('dayName');
    final List<dynamic>? exercisesDynamic = box.get('exercises');
    final DateTime? timestamp = box.get('timestamp');

    if (routineId == null || exercisesDynamic == null) return null;

    // Check if session is too old (e.g., > 12 hours)
    if (timestamp != null) {
      final diff = DateTime.now().difference(timestamp);
      if (diff.inHours > 12) {
        await clearSession();
        return null;
      }
    }

    // Convert back to Map
    Map<String, List<WorkoutSet>> sessionData = {};
    for (var item in exercisesDynamic) {
      if (item is WorkoutExercise) {
        sessionData[item.exerciseId] = List<WorkoutSet>.from(item.sets);
      }
    }

    return {
      'routineId': routineId,
      'dayName': dayName,
      'sessionData': sessionData,
    };
  }

  static Future<void> clearSession() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    await box.clear();
  }
}
