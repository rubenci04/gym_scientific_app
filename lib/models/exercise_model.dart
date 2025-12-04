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

  @HiveField(5, defaultValue: '')
  String videoUrl; // URL de YouTube o GIF

  @HiveField(6, defaultValue: '')
  String description; // Descripción detallada para principiantes

  @HiveField(7, defaultValue: [])
  List<String> tips; // Consejos de ejecución

  @HiveField(8, defaultValue: [])
  List<String> commonMistakes; // Errores comunes

  @HiveField(9, defaultValue: 'Intermedio')
  String difficulty; // 'Principiante', 'Intermedio', 'Avanzado'

  @HiveField(10, defaultValue: [])
  List<String> targetMuscles; // Lista completa de músculos trabajados

  @HiveField(11, defaultValue: [])
  List<String> secondaryMuscles; // Músculos secundarios

  @HiveField(12, defaultValue: [])
  List<String> variations; // IDs de variaciones del ejercicio

  @HiveField(13, defaultValue: true)
  bool isBilateral; // ¿Es bilateral o unilateral?

  @HiveField(14, defaultValue: '')
  String alternativeExercise; // Ejercicio alternativo si no hay equipo

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.movementPattern,
    this.videoUrl = '',
    this.description = '',
    this.tips = const [],
    this.commonMistakes = const [],
    this.difficulty = 'Intermedio',
    this.targetMuscles = const [],
    this.secondaryMuscles = const [],
    this.variations = const [],
    this.isBilateral = true,
    this.alternativeExercise = '',
  });
}
