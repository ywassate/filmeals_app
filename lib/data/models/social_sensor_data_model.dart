import 'package:hive/hive.dart';

part 'social_sensor_data_model.g.dart';

/// Données spécifiques au capteur CONTACTS SOCIAUX
@HiveType(typeId: 12)
class SocialSensorDataModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId; // Référence au CentralDataModel

  @HiveField(2)
  final int targetInteractionsPerDay; // Objectif d'interactions par jour

  @HiveField(3)
  final Map<String, dynamic> socialPreferences; // Préférences sociales

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  SocialSensorDataModel({
    required this.id,
    required this.userId,
    this.targetInteractionsPerDay = 5,
    this.socialPreferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  SocialSensorDataModel copyWith({
    String? id,
    String? userId,
    int? targetInteractionsPerDay,
    Map<String, dynamic>? socialPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialSensorDataModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetInteractionsPerDay:
          targetInteractionsPerDay ?? this.targetInteractionsPerDay,
      socialPreferences: socialPreferences ?? this.socialPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetInteractionsPerDay': targetInteractionsPerDay,
      'socialPreferences': socialPreferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SocialSensorDataModel.fromJson(Map<String, dynamic> json) {
    return SocialSensorDataModel(
      id: json['id'],
      userId: json['userId'],
      targetInteractionsPerDay: json['targetInteractionsPerDay'] ?? 5,
      socialPreferences:
          Map<String, dynamic>.from(json['socialPreferences'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Enregistrement d'une interaction sociale
@HiveType(typeId: 13)
class SocialInteractionModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final InteractionType type; // Type d'interaction

  @HiveField(3)
  final int durationMinutes; // Durée de l'interaction

  @HiveField(4)
  final int peopleCount; // Nombre de personnes

  @HiveField(5)
  final SocialSentiment sentiment; // Ressenti après l'interaction

  @HiveField(6)
  final String description; // Description optionnelle

  @HiveField(7)
  final DateTime timestamp; // Moment de l'interaction

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  SocialInteractionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.durationMinutes,
    this.peopleCount = 1,
    required this.sentiment,
    this.description = '',
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  SocialInteractionModel copyWith({
    String? id,
    String? userId,
    InteractionType? type,
    int? durationMinutes,
    int? peopleCount,
    SocialSentiment? sentiment,
    String? description,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialInteractionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      peopleCount: peopleCount ?? this.peopleCount,
      sentiment: sentiment ?? this.sentiment,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'durationMinutes': durationMinutes,
      'peopleCount': peopleCount,
      'sentiment': sentiment.toString().split('.').last,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SocialInteractionModel.fromJson(Map<String, dynamic> json) {
    return SocialInteractionModel(
      id: json['id'],
      userId: json['userId'],
      type: InteractionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      durationMinutes: json['durationMinutes'],
      peopleCount: json['peopleCount'] ?? 1,
      sentiment: SocialSentiment.values.firstWhere(
        (e) => e.toString().split('.').last == json['sentiment'],
      ),
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

@HiveType(typeId: 14)
enum InteractionType {
  @HiveField(0)
  inPerson, // En personne
  @HiveField(1)
  phoneCall, // Appel téléphonique
  @HiveField(2)
  videoCall, // Appel vidéo
  @HiveField(3)
  messaging, // Messagerie
  @HiveField(4)
  social_media, // Réseaux sociaux
  @HiveField(5)
  groupActivity, // Activité de groupe
}

@HiveType(typeId: 15)
enum SocialSentiment {
  @HiveField(0)
  negative, // Négatif
  @HiveField(1)
  neutral, // Neutre
  @HiveField(2)
  positive, // Positif
  @HiveField(3)
  veryPositive, // Très positif
}
