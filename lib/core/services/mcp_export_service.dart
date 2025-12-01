import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:filmeals_app/data/models/user_model.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:filmeals_app/data/models/meals_sensor_data_model.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/data/models/social_sensor_data_model.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/location_repository.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/core/services/mcp_export_location_extension.dart';

/// Service d'export des données vers le serveur MCP
/// Formate toutes les données collectées pour l'analyse MCP
class MCPExportService {
  final UserRepository userRepository;
  final MealRepository mealRepository;
  final LocationRepository locationRepository;
  final LocalStorageService storageService;

  MCPExportService({
    required this.userRepository,
    required this.mealRepository,
    required this.locationRepository,
    required this.storageService,
  });

  /// Exporte toutes les données utilisateur pour le MCP
  Future<Map<String, dynamic>> exportUserData() async {
    final user = await userRepository.getCurrentUser();
    if (user == null) {
      throw Exception('Aucun utilisateur trouvé');
    }

    final allMeals = await mealRepository.getUserMeals(user.id);
    final allActivities = await locationRepository.getUserLocationRecords(user.id);
    final activityStats = await locationRepository.getUserActivityStats(user.id);

    // Get sensor data
    final mealsSensorData = storageService.mealsSensorBox.get(user.id);
    final sleepSensorData = storageService.sleepSensorBox.get(user.id);
    final socialSensorData = storageService.socialSensorBox.get(user.id);
    final locationSensorData = storageService.locationSensorBox.values.where((l) => l.userId == user.id).toList();

    return {
      'schema_version': '3.0',
      'export_metadata': {
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'platform': Platform.operatingSystem,
        'data_types': [
          'user_profile',
          'meals',
          'daily_aggregates',
          'behavioral_insights',
          'physical_activities',
          'activity_profile',
          'sensor_data',
        ],
      },
      'user_profile': _formatUserProfile(user),
      'meals': _formatMeals(allMeals),
      'daily_aggregates': _calculateDailyAggregates(user, allMeals),
      'behavioral_insights': _analyzeBehavioralInsights(user, allMeals),
      'progress_tracking': _trackProgress(user, allMeals),
      'physical_activities': _formatPhysicalActivities(allActivities),
      'activity_profile': _analyzeActivityProfile(allActivities, activityStats, user),
      'sensor_data': {
        'meals_sensor': _formatMealsSensorData(mealsSensorData),
        'sleep_sensor': _formatSleepSensorData(sleepSensorData),
        'social_sensor': _formatSocialSensorData(socialSensorData),
        'location_sensor': _formatLocationSensorData(locationSensorData),
      },
    };
  }

  /// Formate le profil utilisateur pour le MCP
  Map<String, dynamic> _formatUserProfile(UserModel user) {
    // Calculer le BMI localement
    final bmi = calculateBMI(user.weight, user.height);
    final bmiCategory = determineBMICategory(bmi);

    return {
      'anonymous_id': _generateAnonymousId(user.id),
      'demographics': {
        'age': user.age,
        'gender': user.gender,
        'height_cm': user.height,
        'weight_kg': user.weight,
      },
      'goals': {
        'type': user.goal.toString().split('.').last,
        'target_weight_kg': user.targetWeight,
        'activity_level': user.activityLevel.toString().split('.').last,
      },
      'calculated_metrics': {
        'bmi': bmi,
        'bmi_category': bmiCategory,
        'daily_calorie_goal': user.dailyCalorieGoal,
      },
      'account_created_at': user.createdAt.toIso8601String(),
      'last_updated_at': user.updatedAt.toIso8601String(),
    };
  }

  /// Formate les repas pour le MCP
  List<Map<String, dynamic>> _formatMeals(List<MealModel> meals) {
    return meals.map((meal) {
      return {
        'meal_id': _generateAnonymousId(meal.id),
        'timestamp': meal.date.toIso8601String(),
        'type': meal.mealType.toString().split('.').last,
        'name': meal.name,
        'description': meal.description,
        'nutrition': {
          'calories': meal.calories,
          'protein_g': meal.protein,
          'carbs_g': meal.carbs,
          'fat_g': meal.fat,
        },
        'metadata': {
          'created_at': meal.createdAt.toIso8601String(),
          'updated_at': meal.updatedAt.toIso8601String(),
        },
      };
    }).toList();
  }

