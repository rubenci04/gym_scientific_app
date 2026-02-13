import 'dart:math';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/routine_model.dart';

class RoutineGeneratorService {
  
  static Future<void> generateAndSaveRoutine(
    UserProfile user, {
    String focusArea = 'Full Body',
  }) async {
    final newRoutine = await generateRoutine(user, focusArea: focusArea);
    var routineBox = Hive.box<WeeklyRoutine>('routineBox');

    for (var routine in routineBox.values) {
      routine.isActive = false;
      await routine.save();
    }

    newRoutine.isActive = true;
    await routineBox.put(newRoutine.id, newRoutine);
  }

  static Future<WeeklyRoutine> generateRoutine(
    UserProfile user, {
    String focusArea = 'Full Body',
  }) async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');
    final allExercises = exerciseBox.values.toList();

    final availableExercises = _filterExercisesContextually(allExercises, user);

    List<RoutineDayTemplate> structure = _getComplexSplitStructure(
      user.daysPerWeek,
      user.goal,
      focusArea,
    );

    List<RoutineDay> generatedDays = [];

    for (var i = 0; i < structure.length; i++) {
      var template = structure[i];
      List<RoutineExercise> dayExercises = [];
      Set<String> usedIdsInDay = {};

      double accumulatedTime = 0.0;
      // Damos un poco más de margen al tiempo para permitir el 6to ejercicio
      double maxTime = (user.timeAvailable > 0 ? user.timeAvailable : 60).toDouble() + 10.0; 

      for (var slotPattern in template.patternSlots) {
        
        // CORRECCIÓN: Subimos el límite mínimo a 6 ejercicios antes de cortar por tiempo estricto,
        // a menos que el usuario tenga muy poco tiempo (ej. < 40 min).
        if (accumulatedTime >= maxTime && dayExercises.length >= 6) {
          break; 
        }

        Exercise? selected;

        if (user.hasAsymmetry && _isUnilateralCandidate(slotPattern)) {
          selected = _findBestExercise(
            availableExercises,
            pattern: slotPattern,
            mustBeUnilateral: true,
            usedIds: usedIdsInDay,
            userLevel: user.experience,
            userGoal: user.goal,
            focusContext: focusArea,
          );
        }

        selected ??= _findBestExercise(
          availableExercises,
          pattern: slotPattern,
          usedIds: usedIdsInDay,
          userLevel: user.experience,
          userGoal: user.goal,
          preferredMuscle: (slotPattern == 'FOCUS_SLOT' || slotPattern.startsWith('ISOLATION')) 
              ? (focusArea != 'Full Body' ? focusArea : null) 
              : null,
          focusContext: focusArea,
        );

        if (selected != null) {
          var dose = _calculateOptimalDose(user, selected, dayExercises.length, focusArea);

          dayExercises.add(
            RoutineExercise(
              exerciseId: selected.id,
              sets: dose['sets'],
              reps: dose['reps'],
              rpe: dose['rpe'],
              restTimeSeconds: dose['rest'],
              note: dose['note'],
            ),
          );

          usedIdsInDay.add(selected.id);
          accumulatedTime += selected.timeCost;
        }
      }

      generatedDays.add(
        RoutineDay(
          id: "day_${DateTime.now().millisecondsSinceEpoch}_$i",
          name: template.name,
          targetMuscles: template.targetMuscles,
          exercises: dayExercises,
        ),
      );
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
  // MOTOR DE FILTRADO Y SELECCIÓN
  // ===========================================================================

  static List<Exercise> _filterExercisesContextually(
    List<Exercise> all,
    UserProfile user,
  ) {
    return all.where((ex) {
      bool locationOk = true;
      if (user.location == TrainingLocation.home) {
        locationOk = ex.suitableEnvironments.contains('home');
      }

      bool levelOk = true;
      if (user.experience == Experience.beginner) {
        if (ex.difficulty == 'Avanzado' || 
            ex.id.contains('snatch') || 
            ex.id.contains('clean') ||
            ex.id == 'squat_front' || 
            ex.id == 'deadlift_sumo') {
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
    required Experience userLevel,
    required TrainingGoal userGoal,
    required String focusContext,
    bool mustBeUnilateral = false,
    String? preferredMuscle,
  }) {
    List<Exercise> matches = [];

    if (pattern == 'FOCUS_SLOT' && preferredMuscle != null) {
       matches = candidates.where(
         (e) => e.muscleGroup == preferredMuscle || e.targetMuscles.contains(preferredMuscle)
       ).toList();
    } else {
       matches = candidates.where((e) => _matchesPattern(e, pattern)).toList();
    }

    if (preferredMuscle != null && pattern.contains('ISOLATION')) {
       var muscleMatches = matches.where(
         (e) => e.muscleGroup == preferredMuscle || e.targetMuscles.contains(preferredMuscle)
       ).toList();
       if (muscleMatches.isNotEmpty) matches = muscleMatches;
    }

    if (mustBeUnilateral) {
      var unilaterals = matches
          .where((e) => !e.isBilateral || e.symmetryScore >= 7)
          .toList();
      if (unilaterals.isNotEmpty) matches = unilaterals;
    }

    matches = matches.where((e) => !usedIds.contains(e.id)).toList();

    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      if (a.mechanic == 'compound') scoreA += 5;
      if (b.mechanic == 'compound') scoreB += 5;

      if (userGoal == TrainingGoal.strength) {
        if (a.primaryMechanism == 'tension') scoreA += 4;
        if (b.primaryMechanism == 'tension') scoreB += 4;
      } else if (userGoal == TrainingGoal.weightLoss || userGoal == TrainingGoal.health) {
        if (a.primaryMechanism == 'metabolic') scoreA += 4;
        if (b.primaryMechanism == 'metabolic') scoreB += 4;
      } else {
        if (a.primaryMechanism == 'damage' || a.primaryMechanism == 'tension') scoreA += 3;
        if (b.primaryMechanism == 'damage' || b.primaryMechanism == 'tension') scoreB += 3;
      }

      if (focusContext != 'Full Body') {
         if (a.muscleGroup == focusContext) scoreA += 10;
         if (b.muscleGroup == focusContext) scoreB += 10;
         
         if (a.targetMuscles.contains(focusContext)) scoreA += 2;
         if (b.targetMuscles.contains(focusContext)) scoreB += 2;
      }

      if (mustBeUnilateral) {
        scoreA += a.symmetryScore;
        scoreB += b.symmetryScore;
      }

      return scoreB.compareTo(scoreA);
    });

    return matches.first;
  }

  static bool _matchesPattern(Exercise ex, String pattern) {
    switch (pattern) {
      case 'PUSH_HORIZONTAL': return ex.movementPattern.contains('Empuje Horizontal') || ex.muscleGroup == 'Pecho';
      case 'PUSH_VERTICAL': return ex.movementPattern.contains('Empuje Vertical') || ex.muscleGroup == 'Hombros';
      case 'PULL_VERTICAL': return ex.movementPattern.contains('Tracción Vertical') || ex.id.contains('pullup') || ex.id.contains('lat');
      case 'PULL_HORIZONTAL': return ex.movementPattern.contains('Tracción Horizontal') || ex.id.contains('row');
      
      case 'SQUAT_PATTERN': return ex.movementPattern.contains('Sentadilla') || ex.id.contains('squat') || ex.id.contains('prensa') || ex.id.contains('leg_press');
      case 'HINGE_PATTERN': return ex.movementPattern.contains('Bisagra') || ex.id.contains('deadlift') || ex.id.contains('rdl') || ex.id.contains('good_morning');
      case 'LUNGE_PATTERN': return ex.movementPattern.contains('Zancada') || ex.id.contains('lunge') || ex.id.contains('bulgarian') || ex.id.contains('step_up');
      
      case 'ISOLATION_GLUTE': return ex.muscleGroup == 'Glúteos' && ex.mechanic == 'isolation';
      case 'ISOLATION_HAMSTRING': return ex.muscleGroup == 'Isquiotibiales' && ex.mechanic == 'isolation';
      case 'ISOLATION_QUAD': return ex.muscleGroup == 'Cuádriceps' && ex.mechanic == 'isolation';
      case 'ISOLATION_CHEST': return ex.muscleGroup == 'Pecho' && ex.mechanic == 'isolation';
      case 'ISOLATION_BACK': return ex.muscleGroup == 'Espalda' && ex.mechanic == 'isolation';
      case 'ISOLATION_SHOULDER': return ex.muscleGroup == 'Hombros' && ex.mechanic == 'isolation';
      case 'ISOLATION_BICEP': return ex.muscleGroup == 'Bíceps';
      case 'ISOLATION_TRICEP': return ex.muscleGroup == 'Tríceps';
      case 'ISOLATION_ARM': return ex.muscleGroup == 'Bíceps' || ex.muscleGroup == 'Tríceps' || ex.muscleGroup == 'Antebrazo';
      
      case 'CORE': return ex.muscleGroup == 'Core' || ex.muscleGroup == 'Abdominales';
      case 'CARRY': return ex.movementPattern.contains('Transporte');
      case 'CARDIO': return ex.muscleGroup == 'Cardio';
      case 'FOCUS_SLOT': return true;
      
      default: return false;
    }
  }

  static Map<String, dynamic> _calculateOptimalDose(
    UserProfile user,
    Exercise ex,
    int orderIndex,
    String focusArea,
  ) {
    int sets = 3;
    String reps = "10-12";
    String rpe = "7-8";
    int rest = 90;
    String note = "";

    bool isCompound = ex.mechanic == 'compound';
    bool isFocusMuscle = ex.muscleGroup == focusArea;

    if (user.goal == TrainingGoal.strength) {
      if (isCompound && orderIndex < 2) {
        sets = 5; reps = "3-5"; rest = 180; rpe = "9"; 
        note = "Prioridad: Mover la carga con máxima velocidad concéntrica.";
      } else {
        sets = 3; reps = "6-8"; rest = 120; rpe = "8";
        note = "Accesorio pesado. Controla la bajada.";
      }
    } else if (user.goal == TrainingGoal.weightLoss) {
      sets = 3; reps = "12-15"; rest = 45; rpe = "7";
      note = "Mantén el ritmo cardíaco elevado. Descansos cortos.";
    } else {
      if (orderIndex == 0) { 
        sets = 4; reps = "6-10"; rest = 120; rpe = "8";
        note = "Ejercicio base. Progresión de cargas.";
      } else { 
        sets = 3; reps = "10-15"; rest = 60; rpe = "8-9";
        note = "Enfoque en sentir el músculo (Mind-Muscle connection).";
      }
    }

    if (isFocusMuscle && user.timeAvailable > 45) {
      sets += 1; 
      note += " [Volumen Extra por Foco]";
    }

    if (user.timeAvailable <= 30) {
      sets = (sets > 2) ? sets - 1 : 2;
      rest = 45;
      note = "Super-set si es posible.";
    }

    if (user.hasAsymmetry && (!ex.isBilateral || ex.symmetryScore >= 7)) {
      note = "⚠️ ASIMETRÍA: Empieza con el lado débil.";
    }

    return {'sets': sets, 'reps': reps, 'rpe': rpe, 'rest': rest, 'note': note};
  }

  // ===========================================================================
  // ARQUITECTURA DE SPLITS (CORREGIDA: AHORA CON 6 SLOTS MÍNIMO)
  // ===========================================================================

  static List<RoutineDayTemplate> _getComplexSplitStructure(
    int days,
    TrainingGoal goal,
    String focusArea,
  ) {
    if (goal == TrainingGoal.weightLoss && days < 5) {
      return _getFatLossSplit(days);
    }

    switch (focusArea) {
      case 'Glúteos': return _getGluteFocusedSplit(days);
      case 'Piernas': return _getLegFocusedSplit(days);
      case 'Pecho':   return _getChestFocusedSplit(days);
      case 'Espalda': return _getBackFocusedSplit(days);
      case 'Hombros': return _getShoulderFocusedSplit(days);
      case 'Brazos':  return _getArmFocusedSplit(days);
      case 'Core':    return _getCoreFocusedSplit(days);
      case 'Full Body':
      default:        return _getFullBodyOrBalancedSplit(days);
    }
  }

  // --- A. RUTINAS DE PÉRDIDA DE GRASA ---
  static List<RoutineDayTemplate> _getFatLossSplit(int days) {
    // CORREGIDO: 6 Slots
    var fullBodyMetabolic = ['SQUAT_PATTERN', 'PUSH_HORIZONTAL', 'HINGE_PATTERN', 'PULL_VERTICAL', 'CORE', 'CARRY', 'CARDIO'];
    var fullBodyStrength = ['SQUAT_PATTERN', 'PUSH_VERTICAL', 'LUNGE_PATTERN', 'PULL_HORIZONTAL', 'CORE', 'ISOLATION_ARM', 'CARDIO'];
    
    if (days <= 2) return [
      RoutineDayTemplate(name: "Full Body Metabólico A", targetMuscles: ['Todo'], patternSlots: fullBodyMetabolic),
      RoutineDayTemplate(name: "Full Body Metabólico B", targetMuscles: ['Todo'], patternSlots: fullBodyStrength)
    ];
    
    return [
      RoutineDayTemplate(name: "Circuito A", targetMuscles: ['Todo'], patternSlots: fullBodyMetabolic),
      RoutineDayTemplate(name: "Cardio + Core", targetMuscles: ['Core', 'Cardio'], patternSlots: ['CORE', 'CORE', 'CORE', 'ISOLATION_GLUTE', 'CARDIO', 'CARRY']),
      RoutineDayTemplate(name: "Circuito B", targetMuscles: ['Todo'], patternSlots: fullBodyStrength),
      if (days >= 4) RoutineDayTemplate(name: "HIIT Final", targetMuscles: ['Todo'], patternSlots: ['SQUAT_PATTERN', 'PUSH_HORIZONTAL', 'LUNGE_PATTERN', 'PULL_HORIZONTAL', 'CORE', 'CARDIO']),
    ];
  }

  // --- B. RUTINAS DE GLÚTEOS (CORREGIDO: AHORA SOPORTA 5 DÍAS) ---
  static List<RoutineDayTemplate> _getGluteFocusedSplit(int days) {
    // CORREGIDO: Slots expandidos a 6
    if (days <= 2) {
      return [
        RoutineDayTemplate(name: "Glúteo Pesado + Torso", targetMuscles: ['Glúteos', 'General'], patternSlots: ['HINGE_PATTERN', 'SQUAT_PATTERN', 'PUSH_HORIZONTAL', 'PULL_VERTICAL', 'ISOLATION_GLUTE', 'CORE']),
        RoutineDayTemplate(name: "Glúteo Bombeo + Torso", targetMuscles: ['Glúteos', 'General'], patternSlots: ['LUNGE_PATTERN', 'ISOLATION_GLUTE', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_GLUTE', 'CORE']),
      ];
    }
    if (days == 3) {
      return [
        RoutineDayTemplate(name: "Día 1: Glúteo & Isquios", targetMuscles: ['Glúteos'], patternSlots: ['HINGE_PATTERN', 'LUNGE_PATTERN', 'ISOLATION_GLUTE', 'ISOLATION_HAMSTRING', 'ISOLATION_GLUTE', 'CORE']),
        RoutineDayTemplate(name: "Día 2: Torso Completo", targetMuscles: ['Superior'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_VERTICAL', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_ARM', 'ISOLATION_SHOULDER']),
        RoutineDayTemplate(name: "Día 3: Glúteo & Cuádriceps", targetMuscles: ['Glúteos'], patternSlots: ['SQUAT_PATTERN', 'HINGE_PATTERN', 'ISOLATION_GLUTE', 'ISOLATION_QUAD', 'ISOLATION_GLUTE', 'CORE']),
      ];
    }
    // CORREGIDO: Soporte para 4 Y 5 días
    return [
      RoutineDayTemplate(name: "Lunes: Glúteo Máxima Carga", targetMuscles: ['Glúteos'], patternSlots: ['HINGE_PATTERN', 'SQUAT_PATTERN', 'ISOLATION_GLUTE', 'ISOLATION_GLUTE', 'ISOLATION_HAMSTRING', 'CORE']),
      RoutineDayTemplate(name: "Martes: Torso", targetMuscles: ['Superior'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_VERTICAL', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_SHOULDER', 'ISOLATION_ARM']),
      RoutineDayTemplate(name: "Jueves: Glúteo Aislamiento", targetMuscles: ['Glúteos'], patternSlots: ['LUNGE_PATTERN', 'ISOLATION_GLUTE', 'ISOLATION_GLUTE', 'ISOLATION_HAMSTRING', 'ISOLATION_QUAD', 'CORE']),
      RoutineDayTemplate(name: "Viernes: Full Body (Repaso)", targetMuscles: ['Todo'], patternSlots: ['SQUAT_PATTERN', 'PUSH_HORIZONTAL', 'PULL_HORIZONTAL', 'ISOLATION_GLUTE', 'ISOLATION_ARM', 'CORE']),
      if (days >= 5) RoutineDayTemplate(name: "Sábado: Puntos Débiles", targetMuscles: ['Detalles'], patternSlots: ['ISOLATION_GLUTE', 'ISOLATION_SHOULDER', 'ISOLATION_ARM', 'ISOLATION_GLUTE', 'CORE', 'CARDIO']),
    ];
  }

  // --- C. RUTINAS DE PIERNA GENERAL (QUAD FOCUS) ---
  static List<RoutineDayTemplate> _getLegFocusedSplit(int days) {
    if (days <= 3) {
      return [
        RoutineDayTemplate(name: "Pierna A", targetMuscles: ['Piernas'], patternSlots: ['SQUAT_PATTERN', 'LUNGE_PATTERN', 'ISOLATION_QUAD', 'ISOLATION_HAMSTRING', 'ISOLATION_GLUTE', 'CORE']),
        RoutineDayTemplate(name: "Torso", targetMuscles: ['Superior'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_VERTICAL', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_ARM', 'ISOLATION_SHOULDER']),
        RoutineDayTemplate(name: "Pierna B", targetMuscles: ['Piernas'], patternSlots: ['HINGE_PATTERN', 'SQUAT_PATTERN', 'ISOLATION_GLUTE', 'ISOLATION_QUAD', 'ISOLATION_HAMSTRING', 'CORE']),
      ];
    }
    return [
      RoutineDayTemplate(name: "Cuádriceps", targetMuscles: ['Cuádriceps'], patternSlots: ['SQUAT_PATTERN', 'LUNGE_PATTERN', 'ISOLATION_QUAD', 'ISOLATION_QUAD', 'ISOLATION_GLUTE', 'CORE']),
      RoutineDayTemplate(name: "Torso Empuje", targetMuscles: ['Pecho', 'Hombros'], patternSlots: ['PUSH_HORIZONTAL', 'PUSH_VERTICAL', 'ISOLATION_TRICEP', 'ISOLATION_TRICEP', 'ISOLATION_SHOULDER', 'ISOLATION_SHOULDER']),
      RoutineDayTemplate(name: "Femoral/Glúteo", targetMuscles: ['Isquios', 'Glúteos'], patternSlots: ['HINGE_PATTERN', 'LUNGE_PATTERN', 'ISOLATION_HAMSTRING', 'ISOLATION_GLUTE', 'ISOLATION_HAMSTRING', 'CORE']),
      RoutineDayTemplate(name: "Torso Tracción", targetMuscles: ['Espalda', 'Bíceps'], patternSlots: ['PULL_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_BACK', 'ISOLATION_BICEP', 'ISOLATION_BICEP', 'CORE']),
      if (days >= 5) RoutineDayTemplate(name: "Pierna Híbrida", targetMuscles: ['Piernas'], patternSlots: ['SQUAT_PATTERN', 'HINGE_PATTERN', 'ISOLATION_QUAD', 'ISOLATION_HAMSTRING', 'ISOLATION_GLUTE', 'CORE']),
    ];
  }

  // --- D. RUTINAS DE PECHO ---
  static List<RoutineDayTemplate> _getChestFocusedSplit(int days) {
    if (days <= 3) {
      return [
        RoutineDayTemplate(name: "Pecho & Tríceps", targetMuscles: ['Pecho'], patternSlots: ['PUSH_HORIZONTAL', 'PUSH_HORIZONTAL', 'ISOLATION_CHEST', 'ISOLATION_TRICEP', 'ISOLATION_TRICEP', 'ISOLATION_SHOULDER']),
        RoutineDayTemplate(name: "Espalda & Pierna", targetMuscles: ['General'], patternSlots: ['SQUAT_PATTERN', 'PULL_VERTICAL', 'HINGE_PATTERN', 'PULL_HORIZONTAL', 'ISOLATION_BICEP', 'CORE']),
        RoutineDayTemplate(name: "Pecho & Hombro", targetMuscles: ['Pecho'], patternSlots: ['PUSH_HORIZONTAL', 'PUSH_VERTICAL', 'ISOLATION_CHEST', 'ISOLATION_SHOULDER', 'ISOLATION_TRICEP', 'ISOLATION_CHEST']),
      ];
    }
    return [
      RoutineDayTemplate(name: "Pecho Pesado", targetMuscles: ['Pecho'], patternSlots: ['PUSH_HORIZONTAL', 'PUSH_HORIZONTAL', 'ISOLATION_CHEST', 'ISOLATION_TRICEP', 'ISOLATION_TRICEP', 'ISOLATION_SHOULDER']),
      RoutineDayTemplate(name: "Espalda & Bíceps", targetMuscles: ['Espalda'], patternSlots: ['PULL_VERTICAL', 'PULL_HORIZONTAL', 'PULL_VERTICAL', 'ISOLATION_BICEP', 'ISOLATION_BACK', 'ISOLATION_BICEP']),
      RoutineDayTemplate(name: "Piernas", targetMuscles: ['Piernas'], patternSlots: ['SQUAT_PATTERN', 'HINGE_PATTERN', 'LUNGE_PATTERN', 'ISOLATION_QUAD', 'ISOLATION_HAMSTRING', 'CORE']),
      RoutineDayTemplate(name: "Pecho Hipertrofia", targetMuscles: ['Pecho'], patternSlots: ['PUSH_HORIZONTAL', 'ISOLATION_CHEST', 'ISOLATION_CHEST', 'PUSH_VERTICAL', 'ISOLATION_TRICEP', 'ISOLATION_SHOULDER']),
      if (days >= 5) RoutineDayTemplate(name: "Upper Body Pump", targetMuscles: ['Superior'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_VERTICAL', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_ARM', 'ISOLATION_ARM']),
    ];
  }

  // --- E. RUTINAS DE ESPALDA ---
  static List<RoutineDayTemplate> _getBackFocusedSplit(int days) {
    return [
      RoutineDayTemplate(name: "Espalda Densidad", targetMuscles: ['Espalda'], patternSlots: ['PULL_HORIZONTAL', 'PULL_HORIZONTAL', 'HINGE_PATTERN', 'ISOLATION_BICEP', 'ISOLATION_BACK', 'ISOLATION_BICEP']),
      RoutineDayTemplate(name: "Pecho & Tríceps", targetMuscles: ['Pecho'], patternSlots: ['PUSH_HORIZONTAL', 'PUSH_VERTICAL', 'ISOLATION_TRICEP', 'ISOLATION_SHOULDER', 'ISOLATION_TRICEP', 'ISOLATION_CHEST']),
      RoutineDayTemplate(name: "Piernas", targetMuscles: ['Piernas'], patternSlots: ['SQUAT_PATTERN', 'LUNGE_PATTERN', 'ISOLATION_QUAD', 'ISOLATION_HAMSTRING', 'CORE', 'CORE']),
      if (days >= 4) RoutineDayTemplate(name: "Espalda Amplitud", targetMuscles: ['Espalda'], patternSlots: ['PULL_VERTICAL', 'PULL_VERTICAL', 'ISOLATION_BACK', 'ISOLATION_BICEP', 'PULL_HORIZONTAL', 'ISOLATION_BICEP']),
      if (days >= 5) RoutineDayTemplate(name: "Full Body", targetMuscles: ['Todo'], patternSlots: ['SQUAT_PATTERN', 'PUSH_HORIZONTAL', 'PULL_HORIZONTAL', 'HINGE_PATTERN', 'ISOLATION_ARM', 'CORE']),
    ];
  }

  // --- F. RUTINAS DE HOMBROS ---
  static List<RoutineDayTemplate> _getShoulderFocusedSplit(int days) {
    return [
      RoutineDayTemplate(name: "Hombros Fuerza", targetMuscles: ['Hombros'], patternSlots: ['PUSH_VERTICAL', 'ISOLATION_SHOULDER', 'ISOLATION_SHOULDER', 'ISOLATION_TRICEP', 'PUSH_HORIZONTAL', 'ISOLATION_TRICEP']),
      RoutineDayTemplate(name: "Piernas & Espalda", targetMuscles: ['General'], patternSlots: ['SQUAT_PATTERN', 'PULL_VERTICAL', 'HINGE_PATTERN', 'PULL_HORIZONTAL', 'ISOLATION_BICEP', 'CORE']),
      RoutineDayTemplate(name: "Pecho & Hombro Post", targetMuscles: ['Pecho', 'Hombros'], patternSlots: ['PUSH_HORIZONTAL', 'ISOLATION_CHEST', 'ISOLATION_SHOULDER', 'ISOLATION_SHOULDER', 'ISOLATION_TRICEP', 'CORE']),
      if (days >= 4) RoutineDayTemplate(name: "Hombros & Brazos", targetMuscles: ['Hombros'], patternSlots: ['PUSH_VERTICAL', 'ISOLATION_SHOULDER', 'ISOLATION_ARM', 'ISOLATION_ARM', 'ISOLATION_SHOULDER', 'ISOLATION_ARM']),
      if (days >= 5) RoutineDayTemplate(name: "Piernas Repaso", targetMuscles: ['Piernas'], patternSlots: ['LUNGE_PATTERN', 'SQUAT_PATTERN', 'ISOLATION_QUAD', 'ISOLATION_HAMSTRING', 'CORE', 'CORE']),
    ];
  }

  // --- G. RUTINAS DE BRAZOS ---
  static List<RoutineDayTemplate> _getArmFocusedSplit(int days) {
    return [
      RoutineDayTemplate(name: "Bíceps & Tríceps A", targetMuscles: ['Brazos'], patternSlots: ['ISOLATION_BICEP', 'ISOLATION_TRICEP', 'ISOLATION_BICEP', 'ISOLATION_TRICEP', 'ISOLATION_BICEP', 'ISOLATION_TRICEP']),
      RoutineDayTemplate(name: "Piernas", targetMuscles: ['Piernas'], patternSlots: ['SQUAT_PATTERN', 'HINGE_PATTERN', 'LUNGE_PATTERN', 'ISOLATION_QUAD', 'ISOLATION_HAMSTRING', 'CORE']),
      RoutineDayTemplate(name: "Torso (Mant.)", targetMuscles: ['Superior'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_VERTICAL', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_SHOULDER', 'CORE']),
      if (days >= 4) RoutineDayTemplate(name: "Brazos B", targetMuscles: ['Brazos'], patternSlots: ['ISOLATION_TRICEP', 'ISOLATION_BICEP', 'ISOLATION_ARM', 'ISOLATION_ARM', 'ISOLATION_BICEP', 'ISOLATION_TRICEP']),
      if (days >= 5) RoutineDayTemplate(name: "Full Body", targetMuscles: ['Todo'], patternSlots: ['SQUAT_PATTERN', 'PUSH_HORIZONTAL', 'PULL_VERTICAL', 'ISOLATION_ARM', 'ISOLATION_ARM', 'CORE']),
    ];
  }

  // --- H. RUTINAS DE CORE ---
  static List<RoutineDayTemplate> _getCoreFocusedSplit(int days) {
    return _getFullBodyOrBalancedSplit(days).map((day) {
      List<String> newSlots = List.from(day.patternSlots);
      if (!newSlots.contains('CORE')) newSlots.add('CORE');
      if (newSlots.where((s) => s == 'CORE').length < 2) newSlots.add('CORE');
      // Aseguramos que llegue a 6 slots si quedó corto
      while (newSlots.length < 6) {
        newSlots.add('CORE');
      }
      return RoutineDayTemplate(name: day.name, targetMuscles: day.targetMuscles, patternSlots: newSlots);
    }).toList();
  }

  // --- I. RUTINA DEFAULT (FULL BODY / BALANCED) ---
  static List<RoutineDayTemplate> _getFullBodyOrBalancedSplit(int days) {
    if (days <= 2) {
      return [
        RoutineDayTemplate(name: "Full Body A", targetMuscles: ['Todo'], patternSlots: ['SQUAT_PATTERN', 'PUSH_HORIZONTAL', 'PULL_VERTICAL', 'HINGE_PATTERN', 'ISOLATION_SHOULDER', 'CORE']),
        RoutineDayTemplate(name: "Full Body B", targetMuscles: ['Todo'], patternSlots: ['HINGE_PATTERN', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 'LUNGE_PATTERN', 'ISOLATION_ARM', 'CORE']),
      ];
    }
    if (days == 3) {
      return [
        RoutineDayTemplate(name: "Full Body A", targetMuscles: ['Todo'], patternSlots: ['SQUAT_PATTERN', 'PUSH_HORIZONTAL', 'PULL_HORIZONTAL', 'ISOLATION_SHOULDER', 'ISOLATION_TRICEP', 'CORE']),
        RoutineDayTemplate(name: "Full Body B", targetMuscles: ['Todo'], patternSlots: ['HINGE_PATTERN', 'PUSH_VERTICAL', 'PULL_VERTICAL', 'ISOLATION_ARM', 'ISOLATION_BICEP', 'CORE']),
        RoutineDayTemplate(name: "Full Body C", targetMuscles: ['Todo'], patternSlots: ['LUNGE_PATTERN', 'PUSH_HORIZONTAL', 'PULL_HORIZONTAL', 'ISOLATION_GLUTE', 'ISOLATION_SHOULDER', 'CORE']),
      ];
    }
    if (days == 4) {
      return [
        RoutineDayTemplate(name: "Torso A", targetMuscles: ['Superior'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_VERTICAL', 'PUSH_VERTICAL', 'ISOLATION_TRICEP', 'ISOLATION_BICEP', 'ISOLATION_SHOULDER']),
        RoutineDayTemplate(name: "Pierna A", targetMuscles: ['Inferior'], patternSlots: ['SQUAT_PATTERN', 'HINGE_PATTERN', 'ISOLATION_QUAD', 'ISOLATION_HAMSTRING', 'ISOLATION_GLUTE', 'CORE']),
        RoutineDayTemplate(name: "Torso B", targetMuscles: ['Superior'], patternSlots: ['PUSH_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_SHOULDER', 'ISOLATION_BICEP', 'ISOLATION_TRICEP', 'CORE']),
        RoutineDayTemplate(name: "Pierna B", targetMuscles: ['Inferior'], patternSlots: ['HINGE_PATTERN', 'LUNGE_PATTERN', 'ISOLATION_GLUTE', 'ISOLATION_HAMSTRING', 'ISOLATION_QUAD', 'CORE']),
      ];
    }
    // 5 días: PPL + Upper + Lower
    return [
      RoutineDayTemplate(name: "Empuje", targetMuscles: ['Empuje'], patternSlots: ['PUSH_HORIZONTAL', 'PUSH_VERTICAL', 'ISOLATION_TRICEP', 'ISOLATION_SHOULDER', 'ISOLATION_TRICEP', 'ISOLATION_CHEST']),
      RoutineDayTemplate(name: "Tracción", targetMuscles: ['Tracción'], patternSlots: ['PULL_VERTICAL', 'PULL_HORIZONTAL', 'ISOLATION_BICEP', 'ISOLATION_BACK', 'ISOLATION_BICEP', 'CORE']),
      RoutineDayTemplate(name: "Pierna", targetMuscles: ['Pierna'], patternSlots: ['SQUAT_PATTERN', 'HINGE_PATTERN', 'ISOLATION_QUAD', 'ISOLATION_HAMSTRING', 'ISOLATION_GLUTE', 'CORE']),
      RoutineDayTemplate(name: "Torso", targetMuscles: ['Superior'], patternSlots: ['PUSH_HORIZONTAL', 'PULL_VERTICAL', 'PUSH_VERTICAL', 'ISOLATION_ARM', 'ISOLATION_SHOULDER', 'CORE']),
      RoutineDayTemplate(name: "Pierna & Core", targetMuscles: ['Inferior'], patternSlots: ['LUNGE_PATTERN', 'HINGE_PATTERN', 'ISOLATION_GLUTE', 'ISOLATION_HAMSTRING', 'CORE', 'CORE']),
      if (days >= 6) RoutineDayTemplate(name: "Puntos Débiles", targetMuscles: ['Detalles'], patternSlots: ['ISOLATION_ARM', 'ISOLATION_SHOULDER', 'ISOLATION_GLUTE', 'CORE', 'CARDIO', 'CARRY']),
    ];
  }

  // ===========================================================================
  // UTILIDADES
  // ===========================================================================

  static bool _shouldInjectFocus(String focus, List<String> dayMuscles) {
    return false;
  }

  static bool _isUnilateralCandidate(String pattern) {
    return [
      'PUSH_HORIZONTAL', 'PUSH_VERTICAL', 'PULL_HORIZONTAL', 
      'SQUAT_PATTERN', 'LUNGE_PATTERN', 'HINGE_PATTERN',
      'ISOLATION_GLUTE', 'ISOLATION_ARM', 'ISOLATION_SHOULDER'
    ].contains(pattern);
  }

  static String _generateRoutineName(UserProfile user, String focus) {
    String type = user.location == TrainingLocation.home ? "Home" : "Gym";
    return "$focus ${user.daysPerWeek}D ($type)";
  }

  static String _generateSmartDescription(UserProfile user, String focus) {
    return "Plan especializado en $focus para ${user.name}.\n"
        "Objetivo: ${user.goal.name.toUpperCase()}.\n"
        "Tiempo/Sesión: ~${user.timeAvailable} min.\n"
        "${user.hasAsymmetry ? '⚠️ Protocolo de Asimetría Activado.' : ''}";
  }
}

class RoutineDayTemplate {
  final String name;
  final List<String> targetMuscles;
  final List<String> patternSlots;
  RoutineDayTemplate({
    required this.name,
    required this.targetMuscles,
    required this.patternSlots,
  });
}