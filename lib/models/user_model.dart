import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
enum TrainingGoal {
  @HiveField(0)
  hypertrophy,
  @HiveField(1)
  strength,
  @HiveField(2)
  health,
  @HiveField(3)
  endurance,
  @HiveField(4)
  weightLoss,
  @HiveField(5)
  generalHealth,
}

@HiveType(typeId: 20)
enum TrainingLocation {
  @HiveField(0)
  gym,
  @HiveField(1)
  home,
}

@HiveType(typeId: 21)
enum Experience {
  @HiveField(0)
  beginner,
  @HiveField(1)
  intermediate,
  @HiveField(2)
  advanced,
}

@HiveType(typeId: 22)
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

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;
  @HiveField(1)
  int age;
  @HiveField(2)
  double weight;
  @HiveField(3)
  TrainingGoal goal;
  @HiveField(4)
  int daysPerWeek;
  @HiveField(5)
  int timeAvailable;
  @HiveField(6)
  TrainingLocation location;
  @HiveField(7)
  bool hasAsymmetry;
  @HiveField(8)
  Experience experience;
  @HiveField(9)
  double height;
  @HiveField(10)
  String gender;
  @HiveField(11)
  Somatotype somatotype;
  @HiveField(12)
  double wristCircumference;
  @HiveField(13)
  double ankleCircumference;
  @HiveField(14)
  String focusArea;
  @HiveField(15) // New field
  double tdee;

  UserProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.goal,
    required this.daysPerWeek,
    required this.timeAvailable,
    required this.location,
    required this.hasAsymmetry,
    required this.experience,
    this.height = 170.0,
    this.gender = 'Masculino',
    this.somatotype = Somatotype.undefined,
    this.wristCircumference = 0.0,
    this.ankleCircumference = 0.0,
    this.focusArea = 'Cuerpo Completo',
    this.tdee = 2000.0, // Default value
  });

  // Helper getters to maintain compatibility with existing code if ANY
  Experience get experienceLevel => experience;

  String get goalName {
    switch (goal) {
      case TrainingGoal.hypertrophy:
        return 'Hipertrofia';
      case TrainingGoal.strength:
        return 'Fuerza';
      case TrainingGoal.health:
        return 'Salud';
      case TrainingGoal.endurance:
        return 'Resistencia';
      case TrainingGoal.weightLoss:
        return 'Pérdida de Grasa';
      case TrainingGoal.generalHealth:
        return 'Salud General';
      default:
        return 'General';
    }
  }
}
