import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final int age;

  @HiveField(4)
  final String gender;

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
  final GoalType goal;

  @HiveField(11)
  final int? targetWeight; // in kg

  @HiveField(12)
  final ActivityLevel activityLevel;

  @HiveField(13)
  final int dailyCalorieGoal; // calculated calorie goal

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.profilePictureUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.goal,
    this.targetWeight,
    required this.activityLevel,
    required this.dailyCalorieGoal,
  });
}

@HiveType(typeId: 1)
enum GoalType {
  @HiveField(0)
  maintainWeight,
  @HiveField(1)
  loseWeight,
  @HiveField(2)
  gainWeight,
}

@HiveType(typeId: 4)
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

//function to calculate BMI

double calculateBMI(int weight, int height) {
  if (height <= 0) return 0;
  double heightInMeters = height / 100;
  return weight / (heightInMeters * heightInMeters);
}

//function to determine BMI category
String determineBMICategory(double bmi) {
  if (bmi < 18.5) {
    return 'Underweight';
  } else if (bmi >= 18.5 && bmi < 24.9) {
    return 'Normal weight';
  } else if (bmi >= 25 && bmi < 29.9) {
    return 'Overweight';
  } else {
    return 'Obesity';
  }
}

//function to suggest daily calorie intake based on goal
int suggestDailyCalorie(
  int age,
  String gender,
  int weight,
  int height,
  GoalType goal,
  ActivityLevel activityLevel,
) {
  // Using Mifflin-St Jeor Equation
  double bmr;

  if (gender.toLowerCase() == 'male') {
    bmr = 10 * weight + 6.25 * height - 5 * age + 5;
  } else {
    bmr = 10 * weight + 6.25 * height - 5 * age - 161;
  }

  // Apply activity level multiplier
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

  // Adjust based on goal
  switch (goal) {
    case GoalType.loseWeight:
      dailyCalories -= 500; // Caloric deficit for weight loss
      break;
    case GoalType.gainWeight:
      dailyCalories += 500; // Caloric surplus for weight gain
      break;
    case GoalType.maintainWeight:
      // No change
      break;
  }

  return dailyCalories.round();
}

// Copy with method
extension UserModelCopyWith on UserModel {
  UserModel copyWith({
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
    GoalType? goal,
    int? targetWeight,
    ActivityLevel? activityLevel,
    int? dailyCalorieGoal,
  }) {
    return UserModel(
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
      goal: goal ?? this.goal,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
    );
  }
}

//TO JSON
extension UserModelToJson on UserModel {
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
      'goal': goal.toString().split('.').last,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel.toString().split('.').last,
      'dailyCalorieGoal': dailyCalorieGoal,
    };
  }
}

//FROM JSON
extension UserModelFromJson on UserModel {
  // Méthode statique : peut être appelée directement sur la classe (UserModel.fromJson)
  // sans avoir besoin de créer une instance.
  // Exemple d'utilisation : UserModel user = UserModel.fromJson(jsonData);
  static UserModel fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      age: json['age'],
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
      profilePictureUrl: json['profilePictureUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      goal: GoalType.values.firstWhere(
        (e) => e.toString().split('.').last == json['goal'],
      ),
      targetWeight: json['targetWeight'],
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['activityLevel'],
      ),
      dailyCalorieGoal: json['dailyCalorieGoal'],
    );
  }
}
