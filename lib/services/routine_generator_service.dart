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
    await routineBox.put(newRoutine.id, newRoutine);
  }

  static Future<WeeklyRoutine> generateRoutine(
    UserProfile user, {
    String focusArea = 'Cuerpo Completo',
  }) async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');
    final allExercises = exerciseBox.values.toList();

    // 1. Filtrar Ejercicios por Ubicación (Casa vs Gym)
    final availableExercises = _filterExercisesByLocation(allExercises, user.location);

    // 2. Determinar Estructura
    // Mapear nombres en español a la lógica interna
    List<Map<String, dynamic>> structure;
    
    if (_isSpecificFocus(focusArea)) {
      structure = _getFocusedStructure(user.daysPerWeek, focusArea);
    } else {
      // Estructura general basada en días
      structure = _getScientificSplitStructure(user.daysPerWeek);
    }

    List<RoutineDay> generatedDays = [];
    List<String> notes = [];

    // 3. Generar días
    for (var i = 0; i < structure.length; i++) {
      var dayTemplate = structure[i];
      List<RoutineExercise> selectedExercises = [];
      Set<String> usedIds = {};
      double estimatedTime = 0;

      for (var slot in dayTemplate['slots']) {
        // Intenta encontrar ejercicio compatible (considerando asimetría y equipo)
        Exercise? selected;
        
        // A. Preferencia por Asimetría (Unilaterales)
        if (user.hasAsymmetry) {
           selected = _findSymmetryVariant(availableExercises, slot, usedIds);
        }

        // B. Búsqueda Estándar
        if (selected == null) {
           selected = _findStandardExercise(availableExercises, slot, usedIds);
        }

        if (selected != null) {
          // Calcular series/reps según objetivo
          var vol = _calculateVolume(user, selected);
          
          String note = vol['note'];
          if (user.hasAsymmetry && selected.symmetryScore >= 7) {
            note = "⚠️ LEY DEL LADO DÉBIL: Empieza con el lado izquierdo. Haz las reps al fallo, luego iguala con el derecho.";
          }

          selectedExercises.add(RoutineExercise(
            exerciseId: selected.id,
            sets: vol['sets'],
            reps: vol['reps'],
            rpe: vol['rpe'],
            restTimeSeconds: vol['rest'],
            note: note,
          ));
          
          usedIds.add(selected.id);
          estimatedTime += selected.timeCost * (vol['sets'] as int);
        }
      }

      // Ajuste de Tiempo (Si se pasa, reducir descansos en accesorios)
      if (estimatedTime > user.timeAvailable) {
         for (var exR in selectedExercises) {
            var exDef = availableExercises.firstWhere((e) => e.id == exR.exerciseId);
            if (exDef.mechanic == 'isolation') {
               exR.restTimeSeconds = 30;
               exR.note = (exR.note ?? "") + " [SUPERSERIE: Descanso corto]";
            }
         }
      }

      generatedDays.add(RoutineDay(
        id: "day_${DateTime.now().millisecondsSinceEpoch}_$i",
        name: dayTemplate['name'],
        targetMuscles: List<String>.from(dayTemplate['muscles']),
        exercises: selectedExercises,
      ));
    }

    return WeeklyRoutine(
      id: "routine_${DateTime.now().millisecondsSinceEpoch}",
      name: _generateName(user.daysPerWeek, focusArea, user.goal),
      days: generatedDays,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  // --- LÓGICA DE FILTRADO ---
  
  static List<Exercise> _filterExercisesByLocation(List<Exercise> all, TrainingLocation loc) {
    if (loc == TrainingLocation.gym) return all; // Gym tiene todo
    
    // Casa: Solo corporal, mancuernas, bandas, etc.
    return all.where((ex) {
      final eq = ex.equipment.toLowerCase();
      return eq.contains('corporal') || 
             eq.contains('mancuerna') || 
             eq.contains('banda') || 
             eq.contains('banco') ||
             eq.contains('barra dominadas'); // Asumimos barra de puerta
    }).toList();
  }

  static bool _isSpecificFocus(String focus) {
    return !['Cuerpo Completo', 'Torso/Pierna', 'Empuje/Tracción/Pierna'].contains(focus);
  }

  // --- BÚSQUEDA DE EJERCICIOS ---

  static Exercise? _findSymmetryVariant(List<Exercise> available, String slotId, Set<String> used) {
    // Buscar el ejercicio original para saber qué patrón/músculo necesitamos
    try {
      // Intentamos encontrar el ejercicio original en la lista COMPLETA (incluso si no está disponible en casa)
      // para saber qué patrón tiene. Pero aquí solo tenemos 'available'.
      // Asumimos que 'slotId' es descriptivo o existe en una base global.
      // Simplificación: Buscar en 'available' por patrón si es posible.
      
      // Como no tenemos acceso a la DB completa aquí (solo 'available'), hacemos lo mejor posible:
      // Buscamos cualquier ejercicio disponible que tenga el mismo MuscleGroup que el slotId sugeriría
      // Y que sea UNILATERAL.
      
      // Hack: Deducir grupo muscular del ID si es posible, o buscar coincidencia laxa
      return available.firstWhere((ex) => 
        ex.symmetryScore >= 8 && // Unilateral
        !used.contains(ex.id) &&
        (slotId.contains(ex.muscleGroup.toLowerCase()) || slotId.contains('squat') && ex.movementPattern.contains('Sentadilla')) // Lógica difusa
      );
    } catch (e) {
      return null;
    }
  }

  static Exercise? _findStandardExercise(List<Exercise> available, String slotId, Set<String> used) {
    // 1. Intento directo (si tienes el equipo)
    try {
      return available.firstWhere((e) => e.id == slotId && !used.contains(e.id));
    } catch (e) {
      // 2. Si falló (ej: slot='bench_press_barbell' pero estás en CASA), buscamos sustituto.
      // Necesitamos saber qué patrón tenía el original.
      // Como no podemos consultar el ID que no existe, usamos heurística por nombre.
      
      String targetPattern = '';
      String targetMuscle = '';
      
      if (slotId.contains('squat')) { targetPattern = 'Sentadilla'; targetMuscle = 'Cuádriceps'; }
      else if (slotId.contains('bench') || slotId.contains('press')) { targetPattern = 'Empuje Horizontal'; targetMuscle = 'Pecho'; }
      else if (slotId.contains('row')) { targetPattern = 'Tracción Horizontal'; targetMuscle = 'Espalda'; }
      else if (slotId.contains('deadlift')) { targetPattern = 'Bisagra'; targetMuscle = 'Isquios'; }
      else if (slotId.contains('curl')) { targetPattern = 'Flexión'; targetMuscle = 'Bíceps'; }
      
      if (targetPattern.isNotEmpty) {
         try {
           return available.firstWhere((ex) => 
             ex.movementPattern == targetPattern && !used.contains(ex.id)
           );
         } catch (z) {
           // Fallback final: Cualquier cosa del mismo músculo
           try {
             return available.firstWhere((ex) => ex.muscleGroup == targetMuscle && !used.contains(ex.id));
           } catch (y) { return null; }
         }
      }
      return null;
    }
  }

  // --- VOLUMEN Y SERIES (EN ESPAÑOL) ---
  static Map<String, dynamic> _calculateVolume(UserProfile user, Exercise ex) {
    int sets = 3;
    String reps = "10-12";
    String rpe = "8";
    int rest = 90;
    String note = "";

    bool compound = ex.mechanic == 'compound';

    if (user.goal == TrainingGoal.strength) {
      sets = compound ? 5 : 3;
      reps = compound ? "3-5" : "8-10";
      rest = 180;
      note = "Mueve el peso explosivamente.";
    } else if (user.goal == TrainingGoal.hypertrophy) {
      sets = 4;
      reps = "8-12";
      rest = 120;
      note = "Controla la bajada (3 seg).";
    } else {
      // Salud/Resistencia
      sets = 3;
      reps = "15-20";
      rest = 60;
      note = "Ritmo constante.";
    }

    return {'sets': sets, 'reps': reps, 'rpe': rpe, 'rest': rest, 'note': note};
  }

  static String _generateName(int days, String focus, TrainingGoal goal) {
    String g = goal == TrainingGoal.strength ? "Fuerza" : "Hipertrofia";
    return "$focus - $days Días ($g)";
  }

  // --- ESTRUCTURAS ---
  static List<Map<String, dynamic>> _getScientificSplitStructure(int days) {
    // Definimos plantillas para 1 a 6 días
    // Cada plantilla tiene 7 slots para asegurar que no quede vacía
    switch (days) {
      case 1:
      case 2:
        return [
          {'name': 'Día A: Cuerpo Completo', 'muscles': ['Todo'], 'slots': ['squat_barbell', 'bench_press_barbell', 'row_barbell', 'ohp_barbell', 'curl_barbell', 'skullcrusher_ez', 'plank']},
          {'name': 'Día B: Cuerpo Completo', 'muscles': ['Todo'], 'slots': ['deadlift_conv', 'leg_press', 'lat_pulldown', 'dips_bench', 'lunge_barbell', 'face_pull', 'crunch']}
        ];
      case 3:
        return [
          {'name': 'Día 1: Empuje', 'muscles': ['Pecho', 'Hombros', 'Tríceps'], 'slots': ['bench_press_barbell', 'ohp_barbell', 'dips_chest', 'lat_raise', 'tricep_pushdown_rope', 'skullcrusher_ez', 'hanging_leg_raise']},
          {'name': 'Día 2: Tracción', 'muscles': ['Espalda', 'Bíceps'], 'slots': ['deadlift_conv', 'pullup', 'row_barbell', 'lat_pulldown', 'curl_barbell', 'curl_hammer', 'face_pull']},
          {'name': 'Día 3: Pierna', 'muscles': ['Pierna'], 'slots': ['squat_barbell', 'leg_press', 'rdl_barbell', 'leg_extension', 'leg_curl', 'calf_raise_standing', 'plank']}
        ];
      case 4:
        return [
          {'name': 'Torso A', 'muscles': ['Pecho', 'Espalda'], 'slots': ['bench_press_barbell', 'row_barbell', 'ohp_barbell', 'lat_pulldown', 'lat_raise', 'curl_barbell', 'skullcrusher_ez']},
          {'name': 'Pierna A', 'muscles': ['Pierna'], 'slots': ['squat_barbell', 'leg_press', 'leg_extension', 'calf_raise_standing', 'plank', 'hanging_leg_raise', 'ab_wheel']},
          {'name': 'Torso B', 'muscles': ['Pecho', 'Espalda'], 'slots': ['bench_press_incline', 'pullup', 'db_press_flat', 'row_db_one_arm', 'face_pull', 'curl_hammer', 'tricep_pushdown_rope']},
          {'name': 'Pierna B', 'muscles': ['Pierna'], 'slots': ['deadlift_sumo', 'rdl_barbell', 'bulgarian_split_squat', 'leg_curl', 'calf_raise_seated', 'russian_twist', 'crunch']}
        ];
      case 5: 
        // Híbrido Upper/Lower + PPL
        return [
          {'name': 'Torso Fuerza', 'muscles': ['Pecho', 'Espalda'], 'slots': ['bench_press_barbell', 'row_barbell', 'ohp_barbell', 'pullup', 'face_pull', 'curl_barbell', 'plank']},
          {'name': 'Pierna Fuerza', 'muscles': ['Pierna'], 'slots': ['squat_barbell', 'deadlift_conv', 'leg_press', 'calf_raise_standing', 'hanging_leg_raise', 'ab_wheel', 'crunch']},
          {'name': 'Empuje Hipertrofia', 'muscles': ['Pecho', 'Hombros'], 'slots': ['db_press_incline', 'dips_chest', 'lat_raise', 'tricep_extension_overhead', 'tricep_pushdown_rope', 'front_raise', 'russian_twist']},
          {'name': 'Tracción Hipertrofia', 'muscles': ['Espalda', 'Bíceps'], 'slots': ['lat_pulldown', 'row_seated', 'pullover_db', 'curl_db', 'curl_hammer', 'shrug_dumbbell', 'face_pull']},
          {'name': 'Pierna Hipertrofia', 'muscles': ['Pierna'], 'slots': ['squat_hack', 'lunge_barbell', 'leg_extension', 'leg_curl', 'calf_raise_seated', 'glute_bridge', 'plank']}
        ];
      default: // 6 Días
        return [
          {'name': 'Empuje A', 'muscles': ['Pecho', 'Tríceps'], 'slots': ['bench_press_barbell', 'ohp_barbell', 'tricep_extension_overhead', 'lat_raise', 'dips_bench', 'pushup', 'crunch']},
          {'name': 'Tracción A', 'muscles': ['Espalda'], 'slots': ['deadlift_conv', 'pullup', 'curl_barbell', 'row_barbell', 'face_pull', 'curl_hammer', 'plank']},
          {'name': 'Pierna A', 'muscles': ['Cuádriceps'], 'slots': ['squat_barbell', 'leg_press', 'leg_extension', 'calf_raise_standing', 'lunge_barbell', 'sissy_squat', 'ab_wheel']},
          {'name': 'Empuje B', 'muscles': ['Pecho', 'Hombros'], 'slots': ['db_press_incline', 'arnold_press', 'tricep_pushdown_rope', 'lat_raise', 'pec_deck', 'skullcrusher_ez', 'russian_twist']},
          {'name': 'Tracción B', 'muscles': ['Espalda'], 'slots': ['lat_pulldown', 'row_db_one_arm', 'pullover_db', 'curl_incline_db', 'preacher_curl', 'shrug_barbell', 'hanging_leg_raise']},
          {'name': 'Pierna B', 'muscles': ['Femoral'], 'slots': ['rdl_barbell', 'bulgarian_split_squat', 'leg_curl', 'hip_thrust_barbell', 'calf_raise_seated', 'machine_hip_abduction', 'plank']}
        ];
    }
  }

  // --- ESPECIALIZACIONES ---
  static List<Map<String, dynamic>> _getFocusedStructure(int days, String focusArea) {
    // Generar rutina genérica con énfasis en el músculo seleccionado
    return List.generate(days, (i) => {
      'name': 'Foco en $focusArea (Día ${i+1})',
      'muscles': [focusArea],
      'slots': [
         // Prioridad al músculo foco (3 ejercicios) + Relleno cuerpo completo (4 ejercicios)
         // Como los IDs son específicos, usamos lógica de sustitución para encontrar ejercicios de ese músculo
         'squat_barbell', // Base 1
         'bench_press_barbell', // Base 2
         'row_barbell', // Base 3
         // Slots variables que el algoritmo rellenará buscando el músculo foco:
         'foco_1', // Hack: estos IDs no existen, forzarán al buscador a usar el "Fallback de músculo"
         'foco_2',
         'foco_3',
         'plank' // Core siempre
      ]
    });
  }
}