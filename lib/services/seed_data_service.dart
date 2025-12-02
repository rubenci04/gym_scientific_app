import 'package:hive/hive.dart';
import '../models/exercise_model.dart';

class SeedDataService {
  static Future<void> initializeExercises() async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');

    // Solo llenamos si la caja está vacía (primera vez que se abre la app)
    if (exerciseBox.isEmpty) {
      final List<Exercise> initialExercises = [
        Exercise(
          id: 'sq_barbell',
          name: 'Sentadilla con Barra (Trasera)',
          muscleGroup: 'Piernas (Cuádriceps)',
          equipment: 'Barra',
          movementPattern: 'Sentadilla',
        ),
        Exercise(
          id: 'bp_barbell',
          name: 'Press de Banca Plano',
          muscleGroup: 'Pecho',
          equipment: 'Barra',
          movementPattern: 'Empuje Horizontal',
        ),
        Exercise(
          id: 'dl_conventional',
          name: 'Peso Muerto Convencional',
          muscleGroup: 'Espalda/Isquios',
          equipment: 'Barra',
          movementPattern: 'Bisagra de Cadera',
        ),
        Exercise(
          id: 'ohp_barbell',
          name: 'Press Militar (De Pie)',
          muscleGroup: 'Hombros',
          equipment: 'Barra',
          movementPattern: 'Empuje Vertical',
        ),
        Exercise(
          id: 'pullup',
          name: 'Dominadas',
          muscleGroup: 'Espalda (Dorsales)',
          equipment: 'Peso Corporal',
          movementPattern: 'Tracción Vertical',
        ),
        Exercise(
          id: 'row_barbell',
          name: 'Remo con Barra',
          muscleGroup: 'Espalda (Grosor)',
          equipment: 'Barra',
          movementPattern: 'Tracción Horizontal',
        ),
        // Agrega más ejercicios aquí según necesites
      ];

      // Guardamos todos de una vez
      await exerciseBox.addAll(initialExercises);
      print("✅ Base de datos de ejercicios inicializada con éxito.");
    } else {
      print("ℹ️ Los ejercicios ya existen. Saltando seed.");
    }
  }
}