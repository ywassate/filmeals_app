import 'package:hive_flutter/hive_flutter.dart';
import 'package:filmeals_app/data/models/central_data_model.dart';
import 'package:filmeals_app/data/models/meals_sensor_data_model.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/data/models/social_sensor_data_model.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';

/// Service pour gérer l'initialisation de Hive et l'accès aux boxes
/// Architecture Multi-Capteurs avec données centralisées
class LocalStorageService {
  // Box names
  static const String centralDataBoxName = 'central_data';
  static const String mealsSensorBoxName = 'meals_sensor';
  static const String mealsBoxName = 'meals';
  static const String sleepSensorBoxName = 'sleep_sensor';
  static const String sleepRecordsBoxName = 'sleep_records';
  static const String socialSensorBoxName = 'social_sensor';
  static const String socialInteractionsBoxName = 'social_interactions';
  static const String locationSensorBoxName = 'location_sensor';
  static const String locationRecordsBoxName = 'location_records';
  static const String bluetoothContactsBoxName = 'bluetooth_contacts';

  // Boxes
  Box<CentralDataModel>? _centralDataBox;
  Box<MealsSensorDataModel>? _mealsSensorBox;
  Box<MealModel>? _mealsBox;
  Box<SleepSensorDataModel>? _sleepSensorBox;
  Box<SleepRecordModel>? _sleepRecordsBox;
  Box<SocialSensorDataModel>? _socialSensorBox;
  Box<SocialInteractionModel>? _socialInteractionsBox;
  Box<LocationSensorDataModel>? _locationSensorBox;
  Box<LocationRecordModel>? _locationRecordsBox;
  Box<BluetoothContactModel>? _bluetoothContactsBox;

  /// Initialiser Hive et enregistrer les adapters
  Future<void> init() async {
    await Hive.initFlutter();

    // === CENTRAL DATA ===
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(CentralDataModelAdapter());
    }

    // === MEALS SENSOR ===
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(MealsSensorDataModelAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(GoalTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(ActivityLevelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MealModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MealTypeAdapter());
    }

    // === SLEEP SENSOR ===
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(SleepSensorDataModelAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SleepRecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SleepQualityAdapter());
    }

    // === SOCIAL SENSOR ===
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SocialSensorDataModelAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SocialInteractionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(InteractionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(SocialSentimentAdapter());
    }

    // === LOCATION SENSOR ===
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(LocationSensorDataModelAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(LocationRecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(LocationPointAdapter());
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(ActivityTypeAdapter());
    }

    // === BLUETOOTH CONTACTS ===
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(BluetoothContactModelAdapter());
    }

