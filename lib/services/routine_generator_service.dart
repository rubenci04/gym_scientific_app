import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/routine_model.dart';

class RoutineGeneratorService {
  
  static Future<void> generateAndSaveRoutine(UserProfile user) async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');
    final allExercises = exerciseBox.values.toList();

    // 1. Filtrar ejercicios según Ubicación
    final availableExercises = _filterExercisesByLocation(allExercises, user.location);

    // 2. Determinar Estructura
    final structure = _getSplitStructure(user.daysPerWeek);

    // 3. Crear Días
    List<RoutineDay> generatedDays = [];
    
    for (var dayTemplate in structure) {
      List<String> selectedExerciseIds = [];
      
      // Usamos un Set para evitar ejercicios repetidos el mismo día
      Set<String> usedIds = {};

      for (var pattern in dayTemplate['patterns']) {
        // Buscamos candidatos que coincidan con el patrón O el grupo muscular
        var candidates = availableExercises.where((ex) => 
          (ex.movementPattern == pattern || dayTemplate['muscles'].contains(ex.muscleGroup)) &&
          !usedIds.contains(ex.id) // Evitar duplicados
        ).toList();

        if (candidates.isNotEmpty) {
          candidates.shuffle(); // Variedad aleatoria
          final selected = candidates.first;
          selectedExerciseIds.add(selected.id);
          usedIds.add(selected.id);
        }
      }

      generatedDays.add(RoutineDay(
        id: "day_${generatedDays.length + 1}", 
        name: dayTemplate['name'], 
        targetMuscles: dayTemplate['muscles'], 
        exerciseIds: selectedExerciseIds
      ));
    }

    // 4. Guardar Rutina
    final newRoutine = WeeklyRoutine(
      id: "routine_${DateTime.now().millisecondsSinceEpoch}",
      name: "Plan ${user.daysPerWeek} Días - ${_getLocationName(user.location)}",
      days: generatedDays,
      createdAt: DateTime.now(),
    );

    var routineBox = Hive.box<WeeklyRoutine>('routineBox');
    await routineBox.put('currentRoutine', newRoutine);
  }

  static String _getLocationName(TrainingLocation loc) {
    return loc == TrainingLocation.gym ? "Gym" : "Casa";
  }

  static List<Exercise> _filterExercisesByLocation(List<Exercise> all, TrainingLocation location) {
    if (location == TrainingLocation.gym) return all;
    return all.where((ex) {
      return ex.equipment == 'Corporal' || 
             ex.equipment == 'Mancuernas' || 
             ex.equipment == 'Banco/Silla' ||
             ex.equipment == 'Barra Dominadas';
    }).toList();
  }

  // AUMENTAMOS LA CANTIDAD DE PATRONES POR DÍA (6-7 Ejercicios)
  static List<Map<String, dynamic>> _getSplitStructure(int days) {
    switch (days) {
      case 2:
        return [
          {'name': 'Full Body A', 'muscles': ['Todo'], 'patterns': ['Sentadilla', 'Empuje Horizontal', 'Tracción Vertical', 'Bisagra', 'Empuje Vertical', 'Aislamiento', 'Puente']},
          {'name': 'Full Body B', 'muscles': ['Todo'], 'patterns': ['Zancada', 'Empuje Vertical', 'Tracción Horizontal', 'Puente', 'Empuje Horizontal', 'Aislamiento', 'Tracción Vertical']},
        ];
      case 3:
        return [
          {'name': 'Full Body Fuerza', 'muscles': ['Todo'], 'patterns': ['Sentadilla', 'Empuje Horizontal', 'Tracción Horizontal', 'Empuje Vertical', 'Bisagra', 'Aislamiento']},
          {'name': 'Full Body Hipertrofia', 'muscles': ['Todo'], 'patterns': ['Bisagra', 'Empuje Inclinado', 'Tracción Vertical', 'Zancada', 'Aislamiento', 'Aislamiento']},
          {'name': 'Full Body Metabólico', 'muscles': ['Todo'], 'patterns': ['Sentadilla', 'Empuje Vertical', 'Tracción Horizontal', 'Puente', 'Aislamiento', 'Aislamiento']},
        ];
      case 4: 
        return [
          {'name': 'Torso A (Fuerza)', 'muscles': ['Pecho', 'Espalda'], 'patterns': ['Empuje Horizontal', 'Tracción Horizontal', 'Empuje Vertical', 'Tracción Vertical', 'Aislamiento', 'Aislamiento']},
          {'name': 'Pierna A (Cuádriceps)', 'muscles': ['Cuádriceps', 'Gemelo'], 'patterns': ['Sentadilla', 'Zancada', 'Sentadilla', 'Aislamiento', 'Aislamiento', 'Puente']},
          {'name': 'Torso B (Hipertrofia)', 'muscles': ['Hombros', 'Brazos'], 'patterns': ['Empuje Inclinado', 'Tracción Vertical', 'Empuje Vertical', 'Aislamiento', 'Aislamiento', 'Aislamiento']},
          {'name': 'Pierna B (Cadena Post.)', 'muscles': ['Isquios', 'Glúteo'], 'patterns': ['Bisagra', 'Puente', 'Bisagra', 'Zancada', 'Aislamiento', 'Aislamiento']},
        ];
      case 5:
        return [
          {'name': 'Empuje (Push)', 'muscles': ['Pecho', 'Hombros', 'Tríceps'], 'patterns': ['Empuje Horizontal', 'Empuje Vertical', 'Empuje Inclinado', 'Aislamiento', 'Aislamiento', 'Aislamiento']},
          {'name': 'Tracción (Pull)', 'muscles': ['Espalda', 'Bíceps'], 'patterns': ['Tracción Vertical', 'Tracción Horizontal', 'Tracción Vertical', 'Aislamiento', 'Aislamiento', 'Bisagra']},
          {'name': 'Pierna (Legs)', 'muscles': ['Cuádriceps', 'Isquios'], 'patterns': ['Sentadilla', 'Bisagra', 'Zancada', 'Puente', 'Aislamiento', 'Aislamiento']},
          {'name': 'Torso Completo', 'muscles': ['Todo el Torso'], 'patterns': ['Empuje Horizontal', 'Tracción Vertical', 'Empuje Vertical', 'Tracción Horizontal', 'Aislamiento', 'Aislamiento']},
          {'name': 'Pierna & Glúteo', 'muscles': ['Glúteo', 'Gemelo'], 'patterns': ['Zancada', 'Puente', 'Sentadilla', 'Bisagra', 'Aislamiento', 'Aislamiento']},
        ];
      default:
        return _getSplitStructure(3);
    }
  }
}