import 'package:hive/hive.dart';
import '../models/history_model.dart';
import '../models/exercise_model.dart';

class FatigueService {
  // Retorna un mapa con el estado de fatiga (0.0 a 1.0) por grupo muscular
  static Map<String, double> calculateMuscleFatigue() {
    final historyBox = Hive.box<WorkoutSession>('historyBox');
    final exerciseBox = Hive.box<Exercise>('exerciseBox');
    
    final Map<String, double> fatigueMap = {};
    final now = DateTime.now();

    // 1. Recorrer sesiones de las últimas 72 horas
    for (var session in historyBox.values) {
      final difference = now.difference(session.date).inHours;
      
      if (difference < 72) {
        // Factor de recuperación: Más reciente = Más fatiga
        // 0-24h: 100% impacto, 24-48h: 50%, 48-72h: 25%
        double decayFactor = 1.0;
        if (difference > 24) decayFactor = 0.5;
        if (difference > 48) decayFactor = 0.25;

        for (var workoutExercise in session.exercises) {
          // Buscar qué músculo trabajó este ejercicio
          final exerciseDef = exerciseBox.values.firstWhere(
            (e) => e.id == workoutExercise.exerciseId,
            orElse: () => Exercise(id: 'unknown', name: 'Unknown', muscleGroup: 'General', equipment: '', movementPattern: ''),
          );

          // Sumar "Puntos de Fatiga" (Sets x RPE x Factor)
          double sessionLoad = 0;
          for (var set in workoutExercise.sets) {
            // Si el RPE es alto, cansa más
            double rpeFactor = (set.rpe > 0 ? set.rpe : 7) / 10; 
            sessionLoad += 1.0 * rpeFactor;
          }

          final muscle = exerciseDef.muscleGroup.split(' ')[0]; // Simplificar "Piernas (Cuádriceps)" a "Piernas"
          fatigueMap[muscle] = (fatigueMap[muscle] ?? 0) + (sessionLoad * decayFactor);
        }
      }
    }

    return fatigueMap;
  }

  // Devuelve un color según el nivel de fatiga acumulado
  static double getFatigueLevel(String muscle) {
    // Definimos un umbral arbitrario de "volumen máximo recuperable" diario
    // Digamos que 10 sets efectivos es el 100% de fatiga aguda
    final map = calculateMuscleFatigue();
    final load = map[muscle] ?? 0.0;
    
    // Normalizamos de 0.0 a 1.0 (topeando en 1.0)
    return (load / 8.0).clamp(0.0, 1.0);
  }
}