import 'package:hive/hive.dart';

part 'exercise_model.g.dart';

@HiveType(typeId: 2)
class Exercise extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String muscleGroup; // Ej: "Pecho", "Cuádriceps"

  @HiveField(3)
  String equipment; // Ej: "Mancuernas", "Barra", "Máquina"

  @HiveField(4)
  String movementPattern; // Ej: "Empuje Horizontal" 

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.movementPattern,
  });
}