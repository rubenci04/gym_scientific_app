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
        double decayFactor = 1.0;
        if (difference > 24) decayFactor = 0.5;
        if (difference > 48) decayFactor = 0.25;

        for (var workoutExercise in session.exercises) {
          // Buscar definición del ejercicio
          final exerciseDef = exerciseBox.values.firstWhere(
            (e) => e.id == workoutExercise.exerciseId,
            orElse: () => Exercise(id: 'unknown', name: '?', muscleGroup: 'General', equipment: '', movementPattern: ''),
          );

          // Calcular carga de la sesión
          double sessionLoad = 0;
          for (var set in workoutExercise.sets) {
            double rpeFactor = (set.rpe > 0 ? set.rpe : 7) / 10; 
            sessionLoad += 1.0 * rpeFactor;
          }

          // Normalizar el nombre para que coincida con el archivo PNG
          String muscleKey = _normalizeMuscleName(exerciseDef.muscleGroup);
          
          if (muscleKey.isNotEmpty) {
            fatigueMap[muscleKey] = (fatigueMap[muscleKey] ?? 0) + (sessionLoad * decayFactor);
          }
        }
      }
    }

    return fatigueMap;
  }

  static double getFatigueLevel(String muscleKey) {
    final map = calculateMuscleFatigue();
    final load = map[muscleKey] ?? 0.0;
    // Asumimos que 8 sets efectivos generan 100% fatiga aguda
    return (load / 8.0).clamp(0.0, 1.0);
  }

  // --- TRADUCTOR DE BASE DE DATOS A NOMBRE DE ARCHIVO ---
  static String _normalizeMuscleName(String rawName) {
    final lower = rawName.toLowerCase();
    
    // Mapeo manual a tus nombres de archivo EXACTOS (sin tildes, mayúscula inicial)
    if (lower.contains('cuádriceps') || lower.contains('piernas')) return 'Cuadriceps';
    if (lower.contains('pecho') || lower.contains('pectoral')) return 'Pectorales';
    if (lower.contains('abdominal') || lower.contains('core')) return 'Abdominales';
    if (lower.contains('hombro')) return 'Hombros';
    if (lower.contains('bíceps')) return 'Biceps'; // Sin tilde para el archivo
    if (lower.contains('tríceps')) return 'Triceps'; // Sin tilde
    if (lower.contains('espalda')) {
       if (lower.contains('baja') || lower.contains('lumbar')) return 'EspaldaAlta'; // O Dorsales si prefieres
       return 'Dorsales';
    }
    if (lower.contains('glúteo')) return 'Gluteos'; // Sin tilde
    if (lower.contains('isquio') || lower.contains('femoral')) return 'Isquiotibiales'; // Nombre corregido
    if (lower.contains('gemelo') || lower.contains('pantorrilla')) return 'Gemelos';
    
    return ''; // Si no encuentra coincidencia
  }
}