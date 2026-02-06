import 'dart:math';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/routine_model.dart';

class RoutineGeneratorService {
  
  static Future<void> generateAndSaveRoutine(
    UserProfile user, {
    String focusArea = 'Cuerpo Completo',
  }) async {
    final newRoutine = await generateRoutine(user, focusArea: focusArea);
    var routineBox = Hive.box<WeeklyRoutine>('routineBox');
    // Guardar usando el ID como clave para evitar duplicados
    await routineBox.put(newRoutine.id, newRoutine);
  }

  static Future<WeeklyRoutine> generateRoutine(
    UserProfile user, {
    String focusArea = 'Cuerpo Completo',
  }) async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');
    final allExercises = exerciseBox.values.toList();

    // 1. Filtrar Ejercicios Disponibles (Gym vs Casa, Nivel, etc.)
    // CORREGIDO: Pasamos el objeto usuario completo, la función usará user.experience
    final availableExercises = _filterExercisesContextually(allExercises, user);

    // 2. Obtener la "Receta" (Estructura de Slots abstractos)
    List<RoutineDayTemplate> structure = _getScientificSplitStructure(user.daysPerWeek, user.goal);

    // 3. Determinar Capacidad de Trabajo (Slots Máximos)
    // 30 min = 3 ejercicios claves. 60 min = 6 ejercicios.
    int maxExercisesPerDay = (user.timeAvailable / 8).floor(); // Est. 8 min por ejercicio (incl. descanso)
    if (maxExercisesPerDay < 3) maxExercisesPerDay = 3; // Mínimo viable
    if (maxExercisesPerDay > 10) maxExercisesPerDay = 10; // Tope humano

    List<RoutineDay> generatedDays = [];

    // 4. Construir cada día
    for (var i = 0; i < structure.length; i++) {
      var template = structure[i];
      List<RoutineExercise> dayExercises = [];
      Set<String> usedIdsInDay = {}; // Evitar repetir ejercicios el mismo día
      
      // A. Inyección de Foco (Prioridad Muscular)
      List<String> currentSlots = List.from(template.patternSlots);
      if (_shouldInjectFocus(focusArea, template.targetMuscles)) {
        currentSlots.insert(0, "FOCUS_$focusArea");
      }

      // B. Llenado de Slots
      for (var slotPattern in currentSlots) {
        // Stop si nos pasamos del tiempo
        if (dayExercises.length >= maxExercisesPerDay) break;

        Exercise? selected;

        // B1. Estrategia para Asimetrías
        if (user.hasAsymmetry && _isUnilateralCandidate(slotPattern)) {
          selected = _findBestExercise(
            availableExercises, 
            pattern: slotPattern, 
            mustBeUnilateral: true, 
            usedIds: usedIdsInDay,
            userLevel: user.experience // CORREGIDO: Usamos la propiedad 'experience'
          );
        }

        // B2. Estrategia Estándar
        selected ??= _findBestExercise(
          availableExercises, 
          pattern: slotPattern, 
          usedIds: usedIdsInDay,
          userLevel: user.experience, // CORREGIDO: Usamos la propiedad 'experience'
          preferredMuscle: focusArea != 'Cuerpo Completo' ? focusArea : null
        );

        if (selected != null) {
          // C. Calcular Dosis (Series/Reps/Descanso)
          var dose = _calculateOptimalDose(user, selected, dayExercises.length);
          
          dayExercises.add(RoutineExercise(
            exerciseId: selected.id,
            sets: dose['sets'],
            reps: dose['reps'],
            rpe: dose['rpe'],
            restTimeSeconds: dose['rest'],
            note: dose['note'],
          ));
          
          usedIdsInDay.add(selected.id);
        }
      }

      generatedDays.add(RoutineDay(
        id: "day_${DateTime.now().millisecondsSinceEpoch}_$i",
        name: template.name,
        targetMuscles: template.targetMuscles,
        exercises: dayExercises,
      ));
    }

