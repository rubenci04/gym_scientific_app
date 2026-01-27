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

    // 2. Determinar Estructura Base (Split)
    List<Map<String, dynamic>> structure = _getScientificSplitStructure(user.daysPerWeek);

    // 3. Calcular Límite de Ejercicios según Tiempo (CRÍTICO ERROR 1)
    // 30 min ~ 3-4 ejercicios | 45 min ~ 5 | 60 min ~ 6-7 | 90 min ~ 8+
    int targetExerciseCount;
    if (user.timeAvailable <= 30) {
      targetExerciseCount = 3;
    } else if (user.timeAvailable <= 45) {
      targetExerciseCount = 5;
    } else if (user.timeAvailable <= 60) {
      targetExerciseCount = 7;
    } else {
      targetExerciseCount = 9; // Alto volumen
    }

    List<RoutineDay> generatedDays = [];

    // 4. Generar días
    for (var i = 0; i < structure.length; i++) {
      var dayTemplate = structure[i];
      List<String> rawSlots = List<String>.from(dayTemplate['slots']);
      List<RoutineExercise> selectedExercises = [];
      Set<String> usedIds = {};
      double currentEstimatedTime = 0;

      // A. Inyección de Foco (Si el usuario pidió énfasis en un músculo específico)
      if (_isSpecificFocus(focusArea)) {
        // Reemplazamos los últimos slots genéricos con slots del foco específico
        int focusSlotsCount = (targetExerciseCount >= 5) ? 2 : 1;
        // Inyectamos al inicio para priorizar
        for(int k=0; k<focusSlotsCount; k++) {
           rawSlots.insert(1, "focus_injection_$focusArea"); 
        }
      }

      // B. Selección y Filtrado de Slots
      for (var slotId in rawSlots) {
        // Si ya alcanzamos el límite de tiempo/ejercicios, paramos (a menos que sea rehab vital)
        if (selectedExercises.length >= targetExerciseCount) break;

        Exercise? selected;

        // B1. Lógica de Asimetría (Prioridad Máxima)
        // Si el usuario tiene asimetría y el slot permite un unilateral, lo forzamos.
        if (user.hasAsymmetry) {
           selected = _findSymmetryVariant(availableExercises, slotId, usedIds);
        }

        // B2. Búsqueda Estándar (Si no es asimetría o no se encontró)
        if (selected == null) {
           if (slotId.startsWith("focus_injection")) {
             // Buscar ejercicio del músculo foco (ej: "Pecho")
             selected = _findExerciseByMuscle(availableExercises, focusArea, usedIds);
           } else {
             // Buscar ejercicio estándar del slot
             selected = _findStandardExercise(availableExercises, slotId, usedIds);
           }
        }

        if (selected != null) {
          // Calcular series/reps
          var vol = _calculateVolume(user, selected, selectedExercises.length);
          
          // Generar nota educativa
          String note = vol['note'];
          if (user.hasAsymmetry && selected.symmetryScore >= 7) {
            note = "⚠️ CORRECCIÓN ASIMETRÍA: Empieza con tu lado débil (ej: pierna izquierda). Haz las reps al fallo, luego iguala con el derecho sin pasarte.";
          } else if (selected.mechanic == 'compound') {
            note = "🔥 EJERCICIO PRINCIPAL: Céntrate en mover el peso explosivamente.";
          }

          // Ajuste fino de tiempo: Si nos estamos pasando, convertir a Myo-reps o bajar descanso
          if (currentEstimatedTime + selected.timeCost > user.timeAvailable) {
             vol['rest'] = 45; // Reducir descanso drásticamente
             note += " [Descanso corto para cumplir tiempo]";
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
          currentEstimatedTime += selected.timeCost * (vol['sets'] as int);
        }
      }

      generatedDays.add(RoutineDay(
        id: "day_${DateTime.now().millisecondsSinceEpoch}_$i",
        name: dayTemplate['name'],
        targetMuscles: List<String>.from(dayTemplate['muscles']),
        exercises: selectedExercises,
      ));
    }

    // 5. Generar Descripción Explicativa (Para principiantes)
    String description = _generateExplanation(user, focusArea, generatedDays.length);

    return WeeklyRoutine(
      id: "routine_${DateTime.now().millisecondsSinceEpoch}",
      name: _generateName(user.daysPerWeek, focusArea, user.goal),
      description: description, // Asegúrate de agregar este campo en tu modelo WeeklyRoutine si no existe, o úsalo en la UI
      days: generatedDays,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  // --- LÓGICA DE FILTRADO ---
  
  static List<Exercise> _filterExercisesByLocation(List<Exercise> all, TrainingLocation loc) {
    if (loc == TrainingLocation.gym) return all;
    
    return all.where((ex) {
      final eq = ex.equipment.toLowerCase();
      // Permitimos: Corporal, Mancuernas, Bandas, etc.
      // Excluimos: Máquinas, Poleas (a menos que se asuma banda), Barras olímpicas si es casa básica
      return !eq.contains('máquina') && !eq.contains('polea') && !eq.contains('prensa'); 
    }).toList();
  }

  static bool _isSpecificFocus(String focus) {
    return !['Cuerpo Completo', 'Torso/Pierna', 'Empuje/Tracción/Pierna', 'Equilibrado'].contains(focus);
  }

  // --- BUSCADORES INTELIGENTES ---

  static Exercise? _findSymmetryVariant(List<Exercise> available, String slotId, Set<String> used) {
    // Intentamos deducir el grupo muscular del slot original (ej: "squat" -> Pierna)
    String targetMuscle = _deduceMuscleFromId(slotId);
    
    if (targetMuscle.isEmpty) return null;

    try {
      // Buscar un ejercicio UNILATERAL (Score >= 7) para ese músculo
      return available.firstWhere((ex) => 
        ex.muscleGroup == targetMuscle &&
        ex.symmetryScore >= 7 && 
        !used.contains(ex.id)
      );
    } catch (e) {
      return null;
    }
  }

  static Exercise? _findExerciseByMuscle(List<Exercise> available, String muscle, Set<String> used) {
    try {
      return available.firstWhere((ex) => 
        (ex.muscleGroup == muscle || ex.targetMuscles.contains(muscle)) && 
        !used.contains(ex.id)
      );
    } catch (e) { return null; }
  }

  static Exercise? _findStandardExercise(List<Exercise> available, String slotId, Set<String> used) {
    // 1. Intento exacto
    try {
      return available.firstWhere((e) => e.id == slotId && !used.contains(e.id));
    } catch (e) {
      // 2. Fallback por Patrón de Movimiento
      String targetPattern = _deducePatternFromId(slotId);
      String targetMuscle = _deduceMuscleFromId(slotId);

      try {
        return available.firstWhere((ex) => 
          (ex.movementPattern == targetPattern || ex.muscleGroup == targetMuscle) &&
          !used.contains(ex.id)
        );
      } catch (z) { return null; }
    }
  }

  static String _deduceMuscleFromId(String id) {
    if (id.contains('squat') || id.contains('leg') || id.contains('lunge')) return 'Cuádriceps';
    if (id.contains('bench') || id.contains('chest') || id.contains('pushup')) return 'Pecho';
    if (id.contains('row') || id.contains('pull') || id.contains('deadlift')) return 'Espalda';
    if (id.contains('curl')) return 'Bíceps';
    if (id.contains('tricep') || id.contains('skull')) return 'Tríceps';
    if (id.contains('shoulder') || id.contains('ohp') || id.contains('raise')) return 'Hombros';
    return '';
  }

  static String _deducePatternFromId(String id) {
    if (id.contains('press')) return 'Empuje';
    if (id.contains('row') || id.contains('pull')) return 'Tracción';
    if (id.contains('squat')) return 'Sentadilla';
    return '';
  }

  // --- VOLUMEN INTELIGENTE ---
  static Map<String, dynamic> _calculateVolume(UserProfile user, Exercise ex, int exerciseOrderIndex) {
    // Regla: Los primeros ejercicios (índice 0, 1) llevan más series y descanso.
    // Los últimos (accesorios) llevan menos.
    
    int sets = 3;
    String reps = "10-12";
    String rpe = "8";
    int rest = 90;
    String note = "";

    bool isCompound = ex.mechanic == 'compound';
    bool isMainLift = exerciseOrderIndex < 2; // Los 2 primeros del día

    if (user.goal == TrainingGoal.strength) {
      sets = isMainLift ? 5 : 3;
      reps = isMainLift ? "3-5" : "8-10";
      rest = isMainLift ? 180 : 120;
      note = "Prioridad: Peso. Descansa todo lo necesario.";
    } else if (user.goal == TrainingGoal.hypertrophy) {
      sets = isMainLift ? 4 : 3;
      reps = "8-12";
      rest = isCompound ? 120 : 90; // Menos descanso en aislamiento
      note = "Prioridad: Técnica y control (3 seg bajada).";
    } else {
      // Salud / Pérdida de Peso (Metabólico)
      sets = 3;
      reps = "12-15";
      rest = 60; // Ritmo alto
      note = "Mantén el ritmo cardiaco elevado.";
    }

    // Ajuste por tiempo disponible global (Micro-ajuste)
    if (user.timeAvailable <= 30 && !isMainLift) {
      sets = 2; // Ahorrar tiempo en accesorios
      rest = 45;
    }

    return {'sets': sets, 'reps': reps, 'rpe': rpe, 'rest': rest, 'note': note};
  }

  static String _generateName(int days, String focus, TrainingGoal goal) {
    String g = goal == TrainingGoal.strength ? "Fuerza" : "Hipertrofia";
    return "$focus - $days Días ($g)";
  }

  static String _generateExplanation(UserProfile user, String focus, int days) {
    String intro = "¡Hola ${user.name}! He diseñado este plan de $days días específicamente para ti.\n\n";
    String goalText = "";
    if (user.goal == TrainingGoal.hypertrophy) goalText = "El objetivo principal es aumentar tu masa muscular. Para ello, cada serie debe costarte esfuerzo (RPE alto). ";
    if (user.goal == TrainingGoal.strength) goalText = "Nos enfocaremos en ganar fuerza bruta con descansos largos y pesos altos. ";
    
    String timeText = "Dado que tienes ${user.timeAvailable} minutos, he ajustado el volumen para que sea intenso pero breve. ";
    if (user.timeAvailable <= 30) timeText += "Hemos seleccionado solo los ejercicios más efectivos (compuestos) para maximizar tu tiempo. ";
    
    String asymText = "";
    if (user.hasAsymmetry) asymText = "\n\n⚠️ IMPORTANTE: He detectado asimetría. Verás ejercicios unilaterales (a una mano/pierna). Empieza SIEMPRE por tu lado débil y limita las repeticiones del lado fuerte a las que lograste con el débil.";

    return intro + goalText + timeText + asymText + "\n\n¡Sigue el orden estricto y registra tus pesos!";
  }

  // --- ESTRUCTURAS (Consistente con RoutineTemplates) ---
  static List<Map<String, dynamic>> _getScientificSplitStructure(int days) {
    // Definimos las plantillas base. NOTA: Ponemos muchos slots, 
    // el algoritmo de arriba cortará los sobrantes según el tiempo.
    switch (days) {
      case 1: // Full Body A
        return [
          {'name': 'Full Body: Esenciales', 'muscles': ['Todo'], 'slots': ['squat_barbell', 'bench_press_barbell', 'row_barbell', 'ohp_barbell', 'curl_barbell', 'plank']}
        ];
      case 2: // Full Body A/B
        return [
          {'name': 'Día A: Énfasis Pierna/Empuje', 'muscles': ['Todo'], 'slots': ['squat_barbell', 'bench_press_barbell', 'row_barbell', 'ohp_db', 'skullcrusher_ez', 'plank']},
          {'name': 'Día B: Énfasis Cadena Posterior', 'muscles': ['Todo'], 'slots': ['deadlift_conv', 'ohp_barbell', 'lat_pulldown', 'lunge_barbell', 'curl_barbell', 'face_pull']}
        ];
      case 3: // PPL o Full Body 3 días (Preferimos Full Body para principiantes, PPL para intermedios)
        return [
          {'name': 'Día 1: Empuje (Push)', 'muscles': ['Pecho', 'Tríceps'], 'slots': ['bench_press_barbell', 'ohp_barbell', 'db_press_incline', 'lat_raise', 'tricep_pushdown_rope', 'dips_chest']},
          {'name': 'Día 2: Tracción (Pull)', 'muscles': ['Espalda', 'Bíceps'], 'slots': ['deadlift_conv', 'lat_pulldown', 'row_barbell', 'face_pull', 'curl_barbell', 'curl_hammer']},
          {'name': 'Día 3: Pierna (Legs)', 'muscles': ['Pierna'], 'slots': ['squat_barbell', 'rdl_barbell', 'leg_press', 'leg_extension', 'leg_curl', 'calf_raise_standing']}
        ];
      case 4: // Torso / Pierna
        return [
          {'name': 'Torso A (Fuerza)', 'muscles': ['Pecho', 'Espalda'], 'slots': ['bench_press_barbell', 'row_barbell', 'ohp_barbell', 'pullup', 'skullcrusher_ez', 'curl_barbell']},
          {'name': 'Pierna A (Fuerza)', 'muscles': ['Pierna'], 'slots': ['squat_barbell', 'rdl_barbell', 'leg_press', 'calf_raise_standing', 'hanging_leg_raise', 'plank']},
          {'name': 'Torso B (Hipertrofia)', 'muscles': ['Pecho', 'Espalda'], 'slots': ['db_press_incline', 'lat_pulldown', 'dips_chest', 'row_seated', 'lat_raise', 'face_pull']},
          {'name': 'Pierna B (Hipertrofia)', 'muscles': ['Pierna'], 'slots': ['deadlift_sumo', 'bulgarian_split_squat', 'leg_extension', 'leg_curl', 'glute_bridge', 'russian_twist']}
        ];
      default: // 5 o 6 Días (PPL Frecuencia 2)
        return [
          {'name': 'Empuje A', 'muscles': ['Pecho'], 'slots': ['bench_press_barbell', 'ohp_barbell', 'dips_chest', 'lat_raise', 'tricep_extension_overhead', 'pushup']},
          {'name': 'Tracción A', 'muscles': ['Espalda'], 'slots': ['deadlift_conv', 'pullup', 'row_barbell', 'curl_barbell', 'face_pull', 'shrug_barbell']},
          {'name': 'Pierna A', 'muscles': ['Pierna'], 'slots': ['squat_barbell', 'leg_press', 'leg_extension', 'calf_raise_standing', 'lunge_barbell', 'plank']},
          {'name': 'Empuje B', 'muscles': ['Pecho'], 'slots': ['db_press_incline', 'arnold_press', 'pec_deck', 'lat_raise', 'tricep_pushdown_rope', 'crunch']},
          {'name': 'Tracción B', 'muscles': ['Espalda'], 'slots': ['lat_pulldown', 'row_db_one_arm', 'pullover_db', 'curl_hammer', 'preacher_curl', 'russian_twist']},
          {'name': 'Pierna B', 'muscles': ['Pierna'], 'slots': ['rdl_barbell', 'bulgarian_split_squat', 'hip_thrust_barbell', 'leg_curl', 'calf_raise_seated', 'ab_wheel']}
        ];
    }
  }
}