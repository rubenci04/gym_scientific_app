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
  List<String> exerciseIds; 

  RoutineDay({
    required this.id,
    required this.name,
    required this.targetMuscles,
    required this.exerciseIds,
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

  WeeklyRoutine({
    required this.id,
    required this.name,
    required this.days,
    required this.createdAt,
  });
}