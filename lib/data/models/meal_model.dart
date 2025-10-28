import 'package:hive/hive.dart';

part 'meal_model.g.dart';

@HiveType(typeId: 2)
class MealModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int calories; // in kcal

  @HiveField(4)
  final DateTime date; // date of the meal

  @HiveField(5)
  final String userId; // ID of the user who logged the meal

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final MealType mealType;

  MealModel({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.date,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.mealType,
  });
}

@HiveType(typeId: 3)
enum MealType {
  @HiveField(0)
  breakfast,
  @HiveField(1)
  lunch,
  @HiveField(2)
  dinner,
  @HiveField(3)
  snack,
}