    return WeeklyRoutine(
      id: "routine_${DateTime.now().millisecondsSinceEpoch}",
      name: _generateRoutineName(user, focusArea),
      description: _generateSmartDescription(user, focusArea),
      days: generatedDays,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  // ===========================================================================
  // 🧠 MOTOR DE SELECCIÓN INTELIGENTE (EL CEREBRO)
  // ===========================================================================

  static List<Exercise> _filterExercisesContextually(List<Exercise> all, UserProfile user) {
    return all.where((ex) {
      // 1. Filtro de Lugar/Equipo
      bool locationOk = true;
      if (user.location == TrainingLocation.home) {
        final eq = ex.equipment.toLowerCase();
        if (eq.contains('máquina') || eq.contains('polea') || eq.contains('prensa') || eq.contains('smith')) {
          locationOk = false;
        }
      }

      // 2. Filtro de Nivel (Seguridad)
      bool levelOk = true;
      // CORREGIDO: Usamos Experience.beginner en lugar de ExperienceLevel.beginner
      if (user.experience == Experience.beginner) {
        if (['snatch', 'clean', 'squat_overhead', 'deadlift_sumo', 'good_morning'].contains(ex.id)) {
          levelOk = false;
        }
      }

      return locationOk && levelOk;
    }).toList();
  }

  static Exercise? _findBestExercise(
    List<Exercise> candidates, {
    required String pattern, 
    required Set<String> usedIds,
    required Experience userLevel, // CORREGIDO: Tipo 'Experience'
    bool mustBeUnilateral = false,
    String? preferredMuscle,
  }) {
    List<Exercise> matches = [];

    // Paso 1: Decodificar el patrón
    if (pattern.startsWith("FOCUS_")) {
      String muscle = pattern.replaceAll("FOCUS_", "");
      matches = candidates.where((e) => e.muscleGroup == muscle || e.targetMuscles.contains(muscle)).toList();
    } else {
      matches = candidates.where((e) => _matchesPattern(e, pattern)).toList();
    }

    // Paso 2: Filtrar Unilaterales
    if (mustBeUnilateral) {
      var unilaterals = matches.where((e) => !e.isBilateral || e.symmetryScore >= 7).toList();
      if (unilaterals.isNotEmpty) matches = unilaterals;
    }

    // Paso 3: Filtrar usados
    matches = matches.where((e) => !usedIds.contains(e.id)).toList();

    if (matches.isEmpty) return null;

    // Paso 4: Sorting Inteligente
    matches.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      if (a.mechanic == 'compound') scoreA += 5;
      if (b.mechanic == 'compound') scoreB += 5;

      if (preferredMuscle != null) {
        if (a.muscleGroup == preferredMuscle) scoreA += 3;
        if (b.muscleGroup == preferredMuscle) scoreB += 3;
      }

      return scoreB.compareTo(scoreA); 
    });

