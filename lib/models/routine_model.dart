import 'package:hive/hive.dart';

part 'routine_model.g.dart';

@HiveType(typeId: 8)
class RoutineDay extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name; // ej: "Día 1: Torso"

  @HiveField(2)
  List<String> targetMuscles;

  @HiveField(3)
  List<RoutineExercise> exercises;

  RoutineDay({
    required this.id,
    required this.name,
    required this.targetMuscles,
    required this.exercises,
  });
}

@HiveType(typeId: 9)
class WeeklyRoutine extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name; // ej: "Rutina Híbrida 4 Días"

  @HiveField(2)
  List<RoutineDay> days;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  bool isActive;

  WeeklyRoutine({
    required this.id,
    required this.name,
    required this.days,
    required this.createdAt,
    this.isActive = false,
  });
}

@HiveType(typeId: 11)
class RoutineExercise extends HiveObject {
  @HiveField(0)
  String exerciseId;

  @HiveField(1)
  int sets;

  @HiveField(2)
  String reps;

  @HiveField(3)
  String? rpe;

  @HiveField(4)
  int? restTimeSeconds;

  @HiveField(5)
  String? note;

  RoutineExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.rpe,
    this.restTimeSeconds,
    this.note,
  });
}
