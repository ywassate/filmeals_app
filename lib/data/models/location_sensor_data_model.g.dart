// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_sensor_data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationSensorDataModelAdapter
    extends TypeAdapter<LocationSensorDataModel> {
  @override
  final int typeId = 16;

  @override
  LocationSensorDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationSensorDataModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      targetStepsPerDay: fields[2] as int,
      targetDistanceKm: fields[3] as double,
      locationPreferences: (fields[4] as Map).cast<String, dynamic>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LocationSensorDataModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.targetStepsPerDay)
      ..writeByte(3)
      ..write(obj.targetDistanceKm)
      ..writeByte(4)
      ..write(obj.locationPreferences)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSensorDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationRecordModelAdapter extends TypeAdapter<LocationRecordModel> {
  @override
  final int typeId = 17;

  @override
  LocationRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationRecordModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime,
      distanceKm: fields[4] as double,
      stepsCount: fields[5] as int,
      activityType: fields[6] as ActivityType,
      route: (fields[7] as List).cast<LocationPoint>(),
      notes: fields[8] as String,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LocationRecordModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.distanceKm)
      ..writeByte(5)
      ..write(obj.stepsCount)
      ..writeByte(6)
      ..write(obj.activityType)
      ..writeByte(7)
      ..write(obj.route)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationPointAdapter extends TypeAdapter<LocationPoint> {
  @override
  final int typeId = 18;

  @override
  LocationPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationPoint(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LocationPoint obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityTypeAdapter extends TypeAdapter<ActivityType> {
  @override
  final int typeId = 19;

  @override
  ActivityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityType.walking;
      case 1:
        return ActivityType.running;
      case 2:
        return ActivityType.cycling;
      case 3:
        return ActivityType.driving;
      case 4:
        return ActivityType.stationary;
      case 5:
        return ActivityType.other;
      default:
        return ActivityType.walking;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityType obj) {
    switch (obj) {
      case ActivityType.walking:
        writer.writeByte(0);
        break;
      case ActivityType.running:
        writer.writeByte(1);
        break;
      case ActivityType.cycling:
        writer.writeByte(2);
        break;
      case ActivityType.driving:
        writer.writeByte(3);
        break;
      case ActivityType.stationary:
        writer.writeByte(4);
        break;
      case ActivityType.other:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