    return matches.first;
  }

  static bool _matchesPattern(Exercise ex, String pattern) {
    switch (pattern) {
      case 'PUSH_HORIZONTAL': return ex.muscleGroup == 'Pecho' && ex.movementPattern.contains('Empuje');
      case 'PUSH_VERTICAL': return ex.muscleGroup == 'Hombros' && ex.movementPattern.contains('Empuje');
      case 'PULL_VERTICAL': return ex.muscleGroup == 'Espalda' && (ex.movementPattern.contains('Tracción') || ex.id.contains('pullup') || ex.id.contains('lat_pull'));
      case 'PULL_HORIZONTAL': return ex.muscleGroup == 'Espalda' && (ex.id.contains('row') || ex.movementPattern.contains('Remo'));
      case 'LEG_KNEE': return (ex.muscleGroup == 'Pierna' || ex.muscleGroup == 'Cuádriceps') && (ex.id.contains('squat') || ex.id.contains('leg_press') || ex.id.contains('lunge'));
      case 'LEG_HIP': return (ex.muscleGroup == 'Pierna' || ex.muscleGroup == 'Isquios' || ex.muscleGroup == 'Glúteo') && (ex.id.contains('deadlift') || ex.id.contains('rdl') || ex.id.contains('hip_thrust') || ex.id.contains('curl'));
      case 'ISOLATION_ARM': return ex.muscleGroup == 'Bíceps' || ex.muscleGroup == 'Tríceps';
      case 'ISOLATION_SHOULDER': return ex.muscleGroup == 'Hombros' && ex.mechanic == 'isolation';
      case 'CORE': return ex.muscleGroup == 'Abdominales' || ex.id.contains('plank') || ex.id.contains('crunch');
      case 'CARRY': return ex.id.contains('carry') || ex.id.contains('walk');
      default: return ex.id == pattern;
    }
  }

  // ===========================================================================
  // 💉 GESTIÓN DE DOSIS (VOLUMEN Y ESFUERZO)
  // ===========================================================================

  static Map<String, dynamic> _calculateOptimalDose(UserProfile user, Exercise ex, int orderIndex) {
    bool isPrimary = orderIndex < 2; 
    bool isCompound = ex.mechanic == 'compound';

    // Valores Base
    int sets = 3;
    String reps = "10-12";
    String rpe = "7-8";
    int rest = 90;
    String note = "";

    // 1. Ajuste por Objetivo (AGREGADO: weightLoss)
    if (user.goal == TrainingGoal.strength) {
      if (isCompound && isPrimary) {
        sets = 5; reps = "3-5"; rest = 180; rpe = "8.5";
        note = "💥 Foco: Máxima velocidad intencional.";
      } else {
        sets = 3; reps = "6-8"; rest = 120;
        note = "Controla la bajada.";
      }
    } else if (user.goal == TrainingGoal.hypertrophy) {
      if (isPrimary) {
        sets = 4; reps = "6-10"; rest = 120;
        note = "🧠 Conexión Mente-Músculo. Excéntrica 3 seg.";
      } else {
        sets = 3; reps = "10-15"; rest = 60; 
        note = "Bombeo constante.";
      }
    } else if (user.goal == TrainingGoal.weightLoss) {
      // NUEVO: Lógica metabólica
      sets = 3; reps = "12-15"; rest = 45; 
      note = "🔥 Mantén el ritmo cardíaco alto.";
    } else { 
      // Salud / Resistencia
      sets = 2; reps = "15-20"; rest = 30;
      note = "Resistencia muscular.";
    }

    // 2. Ajuste por Tiempo Disponible
    if (user.timeAvailable <= 30) {
      if (!isPrimary) {
        sets = 2; rest = 30; note += " [Rápido]";
      }
    } else if (user.timeAvailable >= 90) {
      sets += 1; 
    }

    // 3. Ajuste por Asimetría
    if (user.hasAsymmetry && (!ex.isBilateral || ex.symmetryScore >= 7)) {
      note = "⚠️ ASIMETRÍA: Lado débil primero.";
    }

    return {'sets': sets, 'reps': reps, 'rpe': rpe, 'rest': rest, 'note': note};
  }

  // ===========================================================================
  // 📋 ESTRUCTURAS CIENTÍFICAS
  // ===========================================================================

  static List<RoutineDayTemplate> _getScientificSplitStructure(int days, TrainingGoal goal) {
    
    // Si el objetivo es Pérdida de Grasa, priorizamos Full Body Metabólico siempre que sea posible
    if (goal == TrainingGoal.weightLoss) {
       return [
        RoutineDayTemplate(name: "Full Body Metabólico A", targetMuscles: ['Todo'], patternSlots: ['LEG_KNEE', 'PUSH_HORIZONTAL', 'PULL_VERTICAL', 'CORE', 'CARRY']),
        RoutineDayTemplate(name: "Full Body Metabólico B", targetMuscles: ['Todo'], patternSlots: ['LEG_HIP', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'CORE', 'ISOLATION_ARM']),
        if (days > 2) RoutineDayTemplate(name: "HIIT + Accesorios", targetMuscles: ['Todo'], patternSlots: ['LEG_KNEE', 'PUSH_HORIZONTAL', 'PULL_VERTICAL', 'CORE', 'CORE']),
      ];
    }

    // Estructuras Estándar (Fuerza/Hipertrofia)
    if (days == 3) {
      return [
        RoutineDayTemplate(name: "Día 1: Empuje + Cuádriceps", targetMuscles: ['Pecho', 'Hombros', 'Cuádriceps'], patternSlots: ['LEG_KNEE', 'PUSH_HORIZONTAL', 'PUSH_VERTICAL', 'ISOLATION_SHOULDER', 'ISOLATION_ARM', 'CORE']),
        RoutineDayTemplate(name: "Día 2: Tracción + Femoral", targetMuscles: ['Espalda', 'Isquios', 'Bíceps'], patternSlots: ['LEG_HIP', 'PULL_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_ARM', 'CORE', 'CARRY']),
        RoutineDayTemplate(name: "Día 3: Full Body Explosivo", targetMuscles: ['Todo'], patternSlots: ['LEG_KNEE', 'PUSH_HORIZONTAL', 'PULL_HORIZONTAL', 'LEG_HIP', 'ISOLATION_SHOULDER', 'ISOLATION_ARM']),
      ];
    }
    
    if (days == 4) {
      return [
        RoutineDayTemplate(name: "Lunes: Torso Fuerza", targetMuscles: ['Pecho', 'Espalda'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_VERTICAL', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_ARM']),
        RoutineDayTemplate(name: "Martes: Pierna Fuerza", targetMuscles: ['Pierna'], patternSlots: ['LEG_KNEE', 'LEG_HIP', 'LEG_KNEE', 'CORE', 'CARRY']),
        RoutineDayTemplate(name: "Jueves: Torso Hipertrofia", targetMuscles: ['Pecho', 'Espalda'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_HORIZONTAL', 'ISOLATION_SHOULDER', 'ISOLATION_ARM', 'ISOLATION_ARM']),
        RoutineDayTemplate(name: "Viernes: Pierna Hipertrofia", targetMuscles: ['Pierna'], patternSlots: ['LEG_HIP', 'LEG_KNEE', 'LEG_HIP', 'CORE', 'CORE']),
      ];
    }

    if (days == 5) {
      return [
        RoutineDayTemplate(name: "Empuje (Push)", targetMuscles: ['Pecho', 'Tríceps'], patternSlots: ['PUSH_HORIZONTAL', 'PUSH_VERTICAL', 'PUSH_HORIZONTAL', 'ISOLATION_SHOULDER', 'ISOLATION_ARM']),
        RoutineDayTemplate(name: "Tracción (Pull)", targetMuscles: ['Espalda', 'Bíceps'], patternSlots: ['PULL_VERTICAL', 'PULL_HORIZONTAL', 'PULL_VERTICAL', 'ISOLATION_ARM', 'CORE']),
        RoutineDayTemplate(name: "Pierna (Legs)", targetMuscles: ['Pierna'], patternSlots: ['LEG_KNEE', 'LEG_HIP', 'LEG_KNEE', 'LEG_HIP', 'CORE']),
        RoutineDayTemplate(name: "Torso Pump", targetMuscles: ['Pecho', 'Espalda'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_VERTICAL', 'ISOLATION_SHOULDER', 'ISOLATION_ARM', 'ISOLATION_ARM']),
        RoutineDayTemplate(name: "Pierna + Brazos", targetMuscles: ['Pierna', 'Brazos'], patternSlots: ['LEG_HIP', 'LEG_KNEE', 'ISOLATION_ARM', 'ISOLATION_ARM', 'CORE']),
      ];
    }

    // Default
    return [
      RoutineDayTemplate(name: "Full Body A", targetMuscles: ['Todo'], patternSlots: ['LEG_KNEE', 'PUSH_HORIZONTAL', 'PULL_VERTICAL', 'LEG_HIP', 'CORE']),
      if (days >= 2) RoutineDayTemplate(name: "Full Body B", targetMuscles: ['Todo'], patternSlots: ['LEG_HIP', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'LEG_KNEE', 'ISOLATION_ARM']),
    ];
  }

  // --- Utils ---
  static bool _shouldInjectFocus(String focus, List<String> dayMuscles) {
    if (focus == 'Cuerpo Completo') return false;
    if (dayMuscles.contains('Todo')) return true;
    return dayMuscles.any((m) => m == focus);
  }

  static bool _isUnilateralCandidate(String pattern) {
    return ['PUSH_HORIZONTAL', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'LEG_KNEE', 'LEG_HIP'].contains(pattern);
  }

  static String _generateRoutineName(UserProfile user, String focus) {
    String type = user.location == TrainingLocation.home ? "Home" : "Gym";
    return "$focus ${user.daysPerWeek}D ($type)";
  }

  static String _generateSmartDescription(UserProfile user, String focus) {
    return "Rutina generada algorítmicamente para ${user.name}.\n"
           "Objetivo: ${user.goalName}.\n"
           "Tiempo/Sesión: ~${user.timeAvailable} min.\n"
           "${user.hasAsymmetry ? '⚠️ ASIMETRÍA DETECTADA: Protocolo correctivo activado.' : ''}";
  }
}

class RoutineDayTemplate {
  final String name;
  final List<String> targetMuscles;
  final List<String> patternSlots;
  RoutineDayTemplate({required this.name, required this.targetMuscles, required this.patternSlots});
}