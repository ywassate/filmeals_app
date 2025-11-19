import 'package:hive/hive.dart';

part 'location_sensor_data_model.g.dart';

/// Données spécifiques au capteur GPS/LOCALISATION
@HiveType(typeId: 16)
class LocationSensorDataModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId; // Référence au CentralDataModel

  @HiveField(2)
  final int targetStepsPerDay; // Objectif de pas par jour

  @HiveField(3)
  final double targetDistanceKm; // Objectif de distance en km

  @HiveField(4)
  final Map<String, dynamic> locationPreferences; // Préférences de localisation

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  LocationSensorDataModel({
    required this.id,
    required this.userId,
    this.targetStepsPerDay = 10000,
    this.targetDistanceKm = 5.0,
    this.locationPreferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  LocationSensorDataModel copyWith({
    String? id,
    String? userId,
    int? targetStepsPerDay,
    double? targetDistanceKm,
    Map<String, dynamic>? locationPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationSensorDataModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetStepsPerDay: targetStepsPerDay ?? this.targetStepsPerDay,
      targetDistanceKm: targetDistanceKm ?? this.targetDistanceKm,
      locationPreferences: locationPreferences ?? this.locationPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetStepsPerDay': targetStepsPerDay,
      'targetDistanceKm': targetDistanceKm,
      'locationPreferences': locationPreferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LocationSensorDataModel.fromJson(Map<String, dynamic> json) {
    return LocationSensorDataModel(
      id: json['id'],
      userId: json['userId'],
      targetStepsPerDay: json['targetStepsPerDay'] ?? 10000,
      targetDistanceKm: (json['targetDistanceKm'] ?? 5.0).toDouble(),
      locationPreferences:
          Map<String, dynamic>.from(json['locationPreferences'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Enregistrement d'une activité de localisation
@HiveType(typeId: 17)
class LocationRecordModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime startTime; // Début de l'activité

  @HiveField(3)
  final DateTime endTime; // Fin de l'activité

  @HiveField(4)
  final double distanceKm; // Distance parcourue

  @HiveField(5)
  final int stepsCount; // Nombre de pas

  @HiveField(6)
  final ActivityType activityType; // Type d'activité

  @HiveField(7)
  final List<LocationPoint> route; // Points GPS de la route

  @HiveField(8)
  final String notes; // Notes optionnelles

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  LocationRecordModel({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    this.stepsCount = 0,
    required this.activityType,
    this.route = const [],
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  LocationRecordModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceKm,
    int? stepsCount,
    ActivityType? activityType,
    List<LocationPoint>? route,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceKm: distanceKm ?? this.distanceKm,
      stepsCount: stepsCount ?? this.stepsCount,
      activityType: activityType ?? this.activityType,
      route: route ?? this.route,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'distanceKm': distanceKm,
      'stepsCount': stepsCount,
      'activityType': activityType.toString().split('.').last,
      'route': route.map((p) => p.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LocationRecordModel.fromJson(Map<String, dynamic> json) {
    return LocationRecordModel(
      id: json['id'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      stepsCount: json['stepsCount'] ?? 0,
      activityType: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == json['activityType'],
      ),
      route: (json['route'] as List?)
              ?.map((p) => LocationPoint.fromJson(p))
              .toList() ??
          [],
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

@HiveType(typeId: 18)
class LocationPoint {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final DateTime timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

@HiveType(typeId: 19)
enum ActivityType {
  @HiveField(0)
  walking, // Marche
  @HiveField(1)
  running, // Course
  @HiveField(2)
  cycling, // Vélo
  @HiveField(3)
  driving, // Conduite
  @HiveField(4)
  stationary, // Immobile
  @HiveField(5)
  other, // Autre
}
