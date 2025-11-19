// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_sensor_data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepSensorDataModelAdapter extends TypeAdapter<SleepSensorDataModel> {
  @override
  final int typeId = 9;

  @override
  SleepSensorDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepSensorDataModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      targetSleepHours: fields[2] as int,
      sleepPreferences: (fields[3] as Map).cast<String, dynamic>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SleepSensorDataModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.targetSleepHours)
      ..writeByte(3)
      ..write(obj.sleepPreferences)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSensorDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SleepRecordModelAdapter extends TypeAdapter<SleepRecordModel> {
  @override
  final int typeId = 10;

  @override
  SleepRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepRecordModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      bedTime: fields[2] as DateTime,
      wakeTime: fields[3] as DateTime,
      durationMinutes: fields[4] as int,
      quality: fields[5] as SleepQuality,
      interruptionsCount: fields[6] as int,
      notes: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SleepRecordModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.bedTime)
      ..writeByte(3)
      ..write(obj.wakeTime)
      ..writeByte(4)
      ..write(obj.durationMinutes)
      ..writeByte(5)
      ..write(obj.quality)
      ..writeByte(6)
      ..write(obj.interruptionsCount)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SleepQualityAdapter extends TypeAdapter<SleepQuality> {
  @override
  final int typeId = 11;

  @override
  SleepQuality read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SleepQuality.poor;
      case 1:
        return SleepQuality.fair;
      case 2:
        return SleepQuality.good;
      case 3:
        return SleepQuality.excellent;
      default:
        return SleepQuality.poor;
    }
  }

  @override
  void write(BinaryWriter writer, SleepQuality obj) {
    switch (obj) {
      case SleepQuality.poor:
        writer.writeByte(0);
        break;
      case SleepQuality.fair:
        writer.writeByte(1);
        break;
      case SleepQuality.good:
        writer.writeByte(2);
        break;
      case SleepQuality.excellent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepQualityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
