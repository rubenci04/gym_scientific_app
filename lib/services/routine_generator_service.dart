import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/routine_model.dart';

class RoutineGeneratorService {
  
  // // NOTA PARA MÍ: Función principal que orquesta la creación y guardado.
  // // Recibe el 'focusArea' que ahora puede ser un músculo específico.
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

    // // NOTA PARA MÍ: Primero filtro qué ejercicios tiene disponibles el usuario (Gym o Casa)
    final availableExercises = _filterExercisesByLocation(
      allExercises,
      user.location,
    );

    // // NOTA PARA MÍ: Aquí determino la estructura. Si el usuario eligió un músculo específico
    // // (ej: 'Bíceps'), llamo a _getFocusedStructure que contiene la nueva lógica detallada.
    List<Map<String, dynamic>> structure;
    if (focusArea != 'Full Body' && focusArea != 'Upper/Lower' && focusArea != 'Push/Pull/Legs') {
      structure = _getFocusedStructure(user.daysPerWeek, focusArea);
    } else {
      // Si es una división clásica (Full Body, Torso/Pierna, etc)
      structure = _getSplitStructure(user.daysPerWeek, user.goal);
    }

    List<RoutineDay> generatedDays = [];

    for (var i = 0; i < structure.length; i++) {
      var dayTemplate = structure[i];
      List<RoutineExercise> selectedExercises = [];
      Set<String> usedIds = {};

      // // NOTA PARA MÍ: Ajusto series y reps según el objetivo científico.
      int sets;
      String reps;

      switch (user.goal) {
        case TrainingGoal.strength:
          sets = 4;
          reps = "3-6";
          break;
        case TrainingGoal.hypertrophy:
          sets = 3; // Volumen estándar para hipertrofia
          reps = "8-12";
          break;
        case TrainingGoal.endurance:
          sets = 3;
          reps = "15-20";
          break;
        default:
          sets = 3;
          reps = "8-12";
      }

      // // NOTA PARA MÍ: Este es el motor de selección. Itera sobre los "patrones" requeridos
      // // para el día y busca ejercicios que coincidan en la base de datos.
      for (var pattern in dayTemplate['patterns']) {
        var candidates = availableExercises.where((ex) {
          // 1. Filtro básico: ¿Ya se usó este ejercicio?
          if (usedIds.contains(ex.id)) return false;

          // 2. Lógica Específica "Aislamiento Músculo" (ej: 'Aislamiento Tríceps')
          if (pattern.startsWith('Aislamiento ') && pattern.split(' ').length > 1) {
             var target = pattern.split(' ')[1]; // Extrae "Tríceps"
             // Coincidencia laxa para encontrar el músculo
             return ex.muscleGroup.contains(target) || ex.targetMuscles.contains(target);
          }
          
          // 3. Lógica para Patrones Generales
          // Si el día tiene músculos definidos, priorizamos esos músculos
          bool matchesMuscle = false;
          if (dayTemplate['muscles'].contains('Todo')) {
             matchesMuscle = true;
          } else {
             matchesMuscle = dayTemplate['muscles'].contains(ex.muscleGroup);
          }
          
          if (pattern == 'Aislamiento') {
             // Priorizar ejercicios monoarticulares si es posible
             return matchesMuscle && (ex.movementPattern == 'Aislamiento' || ex.movementPattern == 'Extensión' || ex.movementPattern == 'Flexión');
          }
          
          if (pattern == 'Core') {
             return ex.muscleGroup == 'Core';
          }

          // Coincidencia estricta de patrón (ej: 'Sentadilla') O coincidencia de grupo muscular si es genérico
          bool matchesPattern = ex.movementPattern == pattern;
          
          return matchesPattern && matchesMuscle;
        }).toList();

        // Si la búsqueda estricta falla, intentamos una búsqueda más amplia (Fallback)
        if (candidates.isEmpty) {
           candidates = availableExercises.where((ex) {
             if (usedIds.contains(ex.id)) return false;
             if (dayTemplate['muscles'].contains('Todo')) return true;
             return dayTemplate['muscles'].contains(ex.muscleGroup);
           }).toList();
        }

        if (candidates.isNotEmpty) {
          // Barajar para dar variedad
          candidates.shuffle();
          final selected = candidates.first;
          
          // // NOTA PARA MÍ: Ajuste fino. Si es un ejercicio compuesto pesado (Sentadilla, Peso Muerto),
          // // aumento los sets y bajo reps si el objetivo es fuerza/hipertrofia.
          int currentSets = sets;
          String currentReps = reps;
          
          if (['Sentadilla', 'Peso Muerto', 'Press Banca'].any((name) => selected.name.contains(name))) {
             currentSets = (user.goal == TrainingGoal.strength) ? 5 : 4;
             currentReps = (user.goal == TrainingGoal.strength) ? "3-5" : "6-8";
          }

          selectedExercises.add(
            RoutineExercise(
              exerciseId: selected.id, 
              sets: currentSets, 
              reps: currentReps
            ),
          );
          usedIds.add(selected.id);
        }
      }

      generatedDays.add(
        RoutineDay(
          id: "day_${DateTime.now().millisecondsSinceEpoch}_$i",
          name: dayTemplate['name'], // Nombre corregido para que se vea bien
          targetMuscles: List<String>.from(dayTemplate['muscles']), // Aseguramos tipo correcto
          exercises: selectedExercises,
        ),
      );
    }

