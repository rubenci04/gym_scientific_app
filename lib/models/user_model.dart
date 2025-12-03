import 'package:hive/hive.dart';

part 'user_model.g.dart';

// --- NUEVOS ENUMS ---
@HiveType(typeId: 6)
enum TrainingGoal {
  @HiveField(0)
  hypertrophy, // Ganar Masa
  @HiveField(1)
  strength,    // Fuerza
  @HiveField(2)
  weightLoss,  // Perder Peso/Definir
  @HiveField(3)
  generalHealth, // Salud General
  @HiveField(4)
  endurance // Resistencia
}

@HiveType(typeId: 7)
enum TrainingLocation {
  @HiveField(0)
  gym,  // Gimnasio Completo
  @HiveField(1)
  home, // Casa (Mancuernas/Corporal)
}

@HiveType(typeId: 8)
enum Experience {
  @HiveField(0)
  beginner,
  @HiveField(1)
  intermediate,
  @HiveField(2)
  advanced,
}

// --- CLASIFICACIÓN SOMATOTIPO ---
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
  double weight;

  @HiveField(3)
  double height;

  @HiveField(4)
  String gender;

  @HiveField(5)
  double wristCircumference; 

  @HiveField(6)
  double ankleCircumference;

  @HiveField(7)
  Somatotype somatotype;

  @HiveField(8)
  double tdee;

  // --- NUEVOS CAMPOS ---
  @HiveField(9)
  int daysPerWeek; 

  @HiveField(10)
  TrainingGoal goal; 

  @HiveField(11)
  TrainingLocation location; 

  @HiveField(12)
  String focusArea; 

  @HiveField(13)
  DateTime? birthDate;

  @HiveField(14)
  Experience experience;

  // Optional: ID field if needed by services, though HiveObject has 'key'
  // But ProgressiveOverloadService uses user.id, so let's add it if it's not the key.
  // Actually HiveObject has .key, but the service code uses .id. 
  // Let's check if I should add String id. The service code: UserProfile(id: user.id, ...)
  // The previous file didn't have 'id'. 
  // I will add 'id' as well to be safe, or check if it was there. 
  // Looking at previous view_file of user_model.dart (Step 79), there was NO 'id' field.
  // But ProgressiveOverloadService uses it. I should add it.
  @HiveField(15)
  String id;

  UserProfile({
    this.id = '', // Default empty or generate uuid
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    this.wristCircumference = 0.0,
    this.ankleCircumference = 0.0,
    this.somatotype = Somatotype.undefined,
    this.tdee = 0.0,
    this.daysPerWeek = 3,
    this.goal = TrainingGoal.generalHealth,
    this.location = TrainingLocation.gym,
    this.focusArea = 'Equilibrado',
    this.birthDate,
    this.experience = Experience.beginner,
  });
}