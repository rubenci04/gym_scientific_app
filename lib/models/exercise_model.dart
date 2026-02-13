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
  bool isBilateral; // TRUE = Barra/Máquina (dos lados a la vez). FALSE = Unilateral (Mancuerna/Banda).

  @HiveField(14, defaultValue: '')
  String alternativeExercise; // Ejercicio alternativo simple

  @HiveField(15, defaultValue: null)
  String? localImagePath; // Ruta local de la imagen personalizada

  // --- CAMPOS DEL MOTOR FISIOLÓGICO Y FILTRADO AVANZADO ---

  // NOTA PARA MI: Defino si es 'compound' (multiarticular) o 'isolation' (monoarticular).
  // Vital para el algoritmo: si el usuario solo tiene 1 hora, no debo eliminar estos ejercicios de la rutina.
  @HiveField(16, defaultValue: 'compound')
  String mechanic; 

  // NOTA PARA MI: Tiempo estimado en MINUTOS (Ejecución + Descanso).
  // Ej: Sentadilla = 5.0 min, Curl = 2.5 min. Con esto voy a sumar el total para respetar si el usuario eligió entrenar 1 hora, 1.5 hs o 2 hs.
  @HiveField(17, defaultValue: 3.0)
  double timeCost;

  // NOTA PARA MI: Puntuación del 0 al 10 sobre qué tan bueno es para corregir asimetrías.
  // Si el usuario marca que quiere corregir desequilibrios, el algoritmo buscará ejercicios con puntaje alto (ej: Sentadilla Búlgara = 10).
  @HiveField(18, defaultValue: 0)
  int symmetryScore;

  // NOTA PARA MI: Driver principal de hipertrofia.
  // Valores: 'tension' (Cargas altas/Fuerza), 'metabolic' (Bombeo/Salud), 'damage' (Estiramiento).
  // Esto me permite cruzar el objetivo del usuario (Fuerza vs Hipertrofia vs Salud) y darle el ejercicio exacto.
  @HiveField(19, defaultValue: 'tension')
  String primaryMechanism;

  // NOTA PARA MI: Grupo de sustitución biomecánica estricta.
  // Ej: 'horizontal_press'. Si una máquina está ocupada o el usuario entrena en casa, busco otro del mismo grupo.
  @HiveField(20, defaultValue: null)
  String? substitutionGroup;

  // NOTA PARA MI: Agrego esta lista para saber inmediatamente dónde se puede hacer.
  // Ej: ['gym'] para Prensa a 45 grados, o ['gym', 'home'] para Flexiones. Facilita enormemente el filtro de entorno.
  @HiveField(21, defaultValue: ['gym'])
  List<String> suitableEnvironments;

  // NOTA PARA MI: Flag directa para ejercicios con peso corporal.
  // Si el usuario entrena en casa y no tiene equipo, el algoritmo prioriza los que tengan este valor en true.
  @HiveField(22, defaultValue: false)
  bool isBodyweight;

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
    this.localImagePath,
    this.mechanic = 'compound',
    this.timeCost = 3.0,
    this.symmetryScore = 0,
    this.primaryMechanism = 'tension',
    this.substitutionGroup,
    this.suitableEnvironments = const ['gym'],
    this.isBodyweight = false,
  });
}