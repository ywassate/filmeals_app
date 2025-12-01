import 'package:flutter/material.dart';
import 'package:filmeals_app/data/models/meal_model.dart';

/// Utilitaires de formatage pour les repas
class MealFormatter {
  /// Retourne le label pour un type de repas
  static String getMealTypeLabel(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
      default:
        return 'Meal';
    }
  }

  /// Retourne l'icône pour un type de repas
  static IconData getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.free_breakfast_rounded;
      case MealType.lunch:
        return Icons.lunch_dining_rounded;
      case MealType.dinner:
        return Icons.dinner_dining_rounded;
      case MealType.snack:
        return Icons.cookie_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  /// Retourne l'icône par nom de type (string)
  static IconData getMealIconByName(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'snack':
        return Icons.cookie_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  /// Formate les macros (protein/carbs/fat) en string
  static String formatMacros(double protein, double carbs, double fat) {
    return 'P: ${protein.toStringAsFixed(0)}g | C: ${carbs.toStringAsFixed(0)}g | F: ${fat.toStringAsFixed(0)}g';
  }

  /// Formate les calories
  static String formatCalories(int calories) {
    return '$calories kcal';
  }
}
