// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String,
      age: fields[1] as int,
      weight: fields[2] as double,
      goal: fields[3] as TrainingGoal,
      daysPerWeek: fields[4] as int,
      timeAvailable: fields[5] as int,
      location: fields[6] as TrainingLocation,
      hasAsymmetry: fields[7] as bool,
      experience: fields[8] as Experience,
      height: fields[9] as double,
      gender: fields[10] as String,
      somatotype: fields[11] as Somatotype,
      wristCircumference: fields[12] as double,
      ankleCircumference: fields[13] as double,
      focusArea: fields[14] as String,
      tdee: fields[15] as double,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.goal)
      ..writeByte(4)
      ..write(obj.daysPerWeek)
      ..writeByte(5)
      ..write(obj.timeAvailable)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.hasAsymmetry)
      ..writeByte(8)
      ..write(obj.experience)
      ..writeByte(9)
      ..write(obj.height)
      ..writeByte(10)
      ..write(obj.gender)
      ..writeByte(11)
      ..write(obj.somatotype)
      ..writeByte(12)
      ..write(obj.wristCircumference)
      ..writeByte(13)
      ..write(obj.ankleCircumference)
      ..writeByte(14)
      ..write(obj.focusArea)
      ..writeByte(15)
      ..write(obj.tdee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrainingGoalAdapter extends TypeAdapter<TrainingGoal> {
  @override
  final int typeId = 1;

  @override
  TrainingGoal read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TrainingGoal.hypertrophy;
      case 1:
        return TrainingGoal.strength;
      case 2:
        return TrainingGoal.health;
      case 3:
        return TrainingGoal.endurance;
      case 4:
        return TrainingGoal.weightLoss;
      case 5:
        return TrainingGoal.generalHealth;
      default:
        return TrainingGoal.hypertrophy;
    }
  }

  @override
  void write(BinaryWriter writer, TrainingGoal obj) {
    switch (obj) {
      case TrainingGoal.hypertrophy:
        writer.writeByte(0);
        break;
      case TrainingGoal.strength:
        writer.writeByte(1);
        break;
      case TrainingGoal.health:
        writer.writeByte(2);
        break;
      case TrainingGoal.endurance:
        writer.writeByte(3);
        break;
      case TrainingGoal.weightLoss:
        writer.writeByte(4);
        break;
      case TrainingGoal.generalHealth:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrainingLocationAdapter extends TypeAdapter<TrainingLocation> {
  @override
  final int typeId = 20;

  @override
  TrainingLocation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TrainingLocation.gym;
      case 1:
        return TrainingLocation.home;
      default:
        return TrainingLocation.gym;
    }
  }

  @override
  void write(BinaryWriter writer, TrainingLocation obj) {
    switch (obj) {
      case TrainingLocation.gym:
        writer.writeByte(0);
        break;
      case TrainingLocation.home:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExperienceAdapter extends TypeAdapter<Experience> {
  @override
  final int typeId = 21;

  @override
  Experience read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Experience.beginner;
      case 1:
        return Experience.intermediate;
      case 2:
        return Experience.advanced;
      default:
        return Experience.beginner;
    }
  }

  @override
  void write(BinaryWriter writer, Experience obj) {
    switch (obj) {
      case Experience.beginner:
        writer.writeByte(0);
        break;
      case Experience.intermediate:
        writer.writeByte(1);
        break;
      case Experience.advanced:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperienceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SomatotypeAdapter extends TypeAdapter<Somatotype> {
  @override
  final int typeId = 22;

  @override
  Somatotype read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Somatotype.ectomorph;
      case 1:
        return Somatotype.mesomorph;
      case 2:
        return Somatotype.endomorph;
      case 3:
        return Somatotype.undefined;
      default:
        return Somatotype.ectomorph;
    }
  }

  @override
  void write(BinaryWriter writer, Somatotype obj) {
    switch (obj) {
      case Somatotype.ectomorph:
        writer.writeByte(0);
        break;
      case Somatotype.mesomorph:
        writer.writeByte(1);
        break;
      case Somatotype.endomorph:
        writer.writeByte(2);
        break;
      case Somatotype.undefined:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SomatotypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