    return WeeklyRoutine(
      id: "routine_${DateTime.now().millisecondsSinceEpoch}",
      name: "Plan Científico: $focusArea",
      days: generatedDays,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  static String _getGoalName(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.hypertrophy: return "Hipertrofia";
      case TrainingGoal.strength: return "Fuerza";
      case TrainingGoal.endurance: return "Resistencia";
      default: return "General";
    }
  }

  static List<Exercise> _filterExercisesByLocation(
    List<Exercise> all,
    TrainingLocation location,
  ) {
    if (location == TrainingLocation.gym) return all;
    return all.where((ex) {
      return ex.equipment == 'Corporal' ||
          ex.equipment == 'Mancuernas' ||
          ex.equipment == 'Banda' || // Agregado Bandas
          ex.equipment == 'Banco/Silla' ||
          ex.equipment == 'Barra Dominadas';
    }).toList();
  }

  // // NOTA PARA MÍ: Aquí comienza la lógica nueva y masiva para los grupos musculares específicos.
  // // He expandido los 'patterns' para asegurar entre 6 y 8 ejercicios por sesión.
  static List<Map<String, dynamic>> _getFocusedStructure(int days, String focusArea) {
    List<Map<String, dynamic>> result = [];

    for (int i = 0; i < days; i++) {
      String dayNameSuffix = days > 1 ? " (Día ${i + 1})" : "";

      switch (focusArea) {
        // --- TREN SUPERIOR ---
        case 'Pectoral': // PECHO
          result.add({
            'name': 'Pectoral Legendario$dayNameSuffix',
            'muscles': ['Pecho', 'Tríceps'], // Incluyo tríceps como sinergista
            'patterns': [
              'Empuje Horizontal', // Press Banca o similar
              'Empuje Inclinado', // Press Inclinado (Clavicular)
              'Empuje Horizontal', // Máquina o variante
              'Empuje Declinado', // O Fondos (Inferior)
              'Aislamiento', // Aperturas/Cruce
              'Aislamiento', // Pec Deck
              'Aislamiento Tríceps', // Un toque de tríceps al final
            ],
          });
          break;

        case 'Dorsal': // ESPALDA
          result.add({
            'name': 'Espalda en V$dayNameSuffix',
            'muscles': ['Espalda', 'Bíceps', 'Trapecio'],
            'patterns': [
              'Bisagra', // Peso Muerto o Rack Pull (Densidad)
              'Tracción Vertical', // Dominadas o Jalones (Amplitud)
              'Tracción Horizontal', // Remo con Barra (Densidad)
              'Tracción Vertical', // Otro ángulo vertical
              'Tracción Horizontal', // Remo unilateral o máquina
              'Aislamiento Espalda', // Pullover o similar
              'Elevación', // Trapecio (Shrugs)
              'Aislamiento Bíceps', // Finalizador
            ],
          });
          break;

        case 'Hombros':
          result.add({
            'name': 'Hombros 3D$dayNameSuffix',
            'muscles': ['Hombros', 'Trapecio'],
            'patterns': [
              'Empuje Vertical', // Press Militar pesado
              'Empuje Vertical', // Press con mancuernas o Arnold
              'Aislamiento', // Elevaciones Laterales
              'Aislamiento', // Pájaros (Posterior)
              'Aislamiento', // Frontales o variantes
              'Tracción', // Face Pull (Salud del hombro)
              'Elevación', // Trapecio
            ],
          });
          break;

        case 'Bíceps':
          result.add({
            'name': 'Bíceps Masivos$dayNameSuffix',
            'muscles': ['Bíceps', 'Antebrazo', 'Espalda'], // Espalda para activar
            'patterns': [
              'Tracción Vertical', // Dominada Supina (Chin-up) - Gran constructor
              'Flexión', // Curl con Barra (Pesado)
              'Flexión', // Curl Martillo (Braquial)
              'Aislamiento', // Curl Inclinado (Cabeza larga)
              'Aislamiento', // Curl Predicador o Concentrado (Cabeza corta)
              'Flexión', // Curl Invertido o Zottman
              'Aislamiento Antebrazos', // Muñeca
            ],
          });
          break;

        case 'Tríceps':
          result.add({
            'name': 'Tríceps Herradura$dayNameSuffix',
            'muscles': ['Tríceps', 'Pecho'], // Pecho cerrado para activar
            'patterns': [
              'Empuje Horizontal', // Press Banca Agarre Cerrado
              'Empuje Vertical', // Fondos (Dips)
              'Extensión', // Rompecráneos o Francés
              'Empuje', // Polea (Pushdown)
              'Extensión', // Copa o Trasnuca (Cabeza larga)
              'Empuje', // Patada o Unilateral
            ],
          });
          break;
          
        case 'Trapecio':
           result.add({
            'name': 'Yugo de Trapecio$dayNameSuffix',
            'muscles': ['Trapecio', 'Hombros', 'Espalda'],
            'patterns': [
              'Bisagra', // Peso Muerto (Isométrico brutal para trapecio)
              'Elevación', // Encogimientos con Barra (Pesado)
              'Elevación', // Encogimientos con Mancuerna (Rango)
              'Tracción', // Face Pull
              'Transporte', // Paseo del Granjero (Farmer Walk)
              'Tracción Horizontal', // Remo al mentón (Upright Row)
            ],
          });
          break;

        // --- TREN INFERIOR ---
        case 'Cuádriceps':
          result.add({
            'name': 'Cuádriceps de Acero$dayNameSuffix',
            'muscles': ['Cuádriceps', 'Glúteos'],
            'patterns': [
              'Sentadilla', // El rey
              'Zancada', // Búlgara o Zancada
              'Empuje', // Prensa
              'Sentadilla', // Hack o Frontal
              'Aislamiento', // Sillón de Cuádriceps
              'Aislamiento', // Sillón (Altas reps)
              'Aislamiento Gemelo', // Gemelos de pie
            ],
          });
          break;

        case 'Isquios': // FEMORAL
          result.add({
            'name': 'Isquios (Femoral)$dayNameSuffix',
            'muscles': ['Isquiotibiales', 'Glúteos', 'Espalda Baja'],
            'patterns': [
              'Bisagra', // Peso Muerto Rumano (Pesado)
              'Flexión', // Curl Femoral Tumbado
              'Bisagra', // Buenos Días o PM Piernas Rígidas
              'Flexión', // Curl Nórdico o Sentado
              'Bisagra', // Hiperextensiones
              'Aislamiento Glúteo', // Patada (Complemento)
            ],
          });
          break;

        case 'Glúteos':
          result.add({
            'name': 'Glúteos Focus$dayNameSuffix',
            'muscles': ['Glúteos', 'Abductores', 'Isquiotibiales'],
            'patterns': [
              'Puente', // Hip Thrust (Pesado)
              'Sentadilla', // Sentadilla Sumo
              'Zancada', // Estocada Cruzada o Búlgara
              'Bisagra', // Peso Muerto Rumano
              'Extensión de Cadera', // Patada en Polea
              'Abducción', // Máquina de abducción o Almeja
              'Desplazamiento', // Monster Walk
            ],
          });
          break;

        case 'Gemelos':
          result.add({
            'name': 'Gemelos Diamante$dayNameSuffix',
            'muscles': ['Gemelos'],
            'patterns': [
              'Extensión', // De pie (Pesado)
              'Extensión', // Sentado (Sóleo)
              'Extensión', // Prensa
              'Salto', // Cuerda
              'Extensión', // Unilateral
            ],
          });
          break;
          
        case 'Aductores': // y Abductores
           result.add({
            'name': 'Pierna Interior/Exterior$dayNameSuffix',
            'muscles': ['Aductores', 'Abductores', 'Glúteos'],
            'patterns': [
              'Sentadilla', // Sumo (Gran activación aductor)
              'Aislamiento', // Máquina Aductora
              'Isométrico', // Copenhagen Plank
              'Abducción', // Máquina Abductora
              'Desplazamiento', // Monster Walk
              'Aislamiento', // Aductor Polea
            ],
          });
          break;

        // --- EXTRAS ---
        case 'Abdominales': // CORE
          result.add({
            'name': 'Core de Piedra$dayNameSuffix',
            'muscles': ['Core'],
            'patterns': [
              'Flexión', // Crunch o Elevación piernas
              'Isométrico', // Plancha
              'Rotación', // Giros Rusos o Leñador
              'Anti-extensión', // Rueda abdominal
              'Flexión', // Colgado
              'Isométrico', // Vacío abdominal (si existiera) o Plancha lateral
            ],
          });
          break;
          
        case 'Cardio':
           result.add({
            'name': 'Sesión Cardio$dayNameSuffix',
            'muscles': ['Cardio', 'Core'],
            'patterns': [
              'Carrera', 
              'Cíclico', 
              'Pedaleo', 
              'Core',
              'Isométrico'
            ],
          });
          break;

        default: // FALLBACK
          result.add({
            'name': 'Entrenamiento General',
            'muscles': ['Todo'],
            'patterns': ['Sentadilla', 'Empuje Horizontal', 'Tracción Vertical', 'Bisagra', 'Empuje Vertical', 'Aislamiento'],
          });
      }
    }
    return result;
  }

