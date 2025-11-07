import 'package:hive_flutter/hive_flutter.dart';
import 'package:filmeals_app/data/models/user_model.dart';
import 'package:filmeals_app/data/models/meal_model.dart';

/// Service pour gérer l'initialisation de Hive et l'accès aux boxes
class LocalStorageService {
  static const String userBoxName = 'users';
  static const String mealBoxName = 'meals';

  Box<UserModel>? _userBox;
  Box<MealModel>? _mealBox;

  /// Initialiser Hive et enregistrer les adapters
  Future<void> init() async {
    await Hive.initFlutter();

    // Enregistrer les adapters si pas déjà fait
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GoalTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MealModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MealTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ActivityLevelAdapter());
    }

    // Ouvrir les boxes
    _userBox = await Hive.openBox<UserModel>(userBoxName);
    _mealBox = await Hive.openBox<MealModel>(mealBoxName);
  }

  /// Récupérer la box des utilisateurs
  Box<UserModel> get userBox {
    if (_userBox == null || !_userBox!.isOpen) {
      throw Exception('UserBox not initialized. Call init() first.');
    }
    return _userBox!;
  }

  /// Récupérer la box des repas
  Box<MealModel> get mealBox {
    if (_mealBox == null || !_mealBox!.isOpen) {
      throw Exception('MealBox not initialized. Call init() first.');
    }
    return _mealBox!;
  }

  /// Fermer toutes les boxes (à appeler quand l'app se ferme)
  Future<void> close() async {
    await _userBox?.close();
    await _mealBox?.close();
  }

  /// Effacer toutes les données (pour les tests ou reset)
  Future<void> clearAll() async {
    await _userBox?.clear();
    await _mealBox?.clear();
  }
}
