import 'package:hive/hive.dart';

part 'user_model.g.dart';

// --- ENUMS (Definiciones Únicas) ---

@HiveType(typeId: 1)
enum TrainingGoal {
  @HiveField(0) hypertrophy,
  @HiveField(1) strength,
  @HiveField(2) health,
  @HiveField(3) endurance,
  @HiveField(4) weightLoss,   
  @HiveField(5) generalHealth 
}

@HiveType(typeId: 2)
enum TrainingLocation { 
  @HiveField(0) gym, 
  @HiveField(1) home 
}

@HiveType(typeId: 3)
enum Experience { 
  @HiveField(0) beginner,
  @HiveField(1) intermediate,
  @HiveField(2) advanced
}

@HiveType(typeId: 4)
enum Somatotype { 
  @HiveField(0) ectomorph,
  @HiveField(1) mesomorph,
  @HiveField(2) endomorph,
  @HiveField(3) undefined
}

// --- CLASE DE USUARIO PRINCIPAL ---

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0) final String name;
  @HiveField(1) final int age;
  @HiveField(2) final double weight;
  @HiveField(3) TrainingGoal goal;
  @HiveField(4) final int daysPerWeek;
  @HiveField(5) final int timeAvailable;
  @HiveField(6) final TrainingLocation location;
  @HiveField(7) final bool hasAsymmetry;
  @HiveField(8) final Experience experience; 
  @HiveField(9) final double height;
  @HiveField(10) final String gender;
  @HiveField(11) final Somatotype somatotype;
  @HiveField(12) final double wristCircumference;
  @HiveField(13) final double ankleCircumference;
  @HiveField(14) final String focusArea; 

  UserProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.goal,
    required this.daysPerWeek,
    required this.timeAvailable,
    required this.location,
    // Valores por defecto para evitar que la app explote si faltan datos
    this.experience = Experience.intermediate,
    this.hasAsymmetry = false,
    this.height = 170.0,
    this.gender = 'Masculino',
    this.somatotype = Somatotype.undefined,
    this.wristCircumference = 0.0,
    this.ankleCircumference = 0.0,
    this.focusArea = 'Cuerpo Completo', 
  });

  // Getter para que el código viejo que busca 'experienceLevel' siga funcionando
  Experience get experienceLevel => experience;
  
  String get goalName {
    switch (goal) {
      case TrainingGoal.hypertrophy: return 'Hipertrofia';
      case TrainingGoal.strength: return 'Fuerza';
      case TrainingGoal.health: return 'Salud';
      case TrainingGoal.endurance: return 'Resistencia';
      case TrainingGoal.weightLoss: return 'Pérdida de Grasa';
      case TrainingGoal.generalHealth: return 'Salud General';
      default: return 'General';
    }
  }
}