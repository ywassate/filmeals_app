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

//function to calculate BMI

double calculateBMI(int weight, int height) {
  if (height <= 0) {
    throw ArgumentError('Height must be greater than zero');
  }
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
  String goal,
) {
  // Using Mifflin-St Jeor Equation
  double bmr;

  if (gender.toLowerCase() == 'male') {
    bmr = 10 * weight + 6.25 * height - 5 * age + 5;
  } else {
    bmr = 10 * weight + 6.25 * height - 5 * age - 161;
  }
  // Assuming a sedentary activity level
  double dailyCalories = bmr * 1.2;
  if (goal.toLowerCase() == 'lose weight') {
    dailyCalories -= 300; // Caloric deficit
  } else if (goal.toLowerCase() == 'gain muscle') {
    dailyCalories += 400; // Caloric surplus
  } else if (goal.toLowerCase() == 'maintain weight') {
    // No change
  }
  return dailyCalories.round();
}
