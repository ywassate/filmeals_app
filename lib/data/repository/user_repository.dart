import 'package:filmeals_app/data/models/user_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';

/// Repository pour gérer les opérations sur les utilisateurs
class UserRepository {
  final LocalStorageService _storageService;

  // Cache de l'utilisateur actuel en mémoire
  UserModel? _currentUser;

  UserRepository(this._storageService);

  /// Clé pour l'utilisateur actuel dans Hive
  static const String _currentUserKey = 'currentUser';

  /// Sauvegarder un utilisateur (création ou mise à jour)
  Future<void> saveUser(UserModel user) async {
    try {
      await _storageService.userBox.put(_currentUserKey, user);
      _currentUser = user;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de l\'utilisateur: $e');
    }
  }

  /// Récupérer l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    try {
      // Si déjà en cache, le retourner
      if (_currentUser != null) return _currentUser;

      // Sinon, récupérer depuis Hive
      final data = _storageService.userBox.get(_currentUserKey);

      // Vérifier le type avant de caster
      if (data is UserModel) {
        _currentUser = data;
        return _currentUser;
      }

      // Si ce n'est pas un UserModel, retourner null
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  /// Vérifier si un utilisateur existe
  bool hasUser() {
    try {
      return _currentUser != null ||
             _storageService.userBox.get(_currentUserKey) != null;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer directement les données centrales (pour compatibilité)
  dynamic getCentralDataDirect() {
    try {
      final centralDataBox = _storageService.centralDataBox;
      if (centralDataBox.isEmpty) return null;
      return centralDataBox.values.first;
    } catch (e) {
      return null;
    }
  }

  /// Mettre à jour le poids de l'utilisateur
  Future<void> updateWeight(int newWeight) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Aucun utilisateur trouvé');
      }

      final updatedUser = user.copyWith(
        weight: newWeight,
        updatedAt: DateTime.now(),
      );

      await saveUser(updatedUser);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du poids: $e');
    }
  }

  /// Mettre à jour l'objectif calorique
  Future<void> updateCalorieGoal(int newGoal) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Aucun utilisateur trouvé');
      }

      final updatedUser = user.copyWith(
        dailyCalorieGoal: newGoal,
        updatedAt: DateTime.now(),
      );

      await saveUser(updatedUser);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'objectif: $e');
    }
  }

  /// Mettre à jour l'objectif (goal type)
  Future<void> updateGoal(GoalType newGoal) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Aucun utilisateur trouvé');
      }

      final updatedUser = user.copyWith(
        goal: newGoal,
        updatedAt: DateTime.now(),
      );

      await saveUser(updatedUser);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'objectif: $e');
    }
  }

  /// Mettre à jour le profil complet
  Future<void> updateProfile({
    String? name,
    String? email,
    int? age,
    int? height,
    int? weight,
    int? targetWeight,
    GoalType? goal,
    ActivityLevel? activityLevel,
    int? dailyCalorieGoal,
  }) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Aucun utilisateur trouvé');
      }

      final updatedUser = user.copyWith(
        name: name,
        email: email,
        age: age,
        height: height,
        weight: weight,
        targetWeight: targetWeight,
        goal: goal,
        activityLevel: activityLevel,
        dailyCalorieGoal: dailyCalorieGoal,
        updatedAt: DateTime.now(),
      );

      await saveUser(updatedUser);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Supprimer l'utilisateur actuel (déconnexion / reset)
  Future<void> deleteCurrentUser() async {
    try {
      await _storageService.userBox.delete(_currentUserKey);
      _currentUser = null;
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }

  /// Récupérer le BMI de l'utilisateur
  Future<double?> getCurrentBMI() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return null;

      return calculateBMI(user.weight, user.height);
    } catch (e) {
      return null;
    }
  }

  /// Vider le cache (forcer un rechargement depuis Hive)
  void clearCache() {
    _currentUser = null;
  }
}
