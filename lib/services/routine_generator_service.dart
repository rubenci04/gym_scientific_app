import 'dart:math';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/routine_model.dart';

class RoutineGeneratorService {
  
  // Función principal para generar y guardar
  static Future<void> generateAndSaveRoutine(
    UserProfile user, {
    String focusArea = 'Full Body',
  }) async {
    final newRoutine = await generateRoutine(user, focusArea: focusArea);
    var routineBox = Hive.box<WeeklyRoutine>('routineBox');
    await routineBox.put(newRoutine.id, newRoutine);
  }

  static Future<WeeklyRoutine> generateRoutine(
    UserProfile user, {
    String focusArea = 'Full Body',
  }) async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');
    final allExercises = exerciseBox.values.toList();

    // 1. Filtrar por Ubicación (Casa vs Gym)
    final availableExercises = _filterExercisesByLocation(allExercises, user.location);

    // 2. Determinar Estructura (Splits Científicos)
    List<Map<String, dynamic>> structure;
    
    // Si el usuario pide un foco específico (ej: "Pectoral"), usamos lógica de especialización.
    // Si no, usamos los splits periodizados (Full Body, Upper/Lower, PPL).
    if (_isSpecificFocus(focusArea)) {
      structure = _getFocusedStructure(user.daysPerWeek, focusArea);
    } else {
      structure = _getScientificSplitStructure(user.daysPerWeek, user.experience);
    }

    List<RoutineDay> generatedDays = [];
    List<String> routineNotes = []; // Notas generales para la rutina

    // 3. Construir Días (El Motor Principal)
    for (var i = 0; i < structure.length; i++) {
      var dayTemplate = structure[i];
      List<RoutineExercise> selectedExercises = [];
      Set<String> usedIds = {}; // Evitar duplicados en el mismo día
      double estimatedDuration = 0.0; // Cronómetro en minutos

      // --- A. SELECCIÓN DE EJERCICIOS ---
      for (var slot in dayTemplate['slots']) {
        Exercise? selected;

        // ESTRATEGIA DE SELECCIÓN (Informe Sección 5: Simetría)
        // 1. Si el usuario tiene asimetría, intentamos buscar una variante UNILATERAL del patrón requerido.
        if (user.hasAsymmetry) {
           selected = _findSymmetryVariant(availableExercises, slot, usedIds);
        }

        // 2. Si no hay asimetría o no se encontró variante unilateral, buscamos el ejercicio estándar.
        if (selected == null) {
           selected = _findStandardExercise(availableExercises, slot, usedIds);
        }

        if (selected != null) {
          // --- B. CÁLCULO DE VOLUMEN (Informe Sección 2: Fisiología) ---
          var volumeData = _calculateVolumeAndIntensity(
            user, 
            selected, 
            dayTemplate['type'] ?? 'Standard'
          );

          // Calcular Costo Temporal (Sección 4.1 del Informe)
          double slotTime = selected.timeCost * (volumeData['sets'] as int);
          estimatedDuration += slotTime;

          // Generar Instrucción Personalizada
          String instruction = volumeData['note'];
          if (user.hasAsymmetry && selected.symmetryScore >= 7) {
            instruction = "⚠️ LEY DEL LADO DÉBIL: Empieza con tu pierna/brazo IZQUIERDO. Haz las reps hasta el fallo, luego iguala con el derecho sin pasarte.";
          }

          selectedExercises.add(
            RoutineExercise(
              exerciseId: selected.id, 
              sets: volumeData['sets'], 
              reps: volumeData['reps'],
              rpe: volumeData['rpe'],
              restTimeSeconds: volumeData['rest'],
              note: instruction,
            ),
          );
          usedIds.add(selected.id);
        }
      }

      // --- C. GESTIÓN DEL TIEMPO (Informe Sección 4.2: Compresión) ---
      bool timeCompressed = false;
      if (estimatedDuration > user.timeAvailable) {
        // Nivel 1 de Compresión: Superseries en accesorios/aislamiento
        for (var exRoutine in selectedExercises) {
           var exData = availableExercises.firstWhere((e) => e.id == exRoutine.exerciseId);
           // Si es aislamiento, reducimos descanso drásticamente
           if (exData.mechanic == 'isolation') {
             exRoutine.restTimeSeconds = 30; 
             exRoutine.note = (exRoutine.note ?? "") + " [SUPERSERIE: Descanso corto para ahorrar tiempo]";
           }
        }
        timeCompressed = true;
      }

      generatedDays.add(
        RoutineDay(
          id: "day_${DateTime.now().millisecondsSinceEpoch}_$i",
          name: dayTemplate['name'] + (timeCompressed ? " (Optimizado)" : ""),
          targetMuscles: List<String>.from(dayTemplate['muscles']),
          exercises: selectedExercises,
        ),
      );
    }

