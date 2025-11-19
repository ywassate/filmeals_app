import 'package:hive/hive.dart';

part 'sleep_sensor_data_model.g.dart';

/// Données spécifiques au capteur SOMMEIL
@HiveType(typeId: 9)
class SleepSensorDataModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId; // Référence au CentralDataModel

  @HiveField(2)
  final int targetSleepHours; // Objectif en heures

  @HiveField(3)
  final Map<String, dynamic> sleepPreferences; // Préférences de sommeil

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  SleepSensorDataModel({
    required this.id,
    required this.userId,
    this.targetSleepHours = 8,
    this.sleepPreferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  SleepSensorDataModel copyWith({
    String? id,
    String? userId,
    int? targetSleepHours,
    Map<String, dynamic>? sleepPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepSensorDataModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetSleepHours: targetSleepHours ?? this.targetSleepHours,
      sleepPreferences: sleepPreferences ?? this.sleepPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetSleepHours': targetSleepHours,
      'sleepPreferences': sleepPreferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SleepSensorDataModel.fromJson(Map<String, dynamic> json) {
    return SleepSensorDataModel(
      id: json['id'],
      userId: json['userId'],
      targetSleepHours: json['targetSleepHours'] ?? 8,
      sleepPreferences:
          Map<String, dynamic>.from(json['sleepPreferences'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Enregistrement d'une session de sommeil
@HiveType(typeId: 10)
class SleepRecordModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime bedTime; // Heure de coucher

  @HiveField(3)
  final DateTime wakeTime; // Heure de réveil

  @HiveField(4)
  final int durationMinutes; // Durée totale en minutes

  @HiveField(5)
  final SleepQuality quality; // Qualité du sommeil

  @HiveField(6)
  final int interruptionsCount; // Nombre de réveils

  @HiveField(7)
  final String notes; // Notes optionnelles

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  SleepRecordModel({
    required this.id,
    required this.userId,
    required this.bedTime,
    required this.wakeTime,
    required this.durationMinutes,
    required this.quality,
    this.interruptionsCount = 0,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  double get durationHours => durationMinutes / 60;

  SleepRecordModel copyWith({
    String? id,
    String? userId,
    DateTime? bedTime,
    DateTime? wakeTime,
    int? durationMinutes,
    SleepQuality? quality,
    int? interruptionsCount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quality: quality ?? this.quality,
      interruptionsCount: interruptionsCount ?? this.interruptionsCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bedTime': bedTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'durationHours': durationHours,
      'quality': quality.toString().split('.').last,
      'interruptionsCount': interruptionsCount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SleepRecordModel.fromJson(Map<String, dynamic> json) {
    return SleepRecordModel(
      id: json['id'],
      userId: json['userId'],
      bedTime: DateTime.parse(json['bedTime']),
      wakeTime: DateTime.parse(json['wakeTime']),
      durationMinutes: json['durationMinutes'],
      quality: SleepQuality.values.firstWhere(
        (e) => e.toString().split('.').last == json['quality'],
      ),
      interruptionsCount: json['interruptionsCount'] ?? 0,
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

@HiveType(typeId: 11)
enum SleepQuality {
  @HiveField(0)
  poor, // Mauvais
  @HiveField(1)
  fair, // Passable
  @HiveField(2)
  good, // Bon
  @HiveField(3)
  excellent, // Excellent
}
