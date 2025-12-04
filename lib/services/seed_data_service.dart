import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise_model.dart';
import '../data/exercise_database.dart';

class SeedDataService {
  static Future<void> initializeExercises() async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');

    if (exerciseBox.isEmpty) {
      debugPrint("🔄 Inicializando base de datos de ejercicios...");
      
      // Cargar todos los ejercicios de la base de datos completa
      final allExercises = ExerciseDatabase.getAllExercises();
      
      // Guardar en Hive
      for (var exercise in allExercises) {
        await exerciseBox.put(exercise.id, exercise);
      }
      
      debugPrint("✅ Base de datos completada: ${allExercises.length} ejercicios cargados.");
    } else {
      debugPrint("ℹ️ Base de datos ya inicializada (${exerciseBox.length} ejercicios).");
    }
  }

  /// Método para actualizar la base de datos si se añaden nuevos ejercicios
  static Future<void> updateExerciseDatabase() async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');
    final allExercises = ExerciseDatabase.getAllExercises();
    
    debugPrint("🔄 Actualizando base de datos de ejercicios...");
    
    int added = 0;
    int updated = 0;
    
    for (var exercise in allExercises) {
      if (exercise Box.containsKey(exercise.id)) {
        // Actualizar ejercicio existente
        await exerciseBox.put(exercise.id, exercise);
        updated++;
      } else {
        // Añadir nuevo ejercicio
        await exerciseBox.put(exercise.id, exercise);
        added++;
      }
    }
    
    debugPrint("✅ Actualización completa: $added nuevos, $updated actualizados.");
  }
}