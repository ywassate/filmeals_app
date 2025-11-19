import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';

/// Repository pour gérer les opérations sur les repas
class MealRepository {
  final LocalStorageService _storageService;

  MealRepository(this._storageService);

  /// Ajouter un nouveau repas
  Future<void> addMeal(MealModel meal) async {
    try {
      await _storageService.mealsBox.put(meal.id, meal);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du repas: $e');
    }
  }

  /// Récupérer un repas par son ID
  Future<MealModel?> getMealById(String id) async {
    try {
      return _storageService.mealsBox.get(id);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du repas: $e');
    }
  }

  /// Récupérer tous les repas d'un utilisateur
  Future<List<MealModel>> getUserMeals(String userId) async {
    try {
      final allMeals = _storageService.mealsBox.values.toList();
      return allMeals.where((meal) => meal.userId == userId).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Tri par date décroissante
    } catch (e) {
      throw Exception('Erreur lors de la récupération des repas: $e');
    }
  }

  /// Récupérer les repas d'un utilisateur pour une date spécifique
  Future<List<MealModel>> getMealsByDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final allMeals = await getUserMeals(userId);
      return allMeals.where((meal) {
        return meal.date.isAfter(startOfDay) && meal.date.isBefore(endOfDay);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des repas du jour: $e');
    }
  }

  /// Récupérer les repas d'aujourd'hui
  Future<List<MealModel>> getTodayMeals(String userId) async {
    return getMealsByDate(userId, DateTime.now());
  }

  /// Calculer le total de calories pour une date
  Future<int> getCaloriesForDate(String userId, DateTime date) async {
    try {
      final meals = await getMealsByDate(userId, date);
      return meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    } catch (e) {
      throw Exception('Erreur lors du calcul des calories: $e');
    }
  }

  /// Calculer le total de calories d'aujourd'hui
  Future<int> getTodayCalories(String userId) async {
    return getCaloriesForDate(userId, DateTime.now());
  }

  /// Récupérer les repas par type (petit-déjeuner, déjeuner, etc.)
  Future<List<MealModel>> getMealsByType(
    String userId,
    MealType type,
    DateTime date,
  ) async {
    try {
      final meals = await getMealsByDate(userId, date);
      return meals.where((meal) => meal.mealType == type).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des repas par type: $e');
    }
  }

  /// Mettre à jour un repas
  Future<void> updateMeal(MealModel meal) async {
    try {
      final updatedMeal = meal.copyWith(updatedAt: DateTime.now());
      await _storageService.mealsBox.put(meal.id, updatedMeal);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du repas: $e');
    }
  }

  /// Supprimer un repas
  Future<void> deleteMeal(String mealId) async {
    try {
      await _storageService.mealsBox.delete(mealId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du repas: $e');
    }
  }

  /// Supprimer tous les repas d'un utilisateur
  Future<void> deleteAllUserMeals(String userId) async {
    try {
      final userMeals = await getUserMeals(userId);
      for (var meal in userMeals) {
        await _storageService.mealsBox.delete(meal.id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression des repas: $e');
    }
  }

  /// Obtenir les statistiques pour une période
  Future<Map<String, dynamic>> getStatistics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allMeals = await getUserMeals(userId);
      final periodMeals = allMeals.where((meal) {
        return meal.date.isAfter(startDate) && meal.date.isBefore(endDate);
      }).toList();

      final totalCalories =
          periodMeals.fold(0, (sum, meal) => sum + meal.calories);
      final averageCalories =
          periodMeals.isEmpty ? 0 : totalCalories ~/ periodMeals.length;

      // Compter par type de repas
      final breakfastCount =
          periodMeals.where((m) => m.mealType == MealType.breakfast).length;
      final lunchCount =
          periodMeals.where((m) => m.mealType == MealType.lunch).length;
      final dinnerCount =
          periodMeals.where((m) => m.mealType == MealType.dinner).length;
      final snackCount =
          periodMeals.where((m) => m.mealType == MealType.snack).length;

      return {
        'totalMeals': periodMeals.length,
        'totalCalories': totalCalories,
        'averageCalories': averageCalories,
        'breakfastCount': breakfastCount,
        'lunchCount': lunchCount,
        'dinnerCount': dinnerCount,
        'snackCount': snackCount,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// Vérifier si l'objectif calorique est atteint
  Future<bool> isCalorieGoalReached(String userId, int goalCalories) async {
    try {
      final todayCalories = await getTodayCalories(userId);
      return todayCalories >= goalCalories;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir le nombre de repas restants pour atteindre l'objectif
  Future<int> getCaloriesRemaining(String userId, int goalCalories) async {
    try {
      final todayCalories = await getTodayCalories(userId);
      final remaining = goalCalories - todayCalories;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }
}
