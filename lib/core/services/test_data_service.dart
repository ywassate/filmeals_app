import 'dart:math';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:filmeals_app/data/models/social_sensor_data_model.dart';
import 'package:filmeals_app/data/models/central_data_model.dart';

/// Service pour générer des données de test réalistes
class TestDataService {
  final LocalStorageService _storageService;
  final Random _random = Random();

  TestDataService(this._storageService);

  /// Génère toutes les données de test
  Future<void> generateAllTestData() async {
    // D'abord, nettoyer toutes les anciennes données de test
    await clearAllTestData();

    final userId = await _ensureUserExists();

    print('🎲 Generating test data for user: $userId');

    // Générer des données pour les 7 derniers jours
    await _generateSleepData(userId);
    await _generateMealData(userId);
    await _generateActivityData(userId);
    await _generateSocialData(userId);

    print('✅ Test data generation completed!');
    print('📊 Sleep records: ${_storageService.sleepRecordsBox.length}');
    print('📊 Meal records: ${_storageService.mealsBox.length}');
    print('📊 Activity records: ${_storageService.locationRecordsBox.length}');
    print('📊 Social records: ${_storageService.socialInteractionsBox.length}');
  }

  /// S'assure qu'un utilisateur existe
  Future<String> _ensureUserExists() async {
    var user = _storageService.centralDataBox.get('currentUser');

    if (user == null) {
      user = CentralDataModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test User',
        email: 'test@example.com',
        age: 28,
        gender: 'male',
        height: 175,
        weight: 70,
        profilePictureUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        activeSensors: ['sleep', 'meals', 'location', 'social'],
      );
      await _storageService.centralDataBox.put('currentUser', user);
      print('👤 Created new user: ${user.id}');
    } else {
      print('👤 Using existing user: ${user.id}');
    }

