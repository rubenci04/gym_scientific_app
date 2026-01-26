// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 2;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      id: fields[0] as String,
      name: fields[1] as String,
      muscleGroup: fields[2] as String,
      equipment: fields[3] as String,
      movementPattern: fields[4] as String,
      videoUrl: fields[5] == null ? '' : fields[5] as String,
      description: fields[6] == null ? '' : fields[6] as String,
      tips: fields[7] == null ? [] : (fields[7] as List).cast<String>(),
      commonMistakes:
          fields[8] == null ? [] : (fields[8] as List).cast<String>(),
      difficulty: fields[9] == null ? 'Intermedio' : fields[9] as String,
      targetMuscles:
          fields[10] == null ? [] : (fields[10] as List).cast<String>(),
      secondaryMuscles:
          fields[11] == null ? [] : (fields[11] as List).cast<String>(),
      variations: fields[12] == null ? [] : (fields[12] as List).cast<String>(),
      isBilateral: fields[13] == null ? true : fields[13] as bool,
      alternativeExercise: fields[14] == null ? '' : fields[14] as String,
      localImagePath: fields[15] as String?,
      mechanic: fields[16] == null ? 'compound' : fields[16] as String,
      timeCost: fields[17] == null ? 3.0 : fields[17] as double,
      symmetryScore: fields[18] == null ? 0 : fields[18] as int,
      primaryMechanism: fields[19] == null ? 'tension' : fields[19] as String,
      substitutionGroup: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.muscleGroup)
      ..writeByte(3)
      ..write(obj.equipment)
      ..writeByte(4)
      ..write(obj.movementPattern)
      ..writeByte(5)
      ..write(obj.videoUrl)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.tips)
      ..writeByte(8)
      ..write(obj.commonMistakes)
      ..writeByte(9)
      ..write(obj.difficulty)
      ..writeByte(10)
      ..write(obj.targetMuscles)
      ..writeByte(11)
      ..write(obj.secondaryMuscles)
      ..writeByte(12)
      ..write(obj.variations)
      ..writeByte(13)
      ..write(obj.isBilateral)
      ..writeByte(14)
      ..write(obj.alternativeExercise)
      ..writeByte(15)
      ..write(obj.localImagePath)
      ..writeByte(16)
      ..write(obj.mechanic)
      ..writeByte(17)
      ..write(obj.timeCost)
      ..writeByte(18)
      ..write(obj.symmetryScore)
      ..writeByte(19)
      ..write(obj.primaryMechanism)
      ..writeByte(20)
      ..write(obj.substitutionGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