    // Ouvrir les boxes
    _centralDataBox = await Hive.openBox<CentralDataModel>(centralDataBoxName);
    _mealsSensorBox =
        await Hive.openBox<MealsSensorDataModel>(mealsSensorBoxName);
    _mealsBox = await Hive.openBox<MealModel>(mealsBoxName);
    _sleepSensorBox =
        await Hive.openBox<SleepSensorDataModel>(sleepSensorBoxName);
    _sleepRecordsBox = await Hive.openBox<SleepRecordModel>(sleepRecordsBoxName);
    _socialSensorBox =
        await Hive.openBox<SocialSensorDataModel>(socialSensorBoxName);
    _socialInteractionsBox =
        await Hive.openBox<SocialInteractionModel>(socialInteractionsBoxName);
    _locationSensorBox =
        await Hive.openBox<LocationSensorDataModel>(locationSensorBoxName);
    _locationRecordsBox =
        await Hive.openBox<LocationRecordModel>(locationRecordsBoxName);
    _bluetoothContactsBox =
        await Hive.openBox<BluetoothContactModel>(bluetoothContactsBoxName);
  }

  // === GETTERS ===

  /// Récupérer la box des données centrales
  Box<CentralDataModel> get centralDataBox {
    if (_centralDataBox == null || !_centralDataBox!.isOpen) {
      throw Exception('CentralDataBox not initialized. Call init() first.');
    }
    return _centralDataBox!;
  }

  /// Récupérer la box des données du capteur repas
  Box<MealsSensorDataModel> get mealsSensorBox {
    if (_mealsSensorBox == null || !_mealsSensorBox!.isOpen) {
      throw Exception('MealsSensorBox not initialized. Call init() first.');
    }
    return _mealsSensorBox!;
  }

  /// Récupérer la box des repas
  Box<MealModel> get mealsBox {
    if (_mealsBox == null || !_mealsBox!.isOpen) {
      throw Exception('MealsBox not initialized. Call init() first.');
    }
    return _mealsBox!;
  }

  /// Récupérer la box des données du capteur sommeil
  Box<SleepSensorDataModel> get sleepSensorBox {
    if (_sleepSensorBox == null || !_sleepSensorBox!.isOpen) {
      throw Exception('SleepSensorBox not initialized. Call init() first.');
    }
    return _sleepSensorBox!;
  }

  /// Récupérer la box des enregistrements de sommeil
  Box<SleepRecordModel> get sleepRecordsBox {
    if (_sleepRecordsBox == null || !_sleepRecordsBox!.isOpen) {
      throw Exception('SleepRecordsBox not initialized. Call init() first.');
    }
    return _sleepRecordsBox!;
  }

  /// Récupérer la box des données du capteur social
  Box<SocialSensorDataModel> get socialSensorBox {
    if (_socialSensorBox == null || !_socialSensorBox!.isOpen) {
      throw Exception('SocialSensorBox not initialized. Call init() first.');
    }
    return _socialSensorBox!;
  }

  /// Récupérer la box des interactions sociales
  Box<SocialInteractionModel> get socialInteractionsBox {
    if (_socialInteractionsBox == null || !_socialInteractionsBox!.isOpen) {
      throw Exception(
          'SocialInteractionsBox not initialized. Call init() first.');
    }
    return _socialInteractionsBox!;
  }

  /// Récupérer la box des données du capteur localisation
  Box<LocationSensorDataModel> get locationSensorBox {
    if (_locationSensorBox == null || !_locationSensorBox!.isOpen) {
      throw Exception('LocationSensorBox not initialized. Call init() first.');
    }
    return _locationSensorBox!;
  }

  /// Récupérer la box des enregistrements de localisation
  Box<LocationRecordModel> get locationRecordsBox {
    if (_locationRecordsBox == null || !_locationRecordsBox!.isOpen) {
      throw Exception(
          'LocationRecordsBox not initialized. Call init() first.');
    }
    return _locationRecordsBox!;
  }

  /// Récupérer la box des contacts Bluetooth
  Box<BluetoothContactModel> get bluetoothContactsBox {
    if (_bluetoothContactsBox == null || !_bluetoothContactsBox!.isOpen) {
      throw Exception(
          'BluetoothContactsBox not initialized. Call init() first.');
    }
    return _bluetoothContactsBox!;
  }

  // === COMPATIBILITY GETTERS (DEPRECATED) ===
  // Pour compatibilité avec l'ancien code
  // TODO: Migrer tout le code vers centralDataBox et mealsBox

  @Deprecated('Use centralDataBox instead')
  Box get userBox => centralDataBox;

  @Deprecated('Use mealsBox instead')
  Box<MealModel> get mealBox => mealsBox;

  // === UTILITY METHODS ===

  /// Fermer toutes les boxes (à appeler quand l'app se ferme)
  Future<void> close() async {
    await _centralDataBox?.close();
    await _mealsSensorBox?.close();
    await _mealsBox?.close();
    await _sleepSensorBox?.close();
    await _sleepRecordsBox?.close();
    await _socialSensorBox?.close();
    await _socialInteractionsBox?.close();
    await _locationSensorBox?.close();
    await _locationRecordsBox?.close();
    await _bluetoothContactsBox?.close();
  }

  /// Effacer toutes les données (pour les tests ou reset)
  Future<void> clearAll() async {
    await _centralDataBox?.clear();
    await _mealsSensorBox?.clear();
    await _mealsBox?.clear();
    await _sleepSensorBox?.clear();
    await _sleepRecordsBox?.clear();
    await _socialSensorBox?.clear();
    await _socialInteractionsBox?.clear();
    await _locationSensorBox?.clear();
    await _locationRecordsBox?.clear();
    await _bluetoothContactsBox?.clear();
  }
}