    // --- D. NOTAS FINALES DE LA RUTINA ---
    if (user.hasAsymmetry) {
      routineNotes.add("✅ Protocolo de Simetría Activo: Se han priorizado ejercicios unilaterales.");
    }
    if (user.timeAvailable < 60) {
      routineNotes.add("⏱️ Protocolo de Tiempo: Rutina condensada para encajar en ${user.timeAvailable} min.");
    }

    // Generar nombre descriptivo
    String routineName = _generateRoutineName(user.daysPerWeek, focusArea, user.goal);

    return WeeklyRoutine(
      id: "routine_${DateTime.now().millisecondsSinceEpoch}",
      name: routineName,
      days: generatedDays,
      createdAt: DateTime.now(),
      isActive: true,
      // Podrías agregar un campo 'description' al modelo WeeklyRoutine en el futuro para guardar routineNotes.join('\n')
    );
  }

  // ==========================================
  // MOTORES DE BÚSQUEDA Y LÓGICA (PRIVATE)
  // ==========================================

  // Busca variantes con alto puntaje de simetría (Unilaterales)
  static Exercise? _findSymmetryVariant(List<Exercise> all, dynamic slot, Set<String> used) {
    String patternNeeded = "";
    String muscleNeeded = "";

    // Decodificar qué patrón buscamos
    if (slot is String) {
       // Si el slot pide un ID (ej: 'squat_barbell'), buscamos qué patrón tiene ese ID
       var original = all.firstWhere((e) => e.id == slot, orElse: () => all.first);
       patternNeeded = original.movementPattern;
       muscleNeeded = original.muscleGroup;
    } else if (slot is Map) {
       patternNeeded = slot['pattern'] ?? "";
       muscleNeeded = slot['muscle'] ?? "";
    }

    // Buscar sustituto UNILATERAL (SymmetryScore >= 8)
    var candidates = all.where((ex) => 
      (ex.movementPattern == patternNeeded || (patternNeeded.isEmpty && ex.muscleGroup == muscleNeeded)) &&
      ex.muscleGroup == muscleNeeded &&
      ex.symmetryScore >= 8 && // FILTRO CRÍTICO
      !used.contains(ex.id)
    ).toList();

    if (candidates.isNotEmpty) {
      // Priorizar compuestos si existen (ej: Búlgara antes que Extensión Unilateral)
      candidates.sort((a, b) => b.mechanic == 'compound' ? 1 : -1);
      return candidates.first;
    }
    return null;
  }

  // Búsqueda estándar (Intenta ID exacto, luego Patrón, luego Grupo Muscular)
  static Exercise? _findStandardExercise(List<Exercise> all, dynamic slot, Set<String> used) {
     if (slot is String) {
        try {
          // Intento 1: ID Exacto disponible
          return all.firstWhere((e) => e.id == slot && !used.contains(e.id));
        } catch (e) {
          // Intento 2: Sustituto por Patrón (ej: No tengo barra, busco mancuerna)
          var original = all.firstWhere((e) => e.id == slot, orElse: () => all.first);
          return _findSubstitute(all, original.movementPattern, original.muscleGroup, used);
        }
     } else if (slot is Map) {
        // Intento 3: Slot genérico (ej: "Empuje Horizontal")
        return _findSubstitute(all, slot['pattern'], slot['muscle'], used);
     }
     return null;
  }

  static Exercise? _findSubstitute(List<Exercise> available, String? pattern, String muscle, Set<String> used) {
    // 1. Coincidencia Perfecta
    var candidates = available.where((ex) => 
      ex.movementPattern == pattern && 
      ex.muscleGroup == muscle && 
      !used.contains(ex.id)
    ).toList();

    // 2. Coincidencia solo de Músculo (si no hay patrón exacto, ej: máquina rara)
    if (candidates.isEmpty) {
      candidates = available.where((ex) => 
        ex.muscleGroup == muscle && 
        !used.contains(ex.id)
      ).toList();
    }

    if (candidates.isNotEmpty) {
      // Ordenar: Compuestos primero, luego Aislamiento (Salvo que busquemos aislamiento explícitamente)
      candidates.sort((a, b) {
         if (a.mechanic == 'compound' && b.mechanic == 'isolation') return -1;
         if (a.mechanic == 'isolation' && b.mechanic == 'compound') return 1;
         return 0;
      });
      return candidates.first;
    }
    return null;
  }

  // --- CÁLCULO CIENTÍFICO DE CARGA (Informe Sección 2.3) ---
  static Map<String, dynamic> _calculateVolumeAndIntensity(
    UserProfile user, 
    Exercise exercise, 
    String sessionType
  ) {
    int sets = 3;
    String reps = "8-12";
    String rpe = "8 (2 RIR)";
    int rest = 90;
    String note = "";

    bool isCompound = exercise.mechanic == 'compound';

    // LÓGICA DE FUERZA
    if (user.goal == TrainingGoal.strength || sessionType == 'Strength') {
      if (isCompound) {
        sets = 4; // Volumen óptimo fuerza
        reps = "3-6"; // Rango neural
        rpe = "8.5 (1-2 RIR)";
        rest = 180; // 3 min para resíntesis ATP
        note = "Prioridad: Mover la carga rápido (Intención Explosiva).";
      } else {
        // Accesorios en día de fuerza
        sets = 3;
        reps = "8-10";
        rest = 120;
        note = "Apoyo para los levantamientos principales.";
      }
    } 
    // LÓGICA DE HIPERTROFIA
    else if (user.goal == TrainingGoal.hypertrophy || sessionType == 'Hypertrophy') {
      if (isCompound) {
        sets = (user.experience == Experience.advanced) ? 4 : 3;
        reps = "6-10";
        rpe = "8 (2 RIR)";
        rest = 120; // 2 min
        note = "Controla la fase excéntrica (bajada) durante 3 segundos.";
      } else {
        // Aislamiento / Metabólico
        sets = 3;
        reps = "12-15";
        rpe = "9 (1 RIR)"; // Cerca del fallo
        rest = 60; // Estrés metabólico
        note = "Enfócate en la conexión mente-músculo y el bombeo.";
      }
    } 
    // RESISTENCIA / METABÓLICO
    else {
        sets = 3;
        reps = "15-20";
        rest = 45;
        rpe = "7-8";
        note = "Ritmo constante, minimiza el descanso.";
    }

    // Ajuste para Principiantes (Evitar daño muscular excesivo al inicio)
    if (user.experience == Experience.beginner) {
      if (exercise.primaryMechanism == 'damage') { // Ej: Peso Muerto Rumano
         sets = 2; // Reducir volumen inicial
         note += " Foco en técnica, no llegues al fallo total.";
      }
    }

    return {'sets': sets, 'reps': reps, 'rpe': rpe, 'rest': rest, 'note': note};
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  static List<Exercise> _filterExercisesByLocation(List<Exercise> all, TrainingLocation location) {
    if (location == TrainingLocation.gym) return all;
    return all.where((ex) => 
      ['Corporal', 'Mancuernas', 'Banda', 'Banco/Silla', 'Barra Dominadas', 'Mancuerna'].contains(ex.equipment)
    ).toList();
  }

  static bool _isSpecificFocus(String focus) {
    return !['Full Body', 'Upper/Lower', 'Push/Pull/Legs', 'Equilibrado'].contains(focus);
  }

  static String _generateRoutineName(int days, String focus, TrainingGoal goal) {
    String goalStr = goal == TrainingGoal.strength ? "Fuerza" : "Hipertrofia";
    if (_isSpecificFocus(focus)) return "Especialización $focus ($days Días)";
    
    switch (days) {
      case 2: return "Minimalista A/B ($goalStr)";
      case 3: return "Full Body Ondulante ($goalStr)";
      case 4: return "Torso / Pierna ($goalStr)";
      case 5: return "Híbrida Estética ($goalStr)";
      case 6: return "PPL Alto Volumen ($goalStr)";
      default: return "Plan Personalizado";
    }
  }

  // ==========================================
  // ESTRUCTURAS CIENTÍFICAS (CORE DEL INFORME)
  // ==========================================
  
  static List<Map<String, dynamic>> _getScientificSplitStructure(int days, Experience level) {
    // Estos templates usan IDs de ejercicios "Ideales".
    // El algoritmo los sustituirá automáticamente si el usuario no tiene el equipo
    // o si tiene asimetrías activadas.
    switch (days) {
      case 1:
      case 2:
        // INFORME 5.1: "El Minimalista Eficiente" (Full Body A/B)
        return [
          {
            'name': 'Día A: Sentadilla & Empuje',
            'type': 'Strength',
            'muscles': ['Cuádriceps', 'Pecho', 'Espalda', 'Hombros'],
            'slots': [
              'squat_barbell',         // Sentadilla (Patrón Knee Dominant)
              'bench_press_barbell',   // Empuje Horizontal
              'row_barbell',           // Tracción Horizontal
              'ohp_barbell',           // Empuje Vertical
              'calf_raise_standing'    // Accesorio
            ]
          },
          {
            'name': 'Día B: Bisagra & Tracción',
            'type': 'Hypertrophy',
            'muscles': ['Isquios', 'Cuádriceps', 'Espalda', 'Pecho'],
            'slots': [
              'deadlift_conv',         // Bisagra (Hip Dominant)
              'bulgarian_split_squat', // Unilateral (Gran simetría)
              'lat_pulldown',          // Tracción Vertical
              'dips_bench',            // Empuje Vertical
              'face_pull'              // Salud Hombro
            ]
          }
        ];

      case 3:
        // INFORME 5.2: "Frecuencia Óptima" (Full Body Ondulante)
        return [
          {
            'name': 'Día 1: Tensión (Pesado)',
            'type': 'Strength',
            'muscles': ['Todo'],
            'slots': ['squat_barbell', 'bench_press_barbell', 'row_barbell', 'rdl_barbell', 'curl_barbell']
          },
          {
            'name': 'Día 2: Hipertrofia A',
            'type': 'Hypertrophy',
            'muscles': ['Todo'],
            'slots': ['leg_press', 'bench_press_incline', 'lat_pulldown', 'hip_thrust_barbell', 'pushdown_cable']
          },
          {
            'name': 'Día 3: Hipertrofia B / Metabólico',
            'type': 'Metabolic',
            'muscles': ['Todo'],
            'slots': ['lunge_barbell', 'ohp_db', 'row_seated', 'leg_extension', 'lat_raise']
          }
        ];

      case 4:
        // INFORME 2.3.2: Upper / Lower
        return [
          {
            'name': 'Lunes: Torso A (Fuerza)',
            'type': 'Strength',
            'muscles': ['Pecho', 'Espalda', 'Hombros'],
            'slots': ['bench_press_barbell', 'row_barbell', 'ohp_barbell', 'pullup', 'skullcrusher_ez']
          },
          {
            'name': 'Martes: Pierna A (Sentadilla)',
            'type': 'Strength',
            'muscles': ['Cuádriceps', 'Isquios'],
            'slots': ['squat_barbell', 'rdl_barbell', 'leg_press', 'calf_raise_standing', 'plank']
          },
          {
            'name': 'Jueves: Torso B (Hipertrofia)',
            'type': 'Hypertrophy',
            'muscles': ['Pecho', 'Espalda', 'Hombros'],
            'slots': ['bench_press_incline', 'lat_pulldown', 'db_press_flat', 'row_db_one_arm', 'lat_raise']
          },
          {
            'name': 'Viernes: Pierna B (Unilateral)',
            'type': 'Hypertrophy',
            'muscles': ['Glúteos', 'Isquios', 'Cuádriceps'],
            'slots': ['deadlift_sumo', 'bulgarian_split_squat', 'leg_extension', 'leg_curl', 'hanging_leg_raise']
          }
        ];

      case 5:
        // INFORME 5.3: "El Híbrido Estético" (Upper/Lower + PPL)
        return [
          {'name': 'Día 1: Torso (Fuerza)', 'type': 'Strength', 'muscles': ['Pecho', 'Espalda'], 'slots': ['ohp_barbell', 'pullup', 'bench_press_barbell', 'row_barbell']},
          {'name': 'Día 2: Pierna (Fuerza)', 'type': 'Strength', 'muscles': ['Pierna'], 'slots': ['squat_barbell', 'rdl_barbell', 'leg_press', 'calf_raise_standing']},
          {'name': 'Día 3: Empuje (Hipertrofia)', 'type': 'Hypertrophy', 'muscles': ['Pecho', 'Hombros', 'Tríceps'], 'slots': ['bench_press_incline', 'db_press_flat', 'lat_raise', 'tricep_pushdown_rope']},
          {'name': 'Día 4: Tracción (Hipertrofia)', 'type': 'Hypertrophy', 'muscles': ['Espalda', 'Bíceps'], 'slots': ['lat_pulldown', 'row_seated', 'pullover_db', 'curl_db']},
          {'name': 'Día 5: Pierna & Glúteo', 'type': 'Hypertrophy', 'muscles': ['Glúteos', 'Femoral'], 'slots': ['deadlift_sumo', 'hip_thrust_barbell', 'lunge_barbell', 'leg_curl']}
        ];

      case 6:
      default:
        // INFORME 5.4: "PPL Alto Volumen"
        return [
          {'name': 'Push A', 'type': 'Strength', 'muscles': ['Pecho', 'Hombros'], 'slots': ['bench_press_barbell', 'ohp_barbell', 'dips_chest', 'skullcrusher_ez', 'lat_raise']},
          {'name': 'Pull A', 'type': 'Strength', 'muscles': ['Espalda', 'Bíceps'], 'slots': ['deadlift_conv', 'pullup', 'row_barbell', 'curl_barbell', 'face_pull']},
          {'name': 'Legs A', 'type': 'Strength', 'muscles': ['Cuádriceps'], 'slots': ['squat_barbell', 'leg_press', 'leg_extension', 'calf_raise_standing', 'plank']},
          {'name': 'Push B', 'type': 'Hypertrophy', 'muscles': ['Pecho', 'Hombros'], 'slots': ['bench_press_incline', 'db_press_flat', 'arnold_press', 'tricep_pushdown_rope', 'lat_raise']},
          {'name': 'Pull B', 'type': 'Hypertrophy', 'muscles': ['Espalda', 'Bíceps'], 'slots': ['lat_pulldown', 'row_db_one_arm', 'pullover_db', 'curl_incline_db', 'curl_hammer']},
          {'name': 'Legs B', 'type': 'Hypertrophy', 'muscles': ['Isquios', 'Glúteo'], 'slots': ['rdl_barbell', 'bulgarian_split_squat', 'leg_curl', 'hip_thrust_barbell', 'calf_raise_seated']}
        ];
    }
  }

  // --- ESTRUCTURAS FOCALIZADAS (Especialización) ---
  // Mapeamos los patrones antiguos al nuevo sistema de slots
  static List<Map<String, dynamic>> _getFocusedStructure(int days, String focusArea) {
     
     // Ejemplo de lógica detallada para BÍCEPS (Como se solicitó antes)
     if (focusArea == 'Bíceps') {
       return List.generate(days, (i) => {
         'name': 'Espec. Bíceps Día ${i+1}',
         'type': 'Hypertrophy',
         'muscles': ['Bíceps'],
         'slots': [
            'chinup', // Tracción vertical (Gran activador)
            'curl_barbell', // Básico pesado
            'curl_incline_db', // Cabeza larga (Estiramiento)
            'curl_hammer', // Braquial
            'preacher_curl', // Cabeza corta (Acortamiento)
            'row_barbell', // Estímulo secundario
         ]
       });
     }

     // Fallback genérico para otros músculos: Creamos slots genéricos basados en el músculo
     // Esto asegura que el algoritmo busque ejercicios de ese grupo.
     return List.generate(days, (i) => {
       'name': 'Foco en $focusArea (Día ${i+1})',
       'type': 'Hypertrophy',
       'muscles': [focusArea],
       'slots': List.generate(6, (j) => {'pattern': '', 'muscle': focusArea})
     });
  }
}