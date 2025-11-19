import 'package:hive/hive.dart';

part 'central_data_model.g.dart';

/// Données centrales partagées entre tous les capteurs
/// Contient uniquement les informations communes à tous les utilisateurs
@HiveType(typeId: 5)
class CentralDataModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final int age;

  @HiveField(4)
  final String gender; // 'male' or 'female'

  @HiveField(5)
  final int height; // in cm

  @HiveField(6)
  final int weight; // in kg

  @HiveField(7)
  final String profilePictureUrl;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final List<String> activeSensors; // ['meals', 'sleep', 'social', 'location']

  @HiveField(11)
  final Map<String, dynamic> preferences; // Préférences globales

  CentralDataModel({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    this.profilePictureUrl = '',
    required this.createdAt,
    required this.updatedAt,
    this.activeSensors = const ['meals'],
    this.preferences = const {},
  });

  // Calcul BMI (utilisable par tous les capteurs)
  double get bmi {
    if (height <= 0) return 0;
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Catégorie BMI
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue >= 18.5 && bmiValue < 24.9) return 'Normal weight';
    if (bmiValue >= 25 && bmiValue < 29.9) return 'Overweight';
    return 'Obesity';
  }

  // Copy with
  CentralDataModel copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? gender,
    int? height,
    int? weight,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? activeSensors,
    Map<String, dynamic>? preferences,
  }) {
    return CentralDataModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activeSensors: activeSensors ?? this.activeSensors,
      preferences: preferences ?? this.preferences,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'activeSensors': activeSensors,
      'preferences': preferences,
      'bmi': bmi,
      'bmiCategory': bmiCategory,
    };
  }

  // From JSON
  factory CentralDataModel.fromJson(Map<String, dynamic> json) {
    return CentralDataModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      age: json['age'],
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
      profilePictureUrl: json['profilePictureUrl'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      activeSensors: List<String>.from(json['activeSensors'] ?? ['meals']),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }
}
