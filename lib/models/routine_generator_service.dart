import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/routine_model.dart';

class RoutineGeneratorService {
  
  // Función principal que llama la UI
  static Future<void> generateAndSaveRoutine(UserProfile user) async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');
    final allExercises = exerciseBox.values.toList();

    // 1. Filtrar ejercicios según Ubicación (Casa vs Gym)
    final availableExercises = _filterExercisesByLocation(allExercises, user.location);

    // 2. Determinar Estructura (Split) según días disponibles
    final structure = _getSplitStructure(user.daysPerWeek);

    // 3. Llenar cada día con ejercicios
    List<RoutineDay> generatedDays = [];
    
    for (var dayTemplate in structure) {
      List<String> selectedExerciseIds = [];

      // Para cada patrón de movimiento requerido en ese día, buscamos un ejercicio
      for (var pattern in dayTemplate['patterns']) {
        // Buscamos ejercicios que coincidan con el patrón y el grupo muscular deseado
        var candidates = availableExercises.where((ex) => 
          ex.movementPattern == pattern || dayTemplate['muscles'].contains(ex.muscleGroup)
        ).toList();

        if (candidates.isNotEmpty) {
          // Aquí podríamos añadir lógica más compleja de priorización (ej: ejercicios compuestos primero)
          // Por ahora, tomamos el primero disponible o aleatorio para variar
          candidates.shuffle();
          selectedExerciseIds.add(candidates.first.id);
        }
      }

      generatedDays.add(RoutineDay(
        id: "day_${generatedDays.length + 1}", 
        name: dayTemplate['name'], 
        targetMuscles: dayTemplate['muscles'], 
        exerciseIds: selectedExerciseIds
      ));
    }

    // 4. Crear el objeto Rutina
    final newRoutine = WeeklyRoutine(
      id: "routine_${DateTime.now().millisecondsSinceEpoch}",
      name: "Plan ${user.daysPerWeek} Días - ${_getLocationName(user.location)}",
      days: generatedDays,
      createdAt: DateTime.now(),
    );

    // 5. Guardar en Hive
    // Usaremos una caja separada 'routineBox' o guardaremos en userBox. 
    // Para simplificar, crearemos una caja nueva en main.dart
    var routineBox = await Hive.openBox<WeeklyRoutine>('routineBox');
    await routineBox.put('currentRoutine', newRoutine);
  }

  // --- AYUDANTES (Helpers) ---

  static String _getLocationName(TrainingLocation loc) {
    return loc == TrainingLocation.gym ? "Gimnasio" : "Casa";
  }

  static List<Exercise> _filterExercisesByLocation(List<Exercise> all, TrainingLocation location) {
    if (location == TrainingLocation.gym) return all; // En Gym vale todo

    // En Casa filtramos lo que requiere máquinas o poleas estrictas
    return all.where((ex) {
      // Permitimos: Corporal, Mancuernas (asumiendo que tiene), Banda elástica (si hubiera)
      return ex.equipment == 'Corporal' || 
             ex.equipment == 'Mancuernas' || 
             ex.equipment == 'Banco/Silla' ||
             ex.equipment == 'Barra Dominadas'; // Asumimos barra básica en casa
    }).toList();
  }

  // Define la "plantilla" de qué se entrena cada día
  static List<Map<String, dynamic>> _getSplitStructure(int days) {
    switch (days) {
      case 2:
        return [
          {'name': 'Full Body A', 'muscles': ['Todo el cuerpo'], 'patterns': ['Sentadilla', 'Empuje Horizontal', 'Tracción Vertical', 'Bisagra']},
          {'name': 'Full Body B', 'muscles': ['Todo el cuerpo'], 'patterns': ['Zancada', 'Empuje Vertical', 'Tracción Horizontal', 'Puente']},
        ];
      case 3:
        return [
          {'name': 'Full Body Fuerza', 'muscles': ['Todo'], 'patterns': ['Sentadilla', 'Empuje Horizontal', 'Tracción Horizontal']},
          {'name': 'Full Body Hipertrofia', 'muscles': ['Todo'], 'patterns': ['Bisagra', 'Empuje Vertical', 'Tracción Vertical']},
          {'name': 'Full Body Metabólico', 'muscles': ['Todo'], 'patterns': ['Zancada', 'Aislamiento', 'Aislamiento']},
        ];
      case 4: 
        return [ // Torso / Pierna
          {'name': 'Torso A (Fuerza)', 'muscles': ['Pecho', 'Espalda'], 'patterns': ['Empuje Horizontal', 'Tracción Horizontal', 'Empuje Vertical']},
          {'name': 'Pierna A (Cuádriceps)', 'muscles': ['Cuádriceps', 'Gemelo'], 'patterns': ['Sentadilla', 'Zancada', 'Aislamiento']},
          {'name': 'Torso B (Hipertrofia)', 'muscles': ['Hombros', 'Brazos'], 'patterns': ['Empuje Inclinado', 'Tracción Vertical', 'Aislamiento']},
          {'name': 'Pierna B (Cadena Post.)', 'muscles': ['Isquios', 'Glúteo'], 'patterns': ['Bisagra', 'Puente', 'Aislamiento']},
        ];
      case 5:
        return [ // Híbrido PPL + Upper/Lower
          {'name': 'Empuje (Push)', 'muscles': ['Pecho', 'Hombros', 'Tríceps'], 'patterns': ['Empuje Horizontal', 'Empuje Vertical', 'Aislamiento']},
          {'name': 'Tracción (Pull)', 'muscles': ['Espalda', 'Bíceps'], 'patterns': ['Tracción Vertical', 'Tracción Horizontal', 'Aislamiento']},
          {'name': 'Pierna (Legs)', 'muscles': ['Cuádriceps', 'Isquios'], 'patterns': ['Sentadilla', 'Bisagra']},
          {'name': 'Torso Completo', 'muscles': ['Todo el Torso'], 'patterns': ['Empuje Horizontal', 'Tracción Vertical']},
          {'name': 'Pierna & Glúteo', 'muscles': ['Glúteo', 'Gemelo'], 'patterns': ['Zancada', 'Puente']},
        ];
      default: // Por defecto 3 días
        return _getSplitStructure(3);
    }
  }
}