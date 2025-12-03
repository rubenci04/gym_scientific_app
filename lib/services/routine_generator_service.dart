import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/routine_model.dart';

class RoutineGeneratorService {
  static Future<void> generateAndSaveRoutine(UserProfile user) async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');
    final allExercises = exerciseBox.values.toList();

    final availableExercises = _filterExercisesByLocation(
      allExercises,
      user.location,
    );

    final structure = _getSplitStructure(user.daysPerWeek, user.goal);

    List<RoutineDay> generatedDays = [];

    for (var i = 0; i < structure.length; i++) {
      var dayTemplate = structure[i];
      List<String> selectedExerciseIds = [];
      Set<String> usedIds = {};

      // Definir series y repeticiones según el objetivo
      int sets;
      String reps;

      switch (user.goal) {
        case TrainingGoal.strength:
          sets = 4;
          reps = "4-6";
          break;
        case TrainingGoal.hypertrophy:
          sets = 3;
          reps = "8-12";
          break;
        case TrainingGoal.endurance:
          sets = 2;
          reps = "15-20";
          break;
        default:
          sets = 3;
          reps = "8-12";
      }

      for (var pattern in dayTemplate['patterns']) {
        var candidates = availableExercises
            .where(
              (ex) =>
                  (ex.movementPattern == pattern ||
                      dayTemplate['muscles'].contains(ex.muscleGroup)) &&
                  !usedIds.contains(ex.id),
            )
            .toList();

        if (candidates.isNotEmpty) {
          candidates.shuffle();
          final selected = candidates.first;
          selectedExerciseIds.add(selected.id);
          usedIds.add(selected.id);
        }
      }

      generatedDays.add(
        RoutineDay(
          id: "day_${generatedDays.length + 1}",
          name: "Día ${i + 1}: ${dayTemplate['name']}",
          targetMuscles: dayTemplate['muscles'],
          exerciseIds: selectedExerciseIds,
          // Asignar series y reps a cada día
          sets: sets,
          reps: reps,
        ),
      );
    }

    final newRoutine = WeeklyRoutine(
      id: "routine_${DateTime.now().millisecondsSinceEpoch}",
      name:
          "Plan ${user.daysPerWeek} Días - ${_getGoalName(user.goal)} - ${_getLocationName(user.location)}",
      days: generatedDays,
      createdAt: DateTime.now(),
    );

