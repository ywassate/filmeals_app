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

  @HiveField(9)
  final double protein; // in grams

  @HiveField(10)
  final double carbs; // in grams

  @HiveField(11)
  final double fat; // in grams

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
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
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

// Copy with method
extension MealModelCopyWith on MealModel {
  MealModel copyWith({
    String? id,
    String? name,
    String? description,
    int? calories,
    DateTime? date,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    MealType? mealType,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return MealModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mealType: mealType ?? this.mealType,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }
}

// TO JSON
extension MealModelToJson on MealModel {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'calories': calories,
      'date': date.toIso8601String(),
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'mealType': mealType.toString().split('.').last,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

// FROM JSON
extension MealModelFromJson on MealModel {
  static MealModel fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      calories: json['calories'],
      date: DateTime.parse(json['date']),
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      mealType: MealType.values.firstWhere(
        (e) => e.toString().split('.').last == json['mealType'],
      ),
      protein: json['protein']?.toDouble() ?? 0,
      carbs: json['carbs']?.toDouble() ?? 0,
      fat: json['fat']?.toDouble() ?? 0,
    );
  }
}