  /// Calcule les agrégats quotidiens
  List<Map<String, dynamic>> _calculateDailyAggregates(
    UserModel user,
    List<MealModel> meals,
  ) {
    final Map<String, List<MealModel>> mealsByDate = {};

    // Grouper les repas par date
    for (var meal in meals) {
      final dateKey = _formatDate(meal.date);
      mealsByDate.putIfAbsent(dateKey, () => []);
      mealsByDate[dateKey]!.add(meal);
    }

    // Calculer les totaux pour chaque jour
    return mealsByDate.entries.map((entry) {
      final dayMeals = entry.value;
      final totalCalories = dayMeals.fold(0, (sum, m) => sum + m.calories);
      final totalProtein = dayMeals.fold(0.0, (sum, m) => sum + m.protein);
      final totalCarbs = dayMeals.fold(0.0, (sum, m) => sum + m.carbs);
      final totalFat = dayMeals.fold(0.0, (sum, m) => sum + m.fat);

      final calorieGoalAchievement = user.dailyCalorieGoal > 0
          ? (totalCalories / user.dailyCalorieGoal * 100).round()
          : 0;

      return {
        'date': entry.key,
        'totals': {
          'calories': totalCalories,
          'protein_g': totalProtein,
          'carbs_g': totalCarbs,
          'fat_g': totalFat,
        },
        'goals_achievement': {'calories_percent': calorieGoalAchievement},
        'meals_count': dayMeals.length,
        'meal_types': dayMeals
            .map((m) => m.mealType.toString().split('.').last)
            .toSet()
            .toList(),
      };
    }).toList();
  }

  /// Analyse les insights comportementaux
  Map<String, dynamic> _analyzeBehavioralInsights(
    UserModel user,
    List<MealModel> meals,
  ) {
    if (meals.isEmpty) {
      return {
        'meal_timing_patterns': [],
        'food_preferences': [],
        'goal_adherence_score': 0.0,
        'consistency_score': 0.0,
      };
    }

    // Analyser les heures de repas
    final mealTimings = <String, List<int>>{};
    for (var meal in meals) {
      final type = meal.mealType.toString().split('.').last;
      mealTimings.putIfAbsent(type, () => []);
      mealTimings[type]!.add(meal.date.hour);
    }

    final mealTimingPatterns = mealTimings.entries.map((entry) {
      final avgHour = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return {
        'meal_type': entry.key,
        'average_hour': avgHour.round(),
        'frequency': entry.value.length,
      };
    }).toList();

    // Calculer l'adhérence aux objectifs
    final daysWithMeals = _getDaysWithMeals(meals).length;
    final daysCompliant = _getDaysCompliantWithGoals(user, meals);
    final goalAdherenceScore = daysWithMeals > 0
        ? (daysCompliant / daysWithMeals)
        : 0.0;

    // Calculer la consistance (régularité)
    final consistencyScore = _calculateConsistencyScore(meals);

    return {
      'meal_timing_patterns': mealTimingPatterns,
      'food_preferences': _analyzeFoodPreferences(meals),
      'goal_adherence_score': goalAdherenceScore,
      'consistency_score': consistencyScore,
      'total_days_tracked': daysWithMeals,
      'days_compliant': daysCompliant,
    };
  }

