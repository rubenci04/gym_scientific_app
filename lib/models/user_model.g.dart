// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 1;

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
      height: fields[3] as double,
      gender: fields[4] as String,
      wristCircumference: fields[5] as double,
      ankleCircumference: fields[6] as double,
      somatotype: fields[7] as Somatotype,
      tdee: fields[8] as double,
      daysPerWeek: fields[9] as int,
      goal: fields[10] as TrainingGoal,
      location: fields[11] as TrainingLocation,
      focusArea: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.wristCircumference)
      ..writeByte(6)
      ..write(obj.ankleCircumference)
      ..writeByte(7)
      ..write(obj.somatotype)
      ..writeByte(8)
      ..write(obj.tdee)
      ..writeByte(9)
      ..write(obj.daysPerWeek)
      ..writeByte(10)
      ..write(obj.goal)
      ..writeByte(11)
      ..write(obj.location)
      ..writeByte(12)
      ..write(obj.focusArea);
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
  final int typeId = 6;

  @override
  TrainingGoal read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TrainingGoal.hypertrophy;
      case 1:
        return TrainingGoal.strength;
      case 2:
        return TrainingGoal.weightLoss;
      case 3:
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
      case TrainingGoal.weightLoss:
        writer.writeByte(2);
        break;
      case TrainingGoal.generalHealth:
        writer.writeByte(3);
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
  final int typeId = 7;

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

class SomatotypeAdapter extends TypeAdapter<Somatotype> {
  @override
  final int typeId = 0;

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
