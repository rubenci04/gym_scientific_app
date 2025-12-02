import 'package:hive/hive.dart';

// Esta línea es necesaria para que el generador cree el archivo complementario
part 'user_model.g.dart';

// Definimos los tipos de Somatotipo para la clasificación científica [cite: 15]
@HiveType(typeId: 0)
enum Somatotype {
  @HiveField(0)
  ectomorph,
  @HiveField(1)
  mesomorph,
  @HiveField(2)
  endomorph,
  @HiveField(3)
  undefined,
}

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  double weight; // en kg

  @HiveField(3)
  double height; // en cm

  @HiveField(4)
  String gender;

  // Datos para algoritmo Heath-Carter [cite: 17]
  @HiveField(5)
  double wristCircumference; 

  @HiveField(6)
  double ankleCircumference;

  @HiveField(7)
  Somatotype somatotype;

  @HiveField(8)
  double tdee; // Gasto energético diario total calculado [cite: 34]

  UserProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    this.wristCircumference = 0.0,
    this.ankleCircumference = 0.0,
    this.somatotype = Somatotype.undefined,
    this.tdee = 0.0,
  });
}