  /// Suit la progression de l'utilisateur
  Map<String, dynamic> _trackProgress(UserModel user, List<MealModel> meals) {
    if (meals.isEmpty) {
      return {
        'tracking_started': user.createdAt.toIso8601String(),
        'days_tracked': 0,
        'status': 'just_started',
      };
    }

    final firstMealDate = meals
        .map((m) => m.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final daysSinceStart = DateTime.now().difference(firstMealDate).inDays;

    return {
      'tracking_started': firstMealDate.toIso8601String(),
      'days_tracked': daysSinceStart,
      'total_meals_logged': meals.length,
      'average_meals_per_day': meals.length / (daysSinceStart + 1),
      'status': _determineProgressStatus(user, meals),
    };
  }

  /// Utilitaires
  String _generateAnonymousId(String originalId) {
    // Hash simple pour anonymiser (tu peux utiliser crypto pour plus de sécurité)
    return originalId.hashCode.toRadixString(16).padLeft(16, '0');
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Set<String> _getDaysWithMeals(List<MealModel> meals) {
    return meals.map((m) => _formatDate(m.date)).toSet();
  }

  int _getDaysCompliantWithGoals(UserModel user, List<MealModel> meals) {
    final Map<String, List<MealModel>> mealsByDate = {};
    for (var meal in meals) {
      final dateKey = _formatDate(meal.date);
      mealsByDate.putIfAbsent(dateKey, () => []);
      mealsByDate[dateKey]!.add(meal);
    }

    int compliantDays = 0;
    for (var dayMeals in mealsByDate.values) {
      final totalCalories = dayMeals.fold(0, (sum, m) => sum + m.calories);
      // Considérer comme compliant si dans ±10% de l'objectif
      final lowerBound = user.dailyCalorieGoal * 0.9;
      final upperBound = user.dailyCalorieGoal * 1.1;
      if (totalCalories >= lowerBound && totalCalories <= upperBound) {
        compliantDays++;
      }
    }

    return compliantDays;
  }

  double _calculateConsistencyScore(List<MealModel> meals) {
    if (meals.length < 7) return 0.0;

    final daysWithMeals = _getDaysWithMeals(meals).length;
    final totalDays = DateTime.now().difference(meals.first.date).inDays + 1;

    return daysWithMeals / totalDays;
  }

  List<Map<String, dynamic>> _analyzeFoodPreferences(List<MealModel> meals) {
    // Analyser les patterns de noms de repas (simple version)
    final mealTypes = <String, int>{};
    for (var meal in meals) {
      final type = meal.mealType.toString().split('.').last;
      mealTypes[type] = (mealTypes[type] ?? 0) + 1;
    }

    return mealTypes.entries.map((e) {
      return {
        'meal_type': e.key,
        'frequency': e.value,
        'percentage': (e.value / meals.length * 100).round(),
      };
    }).toList();
  }

  String _determineProgressStatus(UserModel user, List<MealModel> meals) {
    final daysSinceStart = DateTime.now().difference(meals.first.date).inDays;
    final daysCompliant = _getDaysCompliantWithGoals(user, meals);
    final adherenceRate = daysCompliant / (daysSinceStart + 1);

    if (adherenceRate >= 0.8) return 'excellent';
    if (adherenceRate >= 0.6) return 'on_track';
    if (adherenceRate >= 0.4) return 'needs_improvement';
    return 'struggling';
  }

  /// Sauvegarde l'export dans un fichier JSON
  Future<File> saveExportToFile() async {
    final exportData = await exportUserData();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/mcp_export_$timestamp.json');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportData),
    );

    return file;
  }

  /// Obtient un résumé rapide pour la visualisation
  Future<Map<String, dynamic>> getExportSummary() async {
    final user = await userRepository.getCurrentUser();
    if (user == null) {
      throw Exception('Aucun utilisateur trouvé');
    }

    final allMeals = await mealRepository.getUserMeals(user.id);
    final daysTracked = _getDaysWithMeals(allMeals).length;
    final daysCompliant = _getDaysCompliantWithGoals(user, allMeals);

    return {
      'total_meals': allMeals.length,
      'days_tracked': daysTracked,
      'days_compliant': daysCompliant,
      'adherence_rate': daysTracked > 0 ? (daysCompliant / daysTracked) : 0.0,
      'ready_for_export': allMeals.isNotEmpty,
    };
  }

  /// Formate les activités physiques pour le MCP
  List<Map<String, dynamic>> _formatPhysicalActivities(List<LocationRecordModel> activities) {
    return MCPExportLocationExtension.formatPhysicalActivities(activities);
  }

  /// Analyse le profil d'activité physique
  Map<String, dynamic> _analyzeActivityProfile(
    List<LocationRecordModel> activities,
    Map<String, dynamic> stats,
    UserModel user,
  ) {
    return MCPExportLocationExtension.analyzeActivityProfile(activities, stats, user);
  }

  /// Formate les données du capteur Meals
  Map<String, dynamic>? _formatMealsSensorData(MealsSensorDataModel? data) {
    if (data == null) return null;

    return {
      'sensor_id': _generateAnonymousId(data.id),
      'user_id': _generateAnonymousId(data.userId),
      'goal_type': data.goal?.toString().split('.').last,
      'activity_level': data.activityLevel?.toString().split('.').last,
      'daily_calorie_goal': data.dailyCalorieGoal,
      'created_at': data.createdAt.toIso8601String(),
      'updated_at': data.updatedAt.toIso8601String(),
    };
  }

  /// Formate les données du capteur Sleep
  Map<String, dynamic>? _formatSleepSensorData(SleepSensorDataModel? data) {
    if (data == null) return null;

    return {
      'sensor_id': _generateAnonymousId(data.id),
      'user_id': _generateAnonymousId(data.userId),
      'target_sleep_hours': data.targetSleepHours,
      'sleep_preferences': data.sleepPreferences,
      'created_at': data.createdAt.toIso8601String(),
      'updated_at': data.updatedAt.toIso8601String(),
    };
  }

  /// Formate les données du capteur Social
  Map<String, dynamic>? _formatSocialSensorData(SocialSensorDataModel? data) {
    if (data == null) return null;

    return {
      'sensor_id': _generateAnonymousId(data.id),
      'user_id': _generateAnonymousId(data.userId),
      'target_interactions_per_day': data.targetInteractionsPerDay,
      'social_preferences': data.socialPreferences,
      'created_at': data.createdAt.toIso8601String(),
      'updated_at': data.updatedAt.toIso8601String(),
    };
  }

  /// Formate les données du capteur Location
  List<Map<String, dynamic>> _formatLocationSensorData(List<LocationSensorDataModel> data) {
    return data.map((sensor) => {
      'sensor_id': _generateAnonymousId(sensor.id),
      'user_id': _generateAnonymousId(sensor.userId),
      'target_steps_per_day': sensor.targetStepsPerDay,
      'target_distance_km': sensor.targetDistanceKm,
      'location_preferences': sensor.locationPreferences,
      'created_at': sensor.createdAt.toIso8601String(),
      'updated_at': sensor.updatedAt.toIso8601String(),
    }).toList();
  }
}
