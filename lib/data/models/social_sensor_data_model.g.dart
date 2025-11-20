// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_sensor_data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SocialSensorDataModelAdapter extends TypeAdapter<SocialSensorDataModel> {
  @override
  final int typeId = 12;

  @override
  SocialSensorDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SocialSensorDataModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      targetInteractionsPerDay: fields[2] as int,
      socialPreferences: (fields[3] as Map).cast<String, dynamic>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SocialSensorDataModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.targetInteractionsPerDay)
      ..writeByte(3)
      ..write(obj.socialPreferences)
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
      other is SocialSensorDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SocialInteractionModelAdapter
    extends TypeAdapter<SocialInteractionModel> {
  @override
  final int typeId = 13;

  @override
  SocialInteractionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SocialInteractionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as InteractionType,
      durationMinutes: fields[3] as int,
      peopleCount: fields[4] as int,
      sentiment: fields[5] as SocialSentiment,
      description: fields[6] as String,
      timestamp: fields[7] as DateTime,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SocialInteractionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.peopleCount)
      ..writeByte(5)
      ..write(obj.sentiment)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.timestamp)
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
      other is SocialInteractionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BluetoothContactModelAdapter extends TypeAdapter<BluetoothContactModel> {
  @override
  final int typeId = 20;

  @override
  BluetoothContactModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BluetoothContactModel(
      macAddress: fields[0] as String,
      contactName: fields[1] as String,
      deviceName: fields[2] as String,
      firstEncounter: fields[3] as DateTime,
      lastEncounter: fields[4] as DateTime,
      encounterCount: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BluetoothContactModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.macAddress)
      ..writeByte(1)
      ..write(obj.contactName)
      ..writeByte(2)
      ..write(obj.deviceName)
      ..writeByte(3)
      ..write(obj.firstEncounter)
      ..writeByte(4)
      ..write(obj.lastEncounter)
      ..writeByte(5)
      ..write(obj.encounterCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothContactModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InteractionTypeAdapter extends TypeAdapter<InteractionType> {
  @override
  final int typeId = 14;

  @override
  InteractionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InteractionType.inPerson;
      case 1:
        return InteractionType.phoneCall;
      case 2:
        return InteractionType.videoCall;
      case 3:
        return InteractionType.messaging;
      case 4:
        return InteractionType.social_media;
      case 5:
        return InteractionType.groupActivity;
      default:
        return InteractionType.inPerson;
    }
  }

  @override
  void write(BinaryWriter writer, InteractionType obj) {
    switch (obj) {
      case InteractionType.inPerson:
        writer.writeByte(0);
        break;
      case InteractionType.phoneCall:
        writer.writeByte(1);
        break;
      case InteractionType.videoCall:
        writer.writeByte(2);
        break;
      case InteractionType.messaging:
        writer.writeByte(3);
        break;
      case InteractionType.social_media:
        writer.writeByte(4);
        break;
      case InteractionType.groupActivity:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SocialSentimentAdapter extends TypeAdapter<SocialSentiment> {
  @override
  final int typeId = 15;

  @override
  SocialSentiment read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SocialSentiment.negative;
      case 1:
        return SocialSentiment.neutral;
      case 2:
        return SocialSentiment.positive;
      case 3:
        return SocialSentiment.veryPositive;
      default:
        return SocialSentiment.negative;
    }
  }

  @override
  void write(BinaryWriter writer, SocialSentiment obj) {
    switch (obj) {
      case SocialSentiment.negative:
        writer.writeByte(0);
        break;
      case SocialSentiment.neutral:
        writer.writeByte(1);
        break;
      case SocialSentiment.positive:
        writer.writeByte(2);
        break;
      case SocialSentiment.veryPositive:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialSentimentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
