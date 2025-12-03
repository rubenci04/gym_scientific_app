import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise_model.dart';

class SeedDataService {
  static Future<void> initializeExercises() async {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');

    if (exerciseBox.isEmpty) {
      final List<Exercise> allExercises = [
        // --- PECHO (GIMNASIO) ---
        Exercise(id: 'bench_press', name: 'Press Banca con Barra', muscleGroup: 'Pecho', equipment: 'Barra', movementPattern: 'Empuje Horizontal'),
        Exercise(id: 'db_press_flat', name: 'Press Plano Mancuernas', muscleGroup: 'Pecho', equipment: 'Mancuernas', movementPattern: 'Empuje Horizontal'),
        Exercise(id: 'db_press_incline', name: 'Press Inclinado Mancuernas', muscleGroup: 'Pecho', equipment: 'Mancuernas', movementPattern: 'Empuje Horizontal'),
        Exercise(id: 'cable_crossover', name: 'Cruce de Poleas', muscleGroup: 'Pecho', equipment: 'Polea', movementPattern: 'Aislamiento'),

        // --- PECHO (CASA) ---
        Exercise(id: 'pushup', name: 'Flexiones de Brazos (Push-ups)', muscleGroup: 'Pecho', equipment: 'Corporal', movementPattern: 'Empuje Horizontal'),
        Exercise(id: 'pushup_incline', name: 'Flexiones Inclinadas', muscleGroup: 'Pecho', equipment: 'Corporal', movementPattern: 'Empuje Horizontal'),
        Exercise(id: 'floor_press', name: 'Press de Suelo con Mancuernas/Botellas', muscleGroup: 'Pecho', equipment: 'Mancuernas', movementPattern: 'Empuje Horizontal'),

        // --- ESPALDA (GIMNASIO) ---
        Exercise(id: 'lat_pulldown', name: 'Jalón al Pecho', muscleGroup: 'Espalda', equipment: 'Polea', movementPattern: 'Tracción Vertical'),
        Exercise(id: 'row_barbell', name: 'Remo con Barra', muscleGroup: 'Espalda', equipment: 'Barra', movementPattern: 'Tracción Horizontal'),
        Exercise(id: 'row_seated', name: 'Remo Gironda', muscleGroup: 'Espalda', equipment: 'Polea', movementPattern: 'Tracción Horizontal'),

        // --- ESPALDA (CASA) ---
        Exercise(id: 'pullup_home', name: 'Dominadas', muscleGroup: 'Espalda', equipment: 'Barra Dominadas', movementPattern: 'Tracción Vertical'),
        Exercise(id: 'row_db_one_arm', name: 'Remo Unilateral con Mancuerna', muscleGroup: 'Espalda', equipment: 'Mancuernas', movementPattern: 'Tracción Horizontal'),

        // --- PIERNAS (GIMNASIO) ---
        Exercise(id: 'squat_barbell', name: 'Sentadilla Trasera', muscleGroup: 'Cuádriceps', equipment: 'Barra', movementPattern: 'Sentadilla'),
        Exercise(id: 'leg_press', name: 'Prensa de Piernas', muscleGroup: 'Cuádriceps', equipment: 'Máquina', movementPattern: 'Sentadilla'),
        Exercise(id: 'leg_extension', name: 'Sillón de Cuádriceps', muscleGroup: 'Cuádriceps', equipment: 'Máquina', movementPattern: 'Aislamiento'),
        Exercise(id: 'deadlift_conv', name: 'Peso Muerto Convencional', muscleGroup: 'Isquios', equipment: 'Barra', movementPattern: 'Bisagra'),

        // --- PIERNAS (CASA) ---
        Exercise(id: 'squat_air', name: 'Sentadilla al Aire', muscleGroup: 'Cuádriceps', equipment: 'Corporal', movementPattern: 'Sentadilla'),
        Exercise(id: 'squat_goblet', name: 'Sentadilla Goblet', muscleGroup: 'Cuádriceps', equipment: 'Mancuernas', movementPattern: 'Sentadilla'),
        Exercise(id: 'lunge_body', name: 'Zancadas', muscleGroup: 'Cuádriceps', equipment: 'Corporal', movementPattern: 'Zancada'),
        Exercise(id: 'rdl_db', name: 'Peso Muerto Rumano Mancuernas', muscleGroup: 'Isquios', equipment: 'Mancuernas', movementPattern: 'Bisagra'),

        // --- HOMBROS Y BRAZOS ---
        Exercise(id: 'ohp_barbell', name: 'Press Militar', muscleGroup: 'Hombros', equipment: 'Barra', movementPattern: 'Empuje Vertical'),
        Exercise(id: 'ohp_db', name: 'Press Hombro Mancuernas', muscleGroup: 'Hombros', equipment: 'Mancuernas', movementPattern: 'Empuje Vertical'),
        Exercise(id: 'lat_raise', name: 'Elevaciones Laterales', muscleGroup: 'Hombros', equipment: 'Mancuernas', movementPattern: 'Aislamiento'),
        Exercise(id: 'curl_db', name: 'Curl de Bíceps', muscleGroup: 'Bíceps', equipment: 'Mancuernas', movementPattern: 'Aislamiento'),
        Exercise(id: 'dips_bench', name: 'Fondos en Banco', muscleGroup: 'Tríceps', equipment: 'Banco/Silla', movementPattern: 'Empuje Vertical'),
      ];

      await exerciseBox.addAll(allExercises);
      debugPrint("✅ Seed completado.");
    }
  }
}