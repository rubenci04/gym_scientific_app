import 'package:hive/hive.dart';

part 'history_model.g.dart';

// --- NIVEL 3: EL DETALLE DE LA SERIE ---
@HiveType(typeId: 3)
class WorkoutSet extends HiveObject {
  @HiveField(0)
  double weight; // Peso en kg

  @HiveField(1)
  int reps;

  @HiveField(2)
  double rpe; // Escala de Esfuerzo (1-10) o RIR. Clave para lo científico.

  @HiveField(3)
  bool isWarmUp; // ¿Es calentamiento?

  WorkoutSet({
    required this.weight,
    required this.reps,
    this.rpe = 0.0,
    this.isWarmUp = false,
  });
}

// --- NIVEL 2: EL EJERCICIO REALIZADO ---
@HiveType(typeId: 4)
class WorkoutExercise extends HiveObject {
  @HiveField(0)
  String exerciseId; // Referencia al ID del ejercicio del catálogo (ej: 'sq_barbell')

  @HiveField(1)
  String exerciseName; // Guardamos el nombre por si se borra del catálogo

  @HiveField(2)
  List<WorkoutSet> sets; // Lista de series realizadas

  @HiveField(3)
  String notes;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes = '',
  });
}

// --- NIVEL 1: LA SESIÓN DE ENTRENAMIENTO (DÍA) ---
@HiveType(typeId: 5)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String routineName; // Ej: "Día de Empuje A"

  @HiveField(2)
  List<WorkoutExercise> exercises; // Lista de ejercicios hechos hoy

  @HiveField(3)
  int durationInMinutes;

  @HiveField(4)
  double bodyweight; // Peso corporal ese día (para correlacionar fuerza/peso)

  WorkoutSession({
    required this.date,
    required this.routineName,
    required this.exercises,
    this.durationInMinutes = 0,
    this.bodyweight = 0.0,
  });
}