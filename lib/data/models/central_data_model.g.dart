// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'central_data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CentralDataModelAdapter extends TypeAdapter<CentralDataModel> {
  @override
  final int typeId = 5;

  @override
  CentralDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CentralDataModel(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      age: fields[3] as int,
      gender: fields[4] as String,
      height: fields[5] as int,
      weight: fields[6] as int,
      profilePictureUrl: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      activeSensors: (fields[10] as List).cast<String>(),
      preferences: (fields[11] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CentralDataModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.height)
      ..writeByte(6)
      ..write(obj.weight)
      ..writeByte(7)
      ..write(obj.profilePictureUrl)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.activeSensors)
      ..writeByte(11)
      ..write(obj.preferences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CentralDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
