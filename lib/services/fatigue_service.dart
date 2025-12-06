import 'dart:math';
import 'package:hive/hive.dart';
import '../models/history_model.dart';
import '../models/exercise_model.dart';
import '../models/user_model.dart';

class FatigueService {
  // --- CONSTANTES ---
  // Un valor de referencia para la fatiga máxima. ~20 sets a RPE 8 = 16 unidades.
  static const double _maxFatigueUnits = 25.0;
  // Controla la velocidad de recuperación base (aprox 50% restante en 48h)
  static const double _baseLambda = 0.015;

  // Retorna un mapa con el estado de fatiga (0.0 a 1.0) por grupo muscular
  static Map<String, double> calculateMuscleFatigue(UserProfile? user) {
    final historyBox = Hive.box<WorkoutSession>('historyBox');
    final exerciseBox = Hive.box<Exercise>('exerciseBox');

    final Map<String, double> fatigueMap = {};
    final now = DateTime.now();

    // Modificador de recuperación basado en el perfil del usuario
    final recoveryModifier = _getUserRecoveryModifier(user);

    for (var session in historyBox.values) {
      final hoursPassed = now.difference(session.date).inHours;

      if (hoursPassed < 168) {
        // Ampliamos la ventana a 7 días (168h) para capturar fatiga residual
        // Factor de decaimiento exponencial continuo
        final decayFactor = exp(-_baseLambda * recoveryModifier * hoursPassed);

        for (var workoutExercise in session.exercises) {
          final exerciseDef = exerciseBox.values.firstWhere(
            (e) => e.id == workoutExercise.exerciseId,
            orElse: () => Exercise(
              id: 'unknown',
              name: '?',
              muscleGroup: 'General',
              equipment: '',
              movementPattern: '',
            ),
          );

          // Carga de la sesión mejorada: Suma de RPEs de cada serie
          // Asumimos que más RPE = más estrés = más fatiga
          double sessionLoad = 0;
          for (var set in workoutExercise.sets) {
            // Un RPE de 0 o bajo se considera como un RPE de calentamiento (ej. 5)
            double effectiveRpe = (set.rpe > 4) ? set.rpe.toDouble() : 5.0;
            sessionLoad +=
                effectiveRpe / 10; // Cada serie añade 'su RPE' en carga
          }

          String muscleKey = _normalizeMuscleName(exerciseDef.muscleGroup);

          if (muscleKey.isNotEmpty) {
            fatigueMap[muscleKey] =
                (fatigueMap[muscleKey] ?? 0) + (sessionLoad * decayFactor);
          }
        }
      }
    }
    return fatigueMap;
  }

  // Ahora requiere el usuario para personalizar la recuperación
  static double getFatigueLevel(String muscleKey, UserProfile? user) {
    final map = calculateMuscleFatigue(user);
    final load = map[muscleKey] ?? 0.0;
    // Normalizamos la carga contra el máximo teórico
    return (load / _maxFatigueUnits).clamp(0.0, 1.0);
  }

  // Calcula un factor que acelera o decelera la recuperación
  static double _getUserRecoveryModifier(UserProfile? user) {
    if (user == null) return 1.0;

    double modifier = 1.0;

    // Experiencia: Más avanzado = recuperación más rápida
    switch (user.experience) {
      case Experience.beginner:
        modifier *= 0.85; // 15% más lento
        break;
      case Experience.intermediate:
        modifier *= 1.0;
        break;
      case Experience.advanced:
        modifier *= 1.15; // 15% más rápido
        break;
    }

    // Somatotipo: Ecto recupera rápido, Endo más lento
    switch (user.somatotype) {
      case Somatotype.ectomorph:
        modifier *= 1.1; // 10% más rápido
        break;
      case Somatotype.mesomorph:
        modifier *= 1.0;
        break;
      case Somatotype.endomorph:
        modifier *= 0.9; // 10% más lento
        break;
      case Somatotype.undefined:
        modifier *= 1.0;
        break;
    }

    return modifier;
  }

  // --- TRADUCTOR DE BASE DE DATOS A NOMBRE DE ARCHIVO ---
  static String _normalizeMuscleName(String rawName) {
    final lower = rawName.toLowerCase();

    if (lower.contains('cuádriceps') || lower.contains('piernas'))
      return 'Cuadriceps';
    if (lower.contains('pecho') || lower.contains('pectoral'))
      return 'Pectorales';
    if (lower.contains('abdominal') || lower.contains('core'))
      return 'Abdominales';
    if (lower.contains('hombro')) return 'Hombros';
    if (lower.contains('bíceps')) return 'Biceps';
    if (lower.contains('tríceps')) return 'Triceps';
    if (lower.contains('espalda')) {
      if (lower.contains('baja') || lower.contains('lumbar')) return 'Lumbares';
      if (lower.contains('alta') || lower.contains('trapecio'))
        return 'Trapecios';
      return 'Dorsales';
    }
    if (lower.contains('glúteo')) return 'Gluteos';
    if (lower.contains('isquio') || lower.contains('femoral'))
      return 'Isquiotibiales';
    if (lower.contains('gemelo') || lower.contains('pantorrilla'))
      return 'Gemelos';
    if (lower.contains('antebrazo')) return 'Antebrazos';
    if (lower.contains('aductor')) return 'Aductores';
    if (lower.contains('abductor')) return 'Abductores';

    return '';
  }
}
