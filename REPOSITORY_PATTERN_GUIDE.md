# 📚 Guide complet : Repository Pattern dans FitMeals

## Table des matières
1. [Introduction](#introduction)
2. [Qu'est-ce que le Repository Pattern ?](#quest-ce-que-le-repository-pattern)
3. [Architecture avant/après](#architecture-avantaprès)
4. [Implémentation détaillée](#implémentation-détaillée)
5. [Exemples d'utilisation](#exemples-dutilisation)
6. [Avantages concrets](#avantages-concrets)
7. [Tests](#tests)
8. [Bonnes pratiques](#bonnes-pratiques)

---

## Introduction

Ce document explique comment le **Repository Pattern** a été implémenté dans l'application **FitMeals** pour gérer l'accès aux données de manière propre et maintenable.

### Contexte
FitMeals est une application de suivi de repas et de calories utilisant **Hive** (base de données locale NoSQL) pour la persistance des données.

### Problème initial
- Accès direct à Hive dispersé dans tous les screens
- Code dupliqué pour les opérations CRUD
- Difficile à tester
- Couplage fort entre UI et base de données

### Solution apportée
Implémentation du Repository Pattern avec 3 composants principaux :
1. **LocalStorageService** : Initialisation et gestion de Hive
2. **UserRepository** : Gestion des utilisateurs
3. **MealRepository** : Gestion des repas

---

## Qu'est-ce que le Repository Pattern ?

Le Repository Pattern est un **design pattern** qui crée une couche d'abstraction entre la logique métier et la source de données.

### Principe

```
┌─────────────┐
│  UI/Screen  │ ← Ne sait pas que Hive existe
└──────┬──────┘
       │ utilise
       ▼
┌─────────────┐
│ Repository  │ ← Interface simple et claire
└──────┬──────┘
       │ gère
       ▼
┌─────────────┐
│    Hive     │ ← Source de données réelle
└─────────────┘
```

### Bénéfices
- ✅ **Abstraction** : L'UI ne connaît pas les détails d'implémentation
- ✅ **Centralisation** : Une seule source de vérité pour les opérations de données
- ✅ **Testabilité** : Facile de mocker les repositories
- ✅ **Maintenabilité** : Changement de BDD ? Modifiez juste le repository
- ✅ **Réutilisabilité** : Même code dans toute l'app

---

## Architecture avant/après

### ❌ AVANT : Accès direct à Hive

```dart
// Dans onboarding_screen.dart
class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _finish() async {
    final user = UserModel(...);

    // ❌ Accès direct à Hive dans le screen
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    final box = await Hive.openBox<UserModel>('users');
    await box.put('currentUser', user);
  }
}

// Dans profile_screen.dart
class ProfileScreen extends StatelessWidget {
  Future<void> _loadUser() async {
    // ❌ Même code répété
    final box = await Hive.openBox<UserModel>('users');
    final user = box.get('currentUser');
  }
}
```

**Problèmes** :
- Code dupliqué dans chaque screen
- Impossible de tester sans Hive réel
- Si on change de BDD → modifier tous les screens
- Pas de cache, pas de gestion d'erreurs centralisée

### ✅ APRÈS : Avec Repository Pattern

```dart
// Dans onboarding_screen.dart
class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _finish() async {
    final user = UserModel(...);

    // ✅ Simple et clair
    await widget.userRepository.saveUser(user);
  }
}

// Dans profile_screen.dart
class ProfileScreen extends StatelessWidget {
  Future<void> _loadUser() async {
    // ✅ Même simplicité partout
    final user = await userRepository.getCurrentUser();
  }
}
```

**Avantages** :
- Code concis et lisible
- Facile à tester avec mock
- Changement de BDD → modifier uniquement le repository
- Cache, gestion d'erreurs, logs centralisés

---

## Implémentation détaillée

### 1. LocalStorageService

**Fichier** : `lib/core/services/local_storage_service.dart`

**Rôle** : Initialiser Hive et gérer les boxes

```dart
class LocalStorageService {
  static const String userBoxName = 'users';
  static const String mealBoxName = 'meals';

  Box<UserModel>? _userBox;
  Box<MealModel>? _mealBox;

  /// Initialise Hive et ouvre les boxes
  Future<void> init() async {
    await Hive.initFlutter();

    // Enregistrer les adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    // ... autres adapters

    // Ouvrir les boxes
    _userBox = await Hive.openBox<UserModel>(userBoxName);
    _mealBox = await Hive.openBox<MealModel>(mealBoxName);
  }

  /// Accès sécurisé à la box des utilisateurs
  Box<UserModel> get userBox {
    if (_userBox == null || !_userBox!.isOpen) {
      throw Exception('UserBox not initialized. Call init() first.');
    }
    return _userBox!;
  }

  // ... autres getters et méthodes
}
```

**Responsabilités** :
- ✅ Initialisation unique de Hive
- ✅ Enregistrement des adapters
- ✅ Ouverture et gestion des boxes
- ✅ Méthodes utilitaires (clear, close)

---

### 2. UserRepository

**Fichier** : `lib/data/repository/user_repository.dart`

**Rôle** : Gérer toutes les opérations liées aux utilisateurs

```dart
class UserRepository {
  final LocalStorageService _storageService;
  UserModel? _currentUser; // Cache en mémoire

  UserRepository(this._storageService);

  static const String _currentUserKey = 'currentUser';

  /// Sauvegarder un utilisateur
  Future<void> saveUser(UserModel user) async {
    try {
      await _storageService.userBox.put(_currentUserKey, user);
      _currentUser = user; // Mise en cache
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Récupérer l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    try {
      // Retourner le cache si disponible
      if (_currentUser != null) return _currentUser;

      // Sinon, charger depuis Hive
      _currentUser = _storageService.userBox.get(_currentUserKey);
      return _currentUser;
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Mettre à jour le poids
  Future<void> updateWeight(int newWeight) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('Aucun utilisateur trouvé');

    final updatedUser = user.copyWith(
      weight: newWeight,
      updatedAt: DateTime.now(),
    );

    await saveUser(updatedUser);
  }

  // ... autres méthodes
}
```

**Méthodes disponibles** :
- `saveUser(UserModel)` - Créer/mettre à jour un user
- `getCurrentUser()` - Récupérer le user actuel
- `hasUser()` - Vérifier si un user existe
- `updateWeight(int)` - Modifier le poids
- `updateProfile(...)` - Modifier le profil complet
- `deleteCurrentUser()` - Supprimer le user
- `getCurrentBMI()` - Calculer l'IMC
- `clearCache()` - Vider le cache

**Points clés** :
- ✅ Cache en mémoire pour les performances
- ✅ Gestion d'erreurs avec try/catch
- ✅ Utilisation de `copyWith()` pour l'immutabilité
- ✅ Validation des données

---

### 3. MealRepository

**Fichier** : `lib/data/repository/meal_repository.dart`

**Rôle** : Gérer toutes les opérations liées aux repas

```dart
class MealRepository {
  final LocalStorageService _storageService;

  MealRepository(this._storageService);

  /// Ajouter un repas
  Future<void> addMeal(MealModel meal) async {
    try {
      await _storageService.mealBox.put(meal.id, meal);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout: $e');
    }
  }

  /// Récupérer les repas du jour
  Future<List<MealModel>> getTodayMeals(String userId) async {
    return getMealsByDate(userId, DateTime.now());
  }

  /// Calculer les calories du jour
  Future<int> getTodayCalories(String userId) async {
    try {
      final meals = await getTodayMeals(userId);
      return meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    } catch (e) {
      throw Exception('Erreur calcul calories: $e');
    }
  }

  /// Obtenir des statistiques
  Future<Map<String, dynamic>> getStatistics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allMeals = await getUserMeals(userId);
    final periodMeals = allMeals.where((meal) {
      return meal.date.isAfter(startDate) &&
             meal.date.isBefore(endDate);
    }).toList();

    return {
      'totalMeals': periodMeals.length,
      'totalCalories': periodMeals.fold<int>(
        0,
        (sum, meal) => sum + meal.calories
      ),
      'averageCalories': periodMeals.isEmpty
        ? 0
        : periodMeals.fold<int>(0, (s, m) => s + m.calories) ~/ periodMeals.length,
      'breakfastCount': periodMeals.where((m) => m.mealType == MealType.breakfast).length,
      'lunchCount': periodMeals.where((m) => m.mealType == MealType.lunch).length,
      'dinnerCount': periodMeals.where((m) => m.mealType == MealType.dinner).length,
      'snackCount': periodMeals.where((m) => m.mealType == MealType.snack).length,
    };
  }

  // ... autres méthodes
}
```

**Méthodes disponibles** :
- `addMeal(MealModel)` - Ajouter un repas
- `getMealById(String)` - Récupérer un repas
- `getUserMeals(String)` - Tous les repas d'un user
- `getMealsByDate(String, DateTime)` - Repas d'une date
- `getTodayMeals(String)` - Repas d'aujourd'hui
- `getCaloriesForDate(String, DateTime)` - Calories d'une date
- `getTodayCalories(String)` - Calories d'aujourd'hui
- `getMealsByType(String, MealType, DateTime)` - Repas par type
- `updateMeal(MealModel)` - Modifier un repas
- `deleteMeal(String)` - Supprimer un repas
- `deleteAllUserMeals(String)` - Tout supprimer
- `getStatistics(String, DateTime, DateTime)` - Statistiques
- `isCalorieGoalReached(String, int)` - Objectif atteint ?
- `getCaloriesRemaining(String, int)` - Calories restantes

**Points clés** :
- ✅ Logique métier complexe centralisée
- ✅ Calculs de calories et statistiques
- ✅ Filtrage par date, type, user
- ✅ Méthodes composables et réutilisables

---

### 4. Initialisation dans main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Créer le service de stockage
  final storageService = LocalStorageService();
  await storageService.init();

  // 2. Créer les repositories
  final userRepository = UserRepository(storageService);
  final mealRepository = MealRepository(storageService);

  // 3. Lancer l'app avec injection de dépendances
  runApp(MyApp(
    userRepository: userRepository,
    mealRepository: mealRepository,
  ));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  final MealRepository mealRepository;

  const MyApp({
    required this.userRepository,
    required this.mealRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WelcomeScreen(userRepository: userRepository),
    );
  }
}
```

**Architecture d'initialisation** :
```
main()
  ↓
LocalStorageService.init()
  ↓
Créer UserRepository(storageService)
  ↓
Créer MealRepository(storageService)
  ↓
MyApp(repositories)
  ↓
WelcomeScreen(userRepository)
  ↓
OnboardingScreen(userRepository)
```

---

## Exemples d'utilisation

### Exemple 1 : Créer un utilisateur (Onboarding)

```dart
// Dans onboarding_screen.dart
class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _finish() async {
    try {
      // 1. Créer le modèle
      final user = UserModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        email: _emailController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        height: int.parse(_heightController.text),
        weight: int.parse(_weightController.text),
        goal: _selectedGoal!,
        activityLevel: _selectedActivityLevel!,
        dailyCalorieGoal: calculatedCalories,
        profilePictureUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 2. Sauvegarder via le repository
      await widget.userRepository.saveUser(user);

      // 3. Navigation
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }
    } catch (e) {
      // 4. Gestion d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
```

### Exemple 2 : Afficher le profil utilisateur

```dart
// Dans profile_screen.dart
class ProfileScreen extends StatefulWidget {
  final UserRepository userRepository;

  const ProfileScreen({required this.userRepository});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);

    try {
      final user = await widget.userRepository.getCurrentUser();
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    if (_user == null) return Text('Aucun utilisateur');

    return Column(
      children: [
        Text('Nom: ${_user!.name}'),
        Text('Poids: ${_user!.weight} kg'),
        Text('Objectif: ${_user!.dailyCalorieGoal} kcal'),
        ElevatedButton(
          onPressed: () => _updateWeight(),
          child: Text('Mettre à jour le poids'),
        ),
      ],
    );
  }

  Future<void> _updateWeight() async {
    try {
      await widget.userRepository.updateWeight(75);
      await _loadUser(); // Recharger
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poids mis à jour!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
```

### Exemple 3 : Ajouter et suivre les repas

```dart
// Dans add_meal_screen.dart
class AddMealScreen extends StatelessWidget {
  final MealRepository mealRepository;
  final UserRepository userRepository;

  Future<void> _addMeal(BuildContext context) async {
    try {
      // 1. Récupérer le user
      final user = await userRepository.getCurrentUser();
      if (user == null) throw Exception('Utilisateur non trouvé');

      // 2. Créer le repas
      final meal = MealModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        description: _descriptionController.text,
        calories: int.parse(_caloriesController.text),
        date: DateTime.now(),
        userId: user.id,
        mealType: _selectedMealType!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Sauvegarder
      await mealRepository.addMeal(meal);

      // 4. Vérifier si objectif atteint
      final todayCalories = await mealRepository.getTodayCalories(user.id);
      final remaining = user.dailyCalorieGoal - todayCalories;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remaining > 0
                ? 'Repas ajouté! Il vous reste $remaining kcal'
                : 'Objectif atteint! 🎉'
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
```

### Exemple 4 : Dashboard avec statistiques

```dart
// Dans home_screen.dart
class HomeScreen extends StatefulWidget {
  final UserRepository userRepository;
  final MealRepository mealRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  List<MealModel> _todayMeals = [];
  int _todayCalories = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // Charger en parallèle
      final results = await Future.wait([
        widget.userRepository.getCurrentUser(),
        widget.mealRepository.getTodayMeals(_user!.id),
        widget.mealRepository.getTodayCalories(_user!.id),
      ]);

      setState(() {
        _user = results[0] as UserModel?;
        _todayMeals = results[1] as List<MealModel>;
        _todayCalories = results[2] as int;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    if (_user == null) return Text('Erreur');

    final remaining = _user!.dailyCalorieGoal - _todayCalories;
    final progress = _todayCalories / _user!.dailyCalorieGoal;

    return Scaffold(
      appBar: AppBar(title: Text('Bonjour ${_user!.name}')),
      body: Column(
        children: [
          // Indicateur de progression
          CircularProgressIndicator(value: progress),
          Text('$_todayCalories / ${_user!.dailyCalorieGoal} kcal'),
          Text(
            remaining > 0
              ? 'Encore $remaining kcal disponibles'
              : 'Objectif atteint! 🎉'
          ),

          // Liste des repas
          Expanded(
            child: ListView.builder(
              itemCount: _todayMeals.length,
              itemBuilder: (context, index) {
                final meal = _todayMeals[index];
                return ListTile(
                  title: Text(meal.name),
                  subtitle: Text('${meal.calories} kcal'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteMeal(meal.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddMeal(),
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteMeal(String mealId) async {
    try {
      await widget.mealRepository.deleteMeal(mealId);
      await _loadData(); // Recharger
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Repas supprimé')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
```

### Exemple 5 : Statistiques hebdomadaires

```dart
// Dans statistics_screen.dart
class StatisticsScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final UserRepository userRepository;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);

    try {
      final user = await widget.userRepository.getCurrentUser();
      if (user == null) throw Exception('Utilisateur non trouvé');

      // Statistiques de la semaine dernière
      final now = DateTime.now();
      final weekAgo = now.subtract(Duration(days: 7));

      final stats = await widget.mealRepository.getStatistics(
        user.id,
        weekAgo,
        now,
      );

      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    if (_stats == null) return Text('Pas de données');

    return Scaffold(
      appBar: AppBar(title: Text('Statistiques')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette semaine',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20),
            _buildStatCard(
              'Total de repas',
              '${_stats!['totalMeals']}',
              Icons.restaurant,
            ),
            _buildStatCard(
              'Calories totales',
              '${_stats!['totalCalories']} kcal',
              Icons.local_fire_department,
            ),
            _buildStatCard(
              'Moyenne par jour',
              '${_stats!['averageCalories']} kcal',
              Icons.trending_up,
            ),
            SizedBox(height: 20),
            Text(
              'Répartition',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            _buildMealTypeBar(
              'Petit-déjeuner',
              _stats!['breakfastCount'],
              Colors.orange,
            ),
            _buildMealTypeBar(
              'Déjeuner',
              _stats!['lunchCount'],
              Colors.green,
            ),
            _buildMealTypeBar(
              'Dîner',
              _stats!['dinnerCount'],
              Colors.blue,
            ),
            _buildMealTypeBar(
              'Snacks',
              _stats!['snackCount'],
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMealTypeBar(String label, int count, Color color) {
    final total = _stats!['totalMeals'];
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: count / (total > 0 ? total : 1),
              backgroundColor: Colors.grey[300],
              color: color,
              minHeight: 20,
            ),
          ),
          SizedBox(width: 10),
          Text('$count ($percentage%)'),
        ],
      ),
    );
  }
}
```

---

## Avantages concrets

### 1. Code plus propre et lisible

**Avant** :
```dart
// 15 lignes pour sauvegarder un user
await Hive.initFlutter();
Hive.registerAdapter(UserModelAdapter());
Hive.registerAdapter(GoalTypeAdapter());
Hive.registerAdapter(ActivityLevelAdapter());
final box = await Hive.openBox<UserModel>('users');
await box.put('currentUser', user);
// Pas de cache, pas de gestion d'erreur
```

**Après** :
```dart
// 1 ligne claire
await userRepository.saveUser(user);
// Cache, gestion d'erreur, logs inclus
```

### 2. Testabilité

```dart
// test/repositories/user_repository_test.dart
void main() {
  late MockLocalStorageService mockStorage;
  late UserRepository repository;

  setUp(() {
    mockStorage = MockLocalStorageService();
    repository = UserRepository(mockStorage);
  });

  test('saveUser should save user and update cache', () async {
    // Arrange
    final user = UserModel(
      id: '123',
      name: 'Test User',
      // ...
    );
    when(mockStorage.userBox).thenReturn(mockBox);

    // Act
    await repository.saveUser(user);

    // Assert
    verify(mockBox.put('currentUser', user)).called(1);
    final cachedUser = await repository.getCurrentUser();
    expect(cachedUser?.id, equals('123'));
  });

  test('updateWeight should update user weight', () async {
    // ...
  });
}
```

### 3. Changement de base de données facile

Si demain vous voulez passer de Hive à Firebase :

```dart
// Créer un nouveau repository
class UserFirebaseRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  UserFirebaseRepository(this._firestore);

  @override
  Future<void> saveUser(UserModel user) async {
    await _firestore
      .collection('users')
      .doc(user.id)
      .set(user.toJson());
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final doc = await _firestore
      .collection('users')
      .doc('currentUserId')
      .get();

    if (!doc.exists) return null;
    return UserModelFromJson.fromJson(doc.data()!);
  }

  // ... autres méthodes
}

// Dans main.dart, changer juste 1 ligne :
final userRepository = UserFirebaseRepository(firestore); // Au lieu de UserRepository
```

**Aucun screen à modifier !** 🎉

### 4. Logique métier centralisée

Toutes les opérations complexes sont au même endroit :

```dart
// Calculer les statistiques de la semaine
final stats = await mealRepository.getStatistics(
  userId,
  DateTime.now().subtract(Duration(days: 7)),
  DateTime.now(),
);

// Vérifier si objectif atteint
final isReached = await mealRepository.isCalorieGoalReached(
  userId,
  2000,
);

// Obtenir les calories restantes
final remaining = await mealRepository.getCaloriesRemaining(
  userId,
  2000,
);
```

Pas besoin de réécrire cette logique dans chaque screen !

### 5. Performance avec cache

```dart
class UserRepository {
  UserModel? _currentUser; // Cache

  Future<UserModel?> getCurrentUser() async {
    // Si en cache, retour instantané
    if (_currentUser != null) return _currentUser;

    // Sinon, lecture depuis Hive (plus lent)
    _currentUser = _storageService.userBox.get('currentUser');
    return _currentUser;
  }
}
```

**Premier appel** : Lit depuis Hive (~5ms)
**Appels suivants** : Retourne le cache (~0.1ms)
**50x plus rapide !** ⚡

---

## Tests

### Test unitaire du UserRepository

```dart
// test/repositories/user_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([LocalStorageService, Box])
void main() {
  late MockLocalStorageService mockStorage;
  late MockBox<UserModel> mockBox;
  late UserRepository repository;

  setUp(() {
    mockStorage = MockLocalStorageService();
    mockBox = MockBox<UserModel>();
    when(mockStorage.userBox).thenReturn(mockBox);
    repository = UserRepository(mockStorage);
  });

  group('UserRepository', () {
    test('getCurrentUser returns cached user if available', () async {
      // Arrange
      final user = UserModel(
        id: '123',
        name: 'Test',
        email: 'test@test.com',
        age: 25,
        gender: 'male',
        height: 180,
        weight: 75,
        profilePictureUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        goal: GoalType.maintainWeight,
        activityLevel: ActivityLevel.moderatelyActive,
        dailyCalorieGoal: 2000,
      );

      // First call - load from Hive
      when(mockBox.get('currentUser')).thenReturn(user);
      await repository.getCurrentUser();

      // Act - Second call should use cache
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, equals(user));
      verify(mockBox.get('currentUser')).called(1); // Called only once
    });

    test('saveUser stores user and updates cache', () async {
      // Arrange
      final user = UserModel(/* ... */);
      when(mockBox.put(any, any)).thenAnswer((_) async => {});

      // Act
      await repository.saveUser(user);

      // Assert
      verify(mockBox.put('currentUser', user)).called(1);
      final cached = await repository.getCurrentUser();
      expect(cached, equals(user));
    });

    test('updateWeight updates user weight correctly', () async {
      // Arrange
      final originalUser = UserModel(
        id: '123',
        weight: 70,
        /* ... */
      );
      when(mockBox.get('currentUser')).thenReturn(originalUser);
      when(mockBox.put(any, any)).thenAnswer((_) async => {});

      // Act
      await repository.updateWeight(75);

      // Assert
      final updated = await repository.getCurrentUser();
      expect(updated?.weight, equals(75));
    });

    test('hasUser returns true when user exists', () {
      // Arrange
      when(mockBox.get('currentUser')).thenReturn(UserModel(/* ... */));

      // Act
      final result = repository.hasUser();

      // Assert
      expect(result, isTrue);
    });

    test('hasUser returns false when no user', () {
      // Arrange
      when(mockBox.get('currentUser')).thenReturn(null);

      // Act
      final result = repository.hasUser();

      // Assert
      expect(result, isFalse);
    });
  });
}
```

### Test d'intégration

```dart
// test/integration/user_flow_test.dart
void main() {
  testWidgets('Complete user onboarding flow', (tester) async {
    // Setup
    final storageService = LocalStorageService();
    await storageService.init();
    final userRepository = UserRepository(storageService);

    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(userRepository: userRepository),
    ));

    // Test: Fill form and save user
    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), 'john@test.com');
    // ... fill other fields

    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    // Verify: User was saved
    final savedUser = await userRepository.getCurrentUser();
    expect(savedUser?.name, equals('John Doe'));
    expect(savedUser?.email, equals('john@test.com'));
  });
}
```

---

## Bonnes pratiques

### 1. Injection de dépendances

✅ **BON** : Passer les repositories via le constructeur
```dart
class ProfileScreen extends StatelessWidget {
  final UserRepository userRepository;

  const ProfileScreen({required this.userRepository});
}
```

❌ **MAUVAIS** : Créer les repositories dans le widget
```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repository = UserRepository(...); // ❌ Ne pas faire
  }
}
```

### 2. Gestion des erreurs

✅ **BON** : Try/catch dans le repository ET dans l'UI
```dart
// Repository
Future<void> saveUser(UserModel user) async {
  try {
    await _storageService.userBox.put('currentUser', user);
  } catch (e) {
    throw Exception('Erreur sauvegarde: $e'); // Exception typée
  }
}

// UI
try {
  await repository.saveUser(user);
  // Succès
} catch (e) {
  // Afficher erreur à l'utilisateur
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$e')),
  );
}
```

### 3. Nommage des méthodes

✅ **BON** : Noms clairs et descriptifs
```dart
getUserMeals(userId)
getTodayCalories(userId)
isCalorieGoalReached(userId, goal)
```

❌ **MAUVAIS** : Noms ambigus
```dart
getMeals() // Tous les repas ? D'un user ? D'aujourd'hui ?
check(userId, goal) // Check quoi ?
```

### 4. Méthodes courtes et composables

✅ **BON** : Petites méthodes réutilisables
```dart
Future<List<MealModel>> getTodayMeals(String userId) {
  return getMealsByDate(userId, DateTime.now());
}

Future<int> getTodayCalories(String userId) {
  return getCaloriesForDate(userId, DateTime.now());
}
```

❌ **MAUVAIS** : Une grosse méthode qui fait tout
```dart
Future<Map> getAllData(String userId) {
  // 100 lignes de code...
}
```

### 5. Cache intelligent

✅ **BON** : Cache avec invalidation
```dart
class UserRepository {
  UserModel? _currentUser;

  void clearCache() {
    _currentUser = null; // Forcer rechargement
  }

  Future<void> updateWeight(int weight) async {
    // ... update
    clearCache(); // Invalider le cache
  }
}
```

### 6. Documentation

✅ **BON** : Documenter les méthodes complexes
```dart
/// Calcule les statistiques pour une période donnée.
///
/// Retourne un Map contenant :
/// - totalMeals : nombre total de repas
/// - totalCalories : calories totales
/// - averageCalories : moyenne de calories par jour
/// - breakfastCount/lunchCount/dinnerCount/snackCount
///
/// Example:
/// ```dart
/// final stats = await repository.getStatistics(
///   userId,
///   DateTime(2024, 1, 1),
///   DateTime(2024, 1, 31),
/// );
/// print(stats['totalCalories']); // 45000
/// ```
Future<Map<String, dynamic>> getStatistics(...) async {
  // ...
}
```

### 7. Logs pour le debug

```dart
class UserRepository {
  Future<void> saveUser(UserModel user) async {
    try {
      debugPrint('📝 Saving user: ${user.id}');
      await _storageService.userBox.put('currentUser', user);
      _currentUser = user;
      debugPrint('✅ User saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving user: $e');
      throw Exception('Erreur sauvegarde: $e');
    }
  }
}
```

---

## Conclusion

Le Repository Pattern a transformé l'architecture de FitMeals :

### Avant
- ❌ Code dupliqué partout
- ❌ Couplage fort avec Hive
- ❌ Difficile à tester
- ❌ Logique dispersée

### Après
- ✅ Code propre et DRY
- ✅ Abstraction de la source de données
- ✅ Facilement testable
- ✅ Logique métier centralisée
- ✅ Cache et performances
- ✅ Gestion d'erreurs robuste

### Résultat
Une application **plus maintenable, évolutive et professionnelle** ! 🚀

---

## Ressources

- [Documentation Hive](https://docs.hivedb.dev/)
- [Repository Pattern (Martin Fowler)](https://martinfowler.com/eaaCatalog/repository.html)
- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)

---

**Créé pour FitMeals** 🥗
*Version 1.0 - Novembre 2024*