    return user.id;
  }

  /// Génère des données de sommeil pour les 7 derniers jours
  Future<void> _generateSleepData(String userId) async {
    final now = DateTime.now();
    final qualities = [SleepQuality.poor, SleepQuality.fair, SleepQuality.good, SleepQuality.excellent];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final bedTime = DateTime(date.year, date.month, date.day - 1, 22 + _random.nextInt(2), _random.nextInt(60));
      final wakeTime = DateTime(date.year, date.month, date.day, 6 + _random.nextInt(3), _random.nextInt(60));
      final durationMinutes = wakeTime.difference(bedTime).inMinutes;

      final sleepRecord = SleepRecordModel(
        id: 'sleep_${bedTime.millisecondsSinceEpoch}',
        userId: userId,
        bedTime: bedTime,
        wakeTime: wakeTime,
        durationMinutes: durationMinutes,
        quality: qualities[1 + _random.nextInt(3)], // fair to excellent
        interruptionsCount: _random.nextInt(3),
        notes: 'Auto-generated test data',
        createdAt: bedTime,
        updatedAt: bedTime,
      );

      await _storageService.sleepRecordsBox.put(sleepRecord.id, sleepRecord);
    }
  }

  /// Génère des données de repas pour les 7 derniers jours
  Future<void> _generateMealData(String userId) async {
    final now = DateTime.now();

    final mealTypes = [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack];
    final mealNames = {
      MealType.breakfast: ['Oatmeal with fruits', 'Toast and eggs', 'Yogurt and granola', 'Smoothie bowl'],
      MealType.lunch: ['Chicken salad', 'Pasta with vegetables', 'Rice and fish', 'Sandwich'],
      MealType.dinner: ['Grilled salmon', 'Steak and potatoes', 'Vegetable curry', 'Pizza'],
      MealType.snack: ['Apple', 'Protein bar', 'Nuts', 'Yogurt'],
    };

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));

      // 3-4 repas par jour
      final mealsCount = 3 + _random.nextInt(2);
      for (int j = 0; j < mealsCount; j++) {
        final mealType = mealTypes[j % mealTypes.length];
        final hour = _getMealHour(mealType);
        final mealTime = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        final calories = _getMealCalories(mealType);
        final protein = (calories * (0.20 + _random.nextDouble() * 0.10) / 4);
        final carbs = (calories * (0.45 + _random.nextDouble() * 0.10) / 4);
        final fats = (calories * (0.30 + _random.nextDouble() * 0.10) / 9);

        final meal = MealModel(
          id: 'meal_${mealTime.millisecondsSinceEpoch}_$j',
          userId: userId,
          name: mealNames[mealType]![_random.nextInt(mealNames[mealType]!.length)],
          description: 'Auto-generated test meal',
          mealType: mealType,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fats,
          date: mealTime,
          createdAt: mealTime,
          updatedAt: mealTime,
        );

        await _storageService.mealsBox.put(meal.id, meal);
      }
    }
  }

  int _getMealHour(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return 7 + _random.nextInt(2);
      case MealType.lunch:
        return 12 + _random.nextInt(2);
      case MealType.dinner:
        return 19 + _random.nextInt(2);
      case MealType.snack:
        return 15 + _random.nextInt(3);
    }
  }

  int _getMealCalories(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return 300 + _random.nextInt(200);
      case MealType.lunch:
        return 500 + _random.nextInt(300);
      case MealType.dinner:
        return 600 + _random.nextInt(300);
      case MealType.snack:
        return 100 + _random.nextInt(150);
    }
  }

  /// Génère des données d'activité GPS pour les 7 derniers jours
  Future<void> _generateActivityData(String userId) async {
    final now = DateTime.now();
    final activityTypes = [ActivityType.running, ActivityType.walking, ActivityType.cycling];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));

      // 1-2 activités par jour
      final activitiesCount = 1 + _random.nextInt(2);
      for (int j = 0; j < activitiesCount; j++) {
        final activityType = activityTypes[_random.nextInt(activityTypes.length)];
        final hour = 8 + _random.nextInt(12);
        final startTime = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        final durationMinutes = 20 + _random.nextInt(40);
        final endTime = startTime.add(Duration(minutes: durationMinutes));

        final distance = _getActivityDistance(activityType, durationMinutes);

        final activity = LocationRecordModel(
          id: 'activity_${startTime.millisecondsSinceEpoch}_$j',
          userId: userId,
          activityType: activityType,
          startTime: startTime,
          endTime: endTime,
          distanceKm: distance,
          stepsCount: (distance * 1300).round(), // Approx 1300 steps/km
          route: _generateRoute(40),
          notes: 'Auto-generated test activity',
          createdAt: startTime,
          updatedAt: startTime,
        );

        await _storageService.locationRecordsBox.put(activity.id, activity);
      }
    }
  }

  double _getActivityDistance(ActivityType type, int durationMinutes) {
    switch (type) {
      case ActivityType.running:
        return (durationMinutes / 60) * (8 + _random.nextDouble() * 4); // 8-12 km/h
      case ActivityType.walking:
        return (durationMinutes / 60) * (4 + _random.nextDouble() * 2); // 4-6 km/h
      case ActivityType.cycling:
        return (durationMinutes / 60) * (15 + _random.nextDouble() * 10); // 15-25 km/h
      default:
        return 0;
    }
  }

  int _getActivityCalories(ActivityType type, int durationMinutes) {
    switch (type) {
      case ActivityType.running:
        return (durationMinutes * 10).round();
      case ActivityType.walking:
        return (durationMinutes * 4).round();
      case ActivityType.cycling:
        return (durationMinutes * 8).round();
      default:
        return 0;
    }
  }

  List<LocationPoint> _generateRoute(int count) {
    final List<LocationPoint> points = [];
    double lat = 48.8566 + (_random.nextDouble() - 0.5) * 0.1; // Paris approx
    double lng = 2.3522 + (_random.nextDouble() - 0.5) * 0.1;

    for (int i = 0; i < count; i++) {
      points.add(LocationPoint(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now().subtract(Duration(seconds: count - i)),
      ));

      // Variation aléatoire pour simuler un parcours
      lat += (_random.nextDouble() - 0.5) * 0.001;
      lng += (_random.nextDouble() - 0.5) * 0.001;
    }

    return points;
  }

  /// Génère des données sociales pour les 7 derniers jours
  Future<void> _generateSocialData(String userId) async {
    final now = DateTime.now();
    final types = [InteractionType.inPerson, InteractionType.phoneCall, InteractionType.videoCall, InteractionType.messaging];
    final sentiments = [SocialSentiment.neutral, SocialSentiment.positive, SocialSentiment.veryPositive];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));

      // 2-5 interactions par jour
      final interactionsCount = 2 + _random.nextInt(4);
      for (int j = 0; j < interactionsCount; j++) {
        final hour = 8 + _random.nextInt(12);
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));
        final durationMinutes = 10 + _random.nextInt(50);
        final type = types[_random.nextInt(types.length)];

        final interaction = SocialInteractionModel(
          id: 'social_${timestamp.millisecondsSinceEpoch}_$j',
          userId: userId,
          type: type,
          durationMinutes: durationMinutes,
          peopleCount: 1 + _random.nextInt(3),
          sentiment: sentiments[_random.nextInt(sentiments.length)],
          description: 'Auto-generated test interaction',
          timestamp: timestamp,
          createdAt: timestamp,
          updatedAt: timestamp,
        );

        await _storageService.socialInteractionsBox.put(interaction.id, interaction);
      }
    }
  }

  /// Efface toutes les données de test
  Future<void> clearAllTestData() async {
    await _storageService.sleepRecordsBox.clear();
    await _storageService.mealsBox.clear();
    await _storageService.locationRecordsBox.clear();
    await _storageService.socialInteractionsBox.clear();
  }
}
