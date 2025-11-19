import 'package:hive/hive.dart';

part 'meals_sensor_data_model.g.dart';

/// Données spécifiques au capteur REPAS
/// Contient les informations et objectifs nutritionnels de l'utilisateur
@HiveType(typeId: 6)
class MealsSensorDataModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId; // Référence au CentralDataModel

  @HiveField(2)
  final GoalType goal;

  @HiveField(3)
  final int? targetWeight; // in kg

  @HiveField(4)
  final ActivityLevel activityLevel;

  @HiveField(5)
  final int dailyCalorieGoal; // calculated calorie goal

  @HiveField(6)
  final Map<String, dynamic> nutritionPreferences; // allergies, régimes, etc.

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  MealsSensorDataModel({
    required this.id,
    required this.userId,
    required this.goal,
    this.targetWeight,
    required this.activityLevel,
    required this.dailyCalorieGoal,
    this.nutritionPreferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  // Copy with
  MealsSensorDataModel copyWith({
    String? id,
    String? userId,
    GoalType? goal,
    int? targetWeight,
    ActivityLevel? activityLevel,
    int? dailyCalorieGoal,
    Map<String, dynamic>? nutritionPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealsSensorDataModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goal: goal ?? this.goal,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      nutritionPreferences: nutritionPreferences ?? this.nutritionPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'goal': goal.toString().split('.').last,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel.toString().split('.').last,
      'dailyCalorieGoal': dailyCalorieGoal,
      'nutritionPreferences': nutritionPreferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // From JSON
  factory MealsSensorDataModel.fromJson(Map<String, dynamic> json) {
    return MealsSensorDataModel(
      id: json['id'],
      userId: json['userId'],
      goal: GoalType.values.firstWhere(
        (e) => e.toString().split('.').last == json['goal'],
      ),
      targetWeight: json['targetWeight'],
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['activityLevel'],
      ),
      dailyCalorieGoal: json['dailyCalorieGoal'],
      nutritionPreferences:
          Map<String, dynamic>.from(json['nutritionPreferences'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

@HiveType(typeId: 7)
enum GoalType {
  @HiveField(0)
  maintainWeight,
  @HiveField(1)
  loseWeight,
  @HiveField(2)
  gainWeight,
}

@HiveType(typeId: 8)
enum ActivityLevel {
  @HiveField(0)
  sedentary, // Peu ou pas d'exercice
  @HiveField(1)
  lightlyActive, // Exercice léger 1-3 jours/semaine
  @HiveField(2)
  moderatelyActive, // Exercice modéré 3-5 jours/semaine
  @HiveField(3)
  veryActive, // Exercice intense 6-7 jours/semaine
  @HiveField(4)
  extraActive, // Exercice très intense ou travail physique
}

// Fonction pour calculer les calories journalières (Mifflin-St Jeor)
int calculateDailyCalories({
  required int age,
  required String gender,
  required int weight,
  required int height,
  required GoalType goal,
  required ActivityLevel activityLevel,
}) {
  // Calcul du BMR (Basal Metabolic Rate)
  double bmr;
  if (gender.toLowerCase() == 'male') {
    bmr = 10 * weight + 6.25 * height - 5 * age + 5;
  } else {
    bmr = 10 * weight + 6.25 * height - 5 * age - 161;
  }

  // Multiplier par niveau d'activité
  double activityMultiplier;
  switch (activityLevel) {
    case ActivityLevel.sedentary:
      activityMultiplier = 1.2;
      break;
    case ActivityLevel.lightlyActive:
      activityMultiplier = 1.375;
      break;
    case ActivityLevel.moderatelyActive:
      activityMultiplier = 1.55;
      break;
    case ActivityLevel.veryActive:
      activityMultiplier = 1.725;
      break;
    case ActivityLevel.extraActive:
      activityMultiplier = 1.9;
      break;
  }

  double dailyCalories = bmr * activityMultiplier;

  // Ajuster selon l'objectif
  switch (goal) {
    case GoalType.loseWeight:
      dailyCalories -= 500; // Déficit calorique
      break;
    case GoalType.gainWeight:
      dailyCalories += 500; // Surplus calorique
      break;
    case GoalType.maintainWeight:
      // Pas de changement
      break;
  }

  return dailyCalories.round();
}
