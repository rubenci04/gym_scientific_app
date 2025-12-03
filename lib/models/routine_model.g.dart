// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineDayAdapter extends TypeAdapter<RoutineDay> {
  @override
  final int typeId = 8;

  @override
  RoutineDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineDay(
      id: fields[0] as String,
      name: fields[1] as String,
      targetMuscles: (fields[2] as List).cast<String>(),
      exerciseIds: (fields[3] as List).cast<String>(),
      sets: fields[4] as int,
      reps: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RoutineDay obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetMuscles)
      ..writeByte(3)
      ..write(obj.exerciseIds)
      ..writeByte(4)
      ..write(obj.sets)
      ..writeByte(5)
      ..write(obj.reps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeeklyRoutineAdapter extends TypeAdapter<WeeklyRoutine> {
  @override
  final int typeId = 9;

  @override
  WeeklyRoutine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyRoutine(
      id: fields[0] as String,
      name: fields[1] as String,
      days: (fields[2] as List).cast<RoutineDay>(),
      createdAt: fields[3] as DateTime,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyRoutine obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.days)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyRoutineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