  // // NOTA PARA MÍ: Mantengo la lógica de división clásica (Full body, Torso/Pierna) 
  // // para cuando el usuario no pide un músculo específico.
  static List<Map<String, dynamic>> _getSplitStructure(
    int days,
    TrainingGoal goal,
  ) {
    if (goal == TrainingGoal.strength) {
       // Rutina de fuerza (Básicos, menos volumen de accesorios)
       return _getStrengthStructure(days);
    } else {
       // Rutina de hipertrofia/general (Más volumen y variedad)
       return _getHypertrophyStructure(days);
    }
  }

  // Estructuras para Fuerza
  static List<Map<String, dynamic>> _getStrengthStructure(int days) {
    switch (days) {
      case 1:
        return [
          {'name': 'Full Body Fuerza', 'muscles': ['Todo'], 'patterns': ['Sentadilla', 'Empuje Horizontal', 'Tracción Horizontal', 'Bisagra', 'Empuje Vertical', 'Core']},
        ];
      case 2:
         return [
          {'name': 'Torso Fuerza', 'muscles': ['Pecho', 'Espalda', 'Hombros'], 'patterns': ['Empuje Horizontal', 'Tracción Horizontal', 'Empuje Vertical', 'Tracción Vertical', 'Aislamiento']},
          {'name': 'Pierna Fuerza', 'muscles': ['Cuádriceps', 'Isquios'], 'patterns': ['Sentadilla', 'Bisagra', 'Zancada', 'Puente', 'Core']},
        ];
      case 3:
        return [
          {'name': 'Full Body A', 'muscles': ['Todo'], 'patterns': ['Sentadilla', 'Empuje Horizontal', 'Tracción Vertical', 'Aislamiento', 'Aislamiento', 'Core']},
          {'name': 'Full Body B', 'muscles': ['Todo'], 'patterns': ['Bisagra', 'Empuje Vertical', 'Tracción Horizontal', 'Aislamiento', 'Aislamiento', 'Core']},
          {'name': 'Full Body C', 'muscles': ['Todo'], 'patterns': ['Zancada', 'Fondos', 'Dominadas', 'Core', 'Aislamiento', 'Cardio']},
        ];
      case 4: // Upper/Lower x2
         return [
          {'name': 'Torso A', 'muscles': ['Pecho', 'Espalda'], 'patterns': ['Empuje Horizontal', 'Tracción Horizontal', 'Empuje Vertical', 'Aislamiento', 'Aislamiento', 'Core']},
          {'name': 'Pierna A', 'muscles': ['Cuádriceps', 'Isquios'], 'patterns': ['Sentadilla', 'Bisagra', 'Aislamiento', 'Core', 'Aislamiento Gemelo']},
          {'name': 'Torso B', 'muscles': ['Hombros', 'Brazos'], 'patterns': ['Empuje Vertical', 'Tracción Vertical', 'Aislamiento', 'Aislamiento', 'Aislamiento', 'Core']},
          {'name': 'Pierna B', 'muscles': ['Glúteos', 'Gemelo'], 'patterns': ['Puente', 'Zancada', 'Aislamiento', 'Core', 'Aislamiento Gemelo']},
        ];
      default:
        // Para 5+ días en fuerza, usar una PPL
        return _getHypertrophyStructure(days); 
    }
  }