    var routineBox = Hive.box<WeeklyRoutine>('routineBox');
    await routineBox.put('currentRoutine', newRoutine);
  }

  static String _getGoalName(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.hypertrophy:
        return "Hipertrofia";
      case TrainingGoal.strength:
        return "Fuerza";
      case TrainingGoal.endurance:
        return "Resistencia";
      default:
        return "General";
    }
  }

  static String _getLocationName(TrainingLocation loc) {
    return loc == TrainingLocation.gym ? "Gym" : "Casa";
  }

  static List<Exercise> _filterExercisesByLocation(
    List<Exercise> all,
    TrainingLocation location,
  ) {
    if (location == TrainingLocation.gym) return all;
    return all.where((ex) {
      return ex.equipment == 'Corporal' ||
          ex.equipment == 'Mancuernas' ||
          ex.equipment == 'Banco/Silla' ||
          ex.equipment == 'Barra Dominadas';
    }).toList();
  }

  static List<Map<String, dynamic>> _getSplitStructure(
    int days,
    TrainingGoal goal,
  ) {
    // Lógica principal para determinar la estructura basada en días y objetivo
    switch (goal) {
      case TrainingGoal.strength:
        return _getStrengthStructure(days);
      case TrainingGoal.hypertrophy:
        return _getHypertrophyStructure(days);
      case TrainingGoal.endurance:
      default:
        return _getGeneralStructure(days);
    }
  }

  // Estructuras para Fuerza (menos volumen, más frecuencia en básicos)
  static List<Map<String, dynamic>> _getStrengthStructure(int days) {
    switch (days) {
      case 1:
        return [
          {
            'name': 'Full Body Fuerza',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Horizontal',
              'Tracción Horizontal',
              'Bisagra',
              'Empuje Vertical',
            ],
          },
        ];
      case 2:
        return [
          {
            'name': 'Full Body A',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Horizontal',
              'Tracción Horizontal',
              'Empuje Vertical',
              'Bisagra',
            ],
          },
          {
            'name': 'Full Body B',
            'muscles': ['Todo'],
            'patterns': [
              'Bisagra',
              'Empuje Vertical',
              'Tracción Vertical',
              'Sentadilla',
              'Empuje Horizontal',
            ],
          },
        ];
      case 3:
        return [
          {
            'name': 'Full Body Pesado',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Horizontal',
              'Tracción Horizontal',
              'Aislamiento Opcional',
            ],
          },
          {
            'name': 'Full Body Liviano',
            'muscles': ['Todo'],
            'patterns': [
              'Bisagra',
              'Empuje Vertical',
              'Tracción Vertical',
              'Zancada',
              'Aislamiento Opcional',
            ],
          },
          {
            'name': 'Full Body Pesado',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Horizontal',
              'Tracción Horizontal',
              'Aislamiento Opcional',
            ],
          },
        ];
      case 4:
        return [
          {
            'name': 'Torso Superior Foco Fuerza',
            'muscles': ['Pecho', 'Espalda'],
            'patterns': [
              'Empuje Horizontal',
              'Tracción Horizontal',
              'Empuje Vertical',
              'Tracción Vertical',
              'Aislamiento Biceps',
            ],
          },
          {
            'name': 'Pierna Foco Fuerza',
            'muscles': ['Cuádriceps', 'Isquios'],
            'patterns': [
              'Sentadilla',
              'Bisagra',
              'Zancada',
              'Puente',
              'Aislamiento Gemelo',
            ],
          },
          {
            'name': 'Torso Superior Foco Reps',
            'muscles': ['Hombros', 'Brazos'],
            'patterns': [
              'Empuje Vertical',
              'Tracción Vertical',
              'Empuje Horizontal',
              'Tracción Horizontal',
              'Aislamiento Triceps',
            ],
          },
          {
            'name': 'Pierna Foco Reps',
            'muscles': ['Isquios', 'Glúteo'],
            'patterns': [
              'Bisagra',
              'Sentadilla',
              'Puente',
              'Zancada',
              'Aislamiento Femoral',
            ],
          },
        ];
      case 5:
        return [
          {
            'name': 'Torso Superior',
            'muscles': ['Pecho', 'Espalda'],
            'patterns': [
              'Empuje Horizontal',
              'Tracción Horizontal',
              'Empuje Vertical',
              'Tracción Vertical',
            ],
          },
          {
            'name': 'Pierna',
            'muscles': ['Cuádriceps', 'Isquios'],
            'patterns': ['Sentadilla', 'Bisagra', 'Zancada', 'Puente'],
          },
          {
            'name': 'Push',
            'muscles': ['Pecho', 'Hombros', 'Tríceps'],
            'patterns': [
              'Empuje Horizontal',
              'Empuje Vertical',
              'Aislamiento Tríceps',
            ],
          },
          {
            'name': 'Pull',
            'muscles': ['Espalda', 'Bíceps'],
            'patterns': [
              'Tracción Vertical',
              'Tracción Horizontal',
              'Aislamiento Bíceps',
            ],
          },
          {
            'name': 'Legs',
            'muscles': ['Cuádriceps', 'Isquios'],
            'patterns': ['Sentadilla', 'Bisagra', 'Aislamiento Gemelo'],
          },
        ];
      case 6:
        return [
          {
            'name': 'Push Fuerza',
            'muscles': ['Pecho', 'Hombros', 'Tríceps'],
            'patterns': [
              'Empuje Horizontal',
              'Empuje Vertical',
              'Aislamiento Tríceps',
            ],
          },
          {
            'name': 'Pull Fuerza',
            'muscles': ['Espalda', 'Bíceps'],
            'patterns': [
              'Tracción Vertical',
              'Tracción Horizontal',
              'Aislamiento Bíceps',
            ],
          },
          {
            'name': 'Legs Fuerza',
            'muscles': ['Cuádriceps', 'Isquios'],
            'patterns': ['Sentadilla', 'Bisagra', 'Aislamiento Gemelo'],
          },
          {
            'name': 'Push Hipertrofia',
            'muscles': ['Pecho', 'Hombros', 'Tríceps'],
            'patterns': [
              'Empuje Inclinado',
              'Aislamiento Hombro',
              'Aislamiento Tríceps',
            ],
          },
          {
            'name': 'Pull Hipertrofia',
            'muscles': ['Espalda', 'Bíceps'],
            'patterns': [
              'Tracción Horizontal',
              'Aislamiento Espalda',
              'Aislamiento Bíceps',
            ],
          },
          {
            'name': 'Legs Hipertrofia',
            'muscles': ['Cuádriceps', 'Isquios'],
            'patterns': ['Zancada', 'Puente', 'Aislamiento Femoral'],
          },
        ];
      case 7:
      default:
        var structure = _getStrengthStructure(6);
        structure.add({
          'name': 'Puntos Débiles / Técnica',
          'muscles': ['Todo'],
          'patterns': ['Aislamiento', 'Aislamiento', 'Aislamiento', 'Core'],
        });
        return structure;
    }
  }

  // Estructuras para Hipertrofia (más volumen y aislamiento)
  static List<Map<String, dynamic>> _getHypertrophyStructure(int days) {
    switch (days) {
      case 1:
        return [
          {
            'name': 'Full Body',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Horizontal',
              'Tracción Vertical',
              'Bisagra',
              'Empuje Vertical',
              'Aislamiento',
            ],
          },
        ];
      case 2: // Para 2 días, Full-Body es mejor
        return [
          {
            'name': 'Full Body A',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Horizontal',
              'Tracción Vertical',
              'Bisagra',
              'Aislamiento',
              'Aislamiento',
            ],
          },
          {
            'name': 'Full Body B',
            'muscles': ['Todo'],
            'patterns': [
              'Zancada',
              'Empuje Vertical',
              'Tracción Horizontal',
              'Puente',
              'Aislamiento',
              'Aislamiento',
            ],
          },
        ];
      case 3:
        return [
          {
            'name': 'Empuje (Push)',
            'muscles': ['Pecho', 'Hombros', 'Tríceps'],
            'patterns': [
              'Empuje Horizontal',
              'Empuje Vertical',
              'Empuje Inclinado',
              'Aislamiento Pecho',
              'Aislamiento Hombro',
              'Aislamiento Tríceps',
            ],
          },
          {
            'name': 'Tracción (Pull)',
            'muscles': ['Espalda', 'Bíceps'],
            'patterns': [
              'Tracción Vertical',
              'Tracción Horizontal',
              'Tracción Vertical',
              'Bisagra',
              'Aislamiento Bíceps',
              'Aislamiento Espalda',
            ],
          },
          {
            'name': 'Pierna (Leg)',
            'muscles': ['Cuádriceps', 'Isquios'],
            'patterns': [
              'Sentadilla',
              'Zancada',
              'Bisagra',
              'Puente',
              'Aislamiento Cuádriceps',
              'Aislamiento Isquios',
            ],
          },
        ];
      case 4:
        return [
          {
            'name': 'Torso A (Pecho y Tríceps)',
            'muscles': ['Pecho', 'Tríceps'],
            'patterns': [
              'Empuje Horizontal',
              'Empuje Inclinado',
              'Aislamiento Pecho',
              'Empuje Vertical',
              'Aislamiento Tríceps',
              'Aislamiento Tríceps',
            ],
          },
          {
            'name': 'Pierna A (Cuádriceps y Gemelo)',
            'muscles': ['Cuádriceps', 'Gemelo'],
            'patterns': [
              'Sentadilla',
              'Zancada',
              'Sentadilla',
              'Aislamiento Cuádriceps',
              'Aislamiento Gemelo',
              'Aislamiento Gemelo',
            ],
          },
          {
            'name': 'Torso B (Espalda y Bíceps)',
            'muscles': ['Espalda', 'Bíceps'],
            'patterns': [
              'Tracción Vertical',
              'Tracción Horizontal',
              'Tracción Horizontal',
              'Bisagra Ligera',
              'Aislamiento Bíceps',
              'Aislamiento Bíceps',
            ],
          },
          {
            'name': 'Pierna B (Isquios y Glúteo)',
            'muscles': ['Isquios', 'Glúteo'],
            'patterns': [
              'Bisagra',
              'Puente',
              'Bisagra',
              'Zancada',
              'Aislamiento Femoral',
              'Aislamiento Glúteo',
            ],
          },
        ];
      case 5:
        return [
          {
            'name': 'Pecho',
            'muscles': ['Pecho'],
            'patterns': [
              'Empuje Horizontal',
              'Empuje Inclinado',
              'Aislamiento',
              'Aislamiento',
              'Empuje Horizontal',
            ],
          },
          {
            'name': 'Espalda',
            'muscles': ['Espalda'],
            'patterns': [
              'Tracción Vertical',
              'Tracción Horizontal',
              'Tracción Vertical',
              'Tracción Horizontal',
              'Bisagra',
            ],
          },
          {
            'name': 'Hombros y Brazos',
            'muscles': ['Hombros', 'Bíceps', 'Tríceps'],
            'patterns': [
              'Empuje Vertical',
              'Aislamiento Hombro',
              'Aislamiento Bíceps',
              'Aislamiento Tríceps',
              'Aislamiento Bíceps',
              'Aislamiento Tríceps',
            ],
          },
          {
            'name': 'Pierna (Cuádriceps)',
            'muscles': ['Cuádriceps', 'Gemelo'],
            'patterns': [
              'Sentadilla',
              'Zancada',
              'Aislamiento Cuádriceps',
              'Aislamiento Cuádriceps',
              'Aislamiento Gemelo',
            ],
          },
          {
            'name': 'Pierna (Isquios y Glúteo)',
            'muscles': ['Isquios', 'Glúteo'],
            'patterns': [
              'Bisagra',
              'Puente',
              'Aislamiento Femoral',
              'Aislamiento Glúteo',
              'Zancada',
            ],
          },
        ];
      case 6:
        return [
          {
            'name': 'Push A',
            'muscles': ['Pecho', 'Hombros', 'Tríceps'],
            'patterns': [
              'Empuje Horizontal',
              'Empuje Vertical',
              'Aislamiento Tríceps',
            ],
          },
          {
            'name': 'Pull A',
            'muscles': ['Espalda', 'Bíceps'],
            'patterns': [
              'Tracción Vertical',
              'Tracción Horizontal',
              'Aislamiento Bíceps',
            ],
          },
          {
            'name': 'Legs A',
            'muscles': ['Cuádriceps', 'Isquios'],
            'patterns': ['Sentadilla', 'Bisagra', 'Aislamiento Cuádriceps'],
          },
          {
            'name': 'Push B',
            'muscles': ['Pecho', 'Hombros', 'Tríceps'],
            'patterns': [
              'Empuje Inclinado',
              'Aislamiento Hombro',
              'Aislamiento Tríceps',
            ],
          },
          {
            'name': 'Pull B',
            'muscles': ['Espalda', 'Bíceps'],
            'patterns': [
              'Tracción Horizontal',
              'Aislamiento Espalda',
              'Aislamiento Bíceps',
            ],
          },
          {
            'name': 'Legs B',
            'muscles': ['Cuádriceps', 'Isquios'],
            'patterns': ['Zancada', 'Puente', 'Aislamiento Femoral'],
          },
        ];
      case 7:
      default:
        var structure = _getHypertrophyStructure(6);
        structure.add({
          'name': 'Puntos Débiles',
          'muscles': ['Todo'],
          'patterns': ['Aislamiento', 'Aislamiento', 'Aislamiento', 'Core'],
        });
        return structure;
    }
  }

  // Estructuras Generales / Resistencia (más Full-Body y metabólico)
  static List<Map<String, dynamic>> _getGeneralStructure(int days) {
    switch (days) {
      case 1:
        return [
          {
            'name': 'Full Body',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Horizontal',
              'Tracción Vertical',
              'Bisagra',
              'Empuje Vertical',
              'Aislamiento',
            ],
          },
        ];
      case 2:
        return [
          {
            'name': 'Full Body A',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Horizontal',
              'Tracción Vertical',
              'Bisagra',
              'Empuje Vertical',
              'Aislamiento',
            ],
          },
          {
            'name': 'Full Body B',
            'muscles': ['Todo'],
            'patterns': [
              'Zancada',
              'Empuje Vertical',
              'Tracción Horizontal',
              'Puente',
              'Empuje Horizontal',
              'Aislamiento',
            ],
          },
        ];
      case 3:
        return [
          {
            'name': 'Full Body A',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Horizontal',
              'Tracción Horizontal',
              'Empuje Vertical',
              'Bisagra',
              'Aislamiento',
            ],
          },
          {
            'name': 'Full Body B',
            'muscles': ['Todo'],
            'patterns': [
              'Bisagra',
              'Empuje Inclinado',
              'Tracción Vertical',
              'Zancada',
              'Aislamiento',
              'Aislamiento',
            ],
          },
          {
            'name': 'Full Body C',
            'muscles': ['Todo'],
            'patterns': [
              'Sentadilla',
              'Empuje Vertical',
              'Tracción Horizontal',
              'Puente',
              'Aislamiento',
              'Aislamiento',
            ],
          },
        ];
      case 4:
        return [
          {
            'name': 'Torso A',
            'muscles': ['Pecho', 'Espalda'],
            'patterns': [
              'Empuje Horizontal',
              'Tracción Horizontal',
              'Empuje Vertical',
              'Tracción Vertical',
              'Aislamiento',
              'Aislamiento',
            ],
          },
          {
            'name': 'Pierna A',
            'muscles': ['Cuádriceps', 'Gemelo'],
            'patterns': [
              'Sentadilla',
              'Zancada',
              'Sentadilla',
              'Aislamiento',
              'Aislamiento',
              'Puente',
            ],
          },
          {
            'name': 'Torso B',
            'muscles': ['Hombros', 'Brazos'],
            'patterns': [
              'Empuje Inclinado',
              'Tracción Vertical',
              'Empuje Vertical',
              'Aislamiento',
              'Aislamiento',
              'Aislamiento',
            ],
          },
          {
            'name': 'Pierna B',
            'muscles': ['Isquios', 'Glúteo'],
            'patterns': [
              'Bisagra',
              'Puente',
              'Bisagra',
              'Zancada',
              'Aislamiento',
              'Aislamiento',
            ],
          },
        ];
      case 5:
        final structure = _getGeneralStructure(4);
        structure.add({
          'name': 'Full Body Metabólico',
          'muscles': ['Todo'],
          'patterns': [
            'Sentadilla',
            'Empuje',
            'Tracción',
            'Bisagra',
            'Aislamiento',
            'Aislamiento',
          ],
        });
        return structure;
      case 6:
        final structure6 = _getGeneralStructure(4);
        structure6.add({
          'name': 'Full Body A',
          'muscles': ['Todo'],
          'patterns': ['Sentadilla', 'Empuje', 'Tracción'],
        });
        structure6.add({
          'name': 'Full Body B',
          'muscles': ['Todo'],
          'patterns': ['Bisagra', 'Empuje', 'Tracción'],
        });
        return structure6;
      case 7:
      default:
        final structure7 = _getGeneralStructure(6);
        structure7.add({
          'name': 'Cardio + Core',
          'muscles': ['Abdominales'],
          'patterns': ['Core', 'Core', 'Core'],
        });
        return structure7;
    }
  }
}
