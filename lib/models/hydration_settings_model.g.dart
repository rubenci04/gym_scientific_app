// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hydration_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HydrationSettingsAdapter extends TypeAdapter<HydrationSettings> {
  @override
  final int typeId = 12;

  @override
  HydrationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HydrationSettings(
      enabled: fields[0] as bool,
      intervalMinutes: fields[1] as int,
      startHour: fields[2] as int,
      endHour: fields[3] as int,
      dailyGoalMl: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HydrationSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.intervalMinutes)
      ..writeByte(2)
      ..write(obj.startHour)
      ..writeByte(3)
      ..write(obj.endHour)
      ..writeByte(4)
      ..write(obj.dailyGoalMl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HydrationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