  // Estructuras para Hipertrofia (Standard)
  static List<Map<String, dynamic>> _getHypertrophyStructure(int days) {
    switch (days) {
      case 1:
        return [
          {'name': 'Full Body', 'muscles': ['Todo'], 'patterns': ['Sentadilla', 'Empuje Horizontal', 'Tracción Vertical', 'Bisagra', 'Empuje Vertical', 'Aislamiento']},
        ];
      case 2:
        return [
          {'name': 'Torso', 'muscles': ['Pecho', 'Espalda', 'Hombros'], 'patterns': ['Empuje Horizontal', 'Tracción Vertical', 'Empuje Vertical', 'Tracción Horizontal', 'Aislamiento', 'Aislamiento']},
          {'name': 'Pierna', 'muscles': ['Cuádriceps', 'Isquios', 'Gemelo'], 'patterns': ['Sentadilla', 'Bisagra', 'Zancada', 'Puente', 'Aislamiento', 'Aislamiento']},
        ];
      case 3: // PPL Básico
        return [
          {'name': 'Empuje (Push)', 'muscles': ['Pecho', 'Hombros', 'Tríceps'], 'patterns': ['Empuje Horizontal', 'Empuje Vertical', 'Empuje Inclinado', 'Aislamiento Hombro', 'Aislamiento Tríceps', 'Aislamiento']},
          {'name': 'Tracción (Pull)', 'muscles': ['Espalda', 'Bíceps'], 'patterns': ['Tracción Vertical', 'Tracción Horizontal', 'Bisagra', 'Aislamiento Espalda', 'Aislamiento Bíceps', 'Core']},
          {'name': 'Pierna (Legs)', 'muscles': ['Cuádriceps', 'Isquios', 'Gemelo'], 'patterns': ['Sentadilla', 'Prensa', 'Bisagra', 'Zancada', 'Aislamiento Gemelo', 'Core']},
        ];
      case 4: // Torso/Pierna Frecuencia 2
        return [
          {'name': 'Torso Hipertrofia A', 'muscles': ['Pecho', 'Espalda'], 'patterns': ['Empuje Horizontal', 'Tracción Vertical', 'Empuje Inclinado', 'Aislamiento Bíceps', 'Aislamiento Tríceps', 'Aislamiento']},
          {'name': 'Pierna Hipertrofia A', 'muscles': ['Cuádriceps', 'Gemelo'], 'patterns': ['Sentadilla', 'Prensa', 'Zancada', 'Aislamiento Cuádriceps', 'Aislamiento Gemelo', 'Core']},
          {'name': 'Torso Hipertrofia B', 'muscles': ['Hombros', 'Espalda'], 'patterns': ['Empuje Vertical', 'Tracción Horizontal', 'Elevación', 'Aislamiento Hombro', 'Aislamiento', 'Core']},
          {'name': 'Pierna Hipertrofia B', 'muscles': ['Isquios', 'Glúteo'], 'patterns': ['Bisagra', 'Puente', 'Flexión', 'Aislamiento Glúteo', 'Core', 'Aislamiento Gemelo']},
        ];
      case 5: // PPL + Upper/Lower híbrido (Arnold Split modificado)
        return [
          {'name': 'Pecho y Espalda', 'muscles': ['Pecho', 'Espalda'], 'patterns': ['Empuje Horizontal', 'Tracción Horizontal', 'Empuje Inclinado', 'Tracción Vertical', 'Aislamiento', 'Aislamiento']},
          {'name': 'Piernas', 'muscles': ['Cuádriceps', 'Isquios'], 'patterns': ['Sentadilla', 'Bisagra', 'Prensa', 'Zancada', 'Aislamiento', 'Aislamiento']},
          {'name': 'Hombros y Brazos', 'muscles': ['Hombros', 'Brazos'], 'patterns': ['Empuje Vertical', 'Aislamiento Hombro', 'Aislamiento Bíceps', 'Aislamiento Tríceps', 'Elevación', 'Aislamiento']},
          {'name': 'Torso Pump', 'muscles': ['Pecho', 'Espalda'], 'patterns': ['Empuje', 'Tracción', 'Aislamiento', 'Aislamiento', 'Core', 'Cardio']},
          {'name': 'Pierna Pump', 'muscles': ['Pierna'], 'patterns': ['Sentadilla', 'Puente', 'Aislamiento', 'Aislamiento', 'Aislamiento', 'Core']},
        ];
      default: // 6 días PPL x2
        return [
          {'name': 'Push A', 'muscles': ['Pecho', 'Tríceps'], 'patterns': ['Empuje Horizontal', 'Empuje Vertical', 'Aislamiento Tríceps', 'Aislamiento Pecho', 'Aislamiento', 'Core']},
          {'name': 'Pull A', 'muscles': ['Espalda', 'Bíceps'], 'patterns': ['Tracción Vertical', 'Tracción Horizontal', 'Aislamiento Bíceps', 'Aislamiento Espalda', 'Elevación', 'Core']},
          {'name': 'Legs A', 'muscles': ['Cuádriceps'], 'patterns': ['Sentadilla', 'Zancada', 'Aislamiento Cuádriceps', 'Aislamiento Gemelo', 'Core', 'Cardio']},
          {'name': 'Push B', 'muscles': ['Hombros', 'Pecho'], 'patterns': ['Empuje Vertical', 'Empuje Inclinado', 'Aislamiento Hombro', 'Aislamiento Tríceps', 'Aislamiento', 'Core']},
          {'name': 'Pull B', 'muscles': ['Espalda', 'Trapecio'], 'patterns': ['Tracción Horizontal', 'Tracción Vertical', 'Elevación', 'Aislamiento Bíceps', 'Aislamiento Antebrazos', 'Core']},
          {'name': 'Legs B', 'muscles': ['Isquios', 'Glúteo'], 'patterns': ['Bisagra', 'Puente', 'Flexión', 'Aislamiento Glúteo', 'Aislamiento Gemelo', 'Cardio']},
        ];
    }
  }
}