# 🏗️ HEALTHSYNC - Architecture Multi-Capteurs

> **Application mobile de collecte et d'analyse de données de santé pour l'intelligence artificielle**

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![Hive](https://img.shields.io/badge/Storage-Hive-orange)](https://docs.hivedb.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Layered%20%2B%20SCC-green)](https://github.com)

---

## 📋 Table des Matières

1. [Architecture Globale](#-architecture-globale)
2. [Network/Entity Layer](#-networkentity-layer)
3. [Software Engineering Layer](#-software-engineering-layer)
4. [Microservices Components Layer](#-microservices-components-layer)

---

## 🏛️ Architecture Globale

### Schéma Conceptuel

```
┌─────────────────────────────────────────────────────────────┐
│              🌐 NETWORK/ENTITY LAYER                        │
│         (Entités Principales & Contraintes)                 │
│                                                             │
│  📊 CentralDataModel                                        │
│  ├─ But : Hub central des données utilisateur              │
│  ├─ Enjeux : Agrégation multi-capteurs                     │
│  └─ Contraintes : Cohérence des données                    │
│                                                             │
│  Entités Principales:                                       │
│  ├─ Profil utilisateur (nom, email, photo)                 │
│  ├─ Données physiques (âge, sexe, taille, poids)          │
│  ├─ BMI (calculé automatiquement)                         │
│  └─ Configuration capteurs actifs                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│             💻 SOFTWARE ENGINEERING LAYER                   │
│                                                             │
│  Architecture en Couches:                                   │
│  ├─ Repositories (accès données)                           │
│  ├─ Services (logique métier)                              │
│  └─ UI (présentation)                                      │
│                                                             │
│  Pattern Sense-Compute-Control (SCC):                      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🔍 SENSE (Percevoir)                               │   │
│  │  ├─ GPS Stream (position temps réel)               │   │
│  │  ├─ Bluetooth Scan (appareils proches)             │   │
│  │  ├─ User Input (saisie manuelle repas)             │   │
│  │  └─ API Fetch (données nutritionnelles)            │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ↓                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🧮 COMPUTE (Calculer)                              │   │
│  │  ├─ Calcul BMI (height, weight → BMI)              │   │
│  │  ├─ Calcul Calories (Mifflin-St Jeor)              │   │
│  │  ├─ Détection activité (vitesse → type)            │   │
│  │  ├─ Matching contacts (BT name → contact)          │   │
│  │  └─ Calcul distance (Haversine)                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ↓                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ⚙️ CONTROL (Contrôler)                             │   │
│  │  ├─ Mise à jour UI en temps réel                   │   │
│  │  ├─ Sauvegarde Hive                                │   │
│  │  ├─ Export MCP                                     │   │
│  │  └─ Notifications                                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│          🔧 MICROSERVICES COMPONENTS LAYER                  │
│         (Capteurs Indépendants & Modulaires)                │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐    │
│  │ 🍽️ Repas │  │ 😴Sommeil│  │👥Bluetooth│ │📍 GPS  │    │
│  │  (Meals) │  │ (Sleep)  │  │ (Social) │  │(Location)   │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘    │
│                                                             │
│  Chaque capteur possède:                                   │
│  ├─ SensorDataModel (configuration)                        │
│  ├─ RecordModel[] (données collectées)                     │
│  ├─ Repository (accès données)                             │
│  └─ UI Tab (interface utilisateur)                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
                    📤 Export MCP
                           ↓
                  🤖 Serveur MCP (IA)
```

---

## 🌐 Network/Entity Layer

### But, Enjeux et Contraintes

#### But
- Centraliser les données utilisateur
- Définir les entités principales du système
- Gérer la communication avec les services externes

#### Enjeux
- Cohérence des données entre capteurs
- Validation des contraintes métier
- Intégrité des données physiques

#### Contraintes
- Un seul profil utilisateur par application
- BMI calculé automatiquement (non modifiable)
- Activation/désactivation dynamique des capteurs
- Communication externe HTTPS uniquement

---

### Entités Principales

#### 1. CentralDataModel (Hub Central)

```dart
@HiveType(typeId: 5)
class CentralDataModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  int age;

  @HiveField(4)
  String gender;

  @HiveField(5)
  int height; // cm

  @HiveField(6)
  int weight; // kg

  @HiveField(7)
  String? photoPath;

  @HiveField(8)
  List<String> activeSensors; // ["meals", "social", "sleep", "location"]

  @HiveField(9)
  Map<String, dynamic> preferences;

  @HiveField(10)
  DateTime createdAt;

  // Calculé automatiquement
  double get bmi => weight / pow(height / 100, 2);
}
```

**Contraintes** :
- `height` : 100-250 cm
- `weight` : 30-300 kg
- `age` : 13-120 ans
- `gender` : "male", "female", "other"
- `activeSensors` : liste modifiable dynamiquement

---

#### 2. Communication Externe

**API Spoonacular** (Nutrition)
- Endpoint : `https://api.spoonacular.com/`
- Authentification : API Key
- Usage : Recherche recettes, informations nutritionnelles

**Export MCP** (Intelligence Artificielle)
- Format : JSON structuré
- Protocole : Model Context Protocol
- Anonymisation : Hash identifiants personnels

---

## 💻 Software Engineering Layer

### Architecture en Couches

```
┌──────────────────────────────────┐
│   PRESENTATION LAYER (UI)        │
│   - Screens                      │
│   - Widgets                      │
│   - State Management             │
└─────────────┬────────────────────┘
              ↓
┌──────────────────────────────────┐
│   BUSINESS LOGIC LAYER           │
│   - Repositories                 │
│   - Services                     │
│   - Use Cases                    │
└─────────────┬────────────────────┘
              ↓
┌──────────────────────────────────┐
│   DATA ACCESS LAYER              │
│   - LocalStorageService (Hive)   │
│   - API Clients                  │
│   - External Services            │
└──────────────────────────────────┘
```

**Principe** : Séparation stricte des responsabilités
- UI ne communique JAMAIS directement avec Hive
- Repositories abstrait le stockage
- Services contiennent la logique métier

---

### Pattern Sense-Compute-Control (SCC)

#### Qu'est-ce que SCC ?

Pattern architectural spécialisé pour **systèmes IoT et capteurs intelligents**.

```
SENSE    : Collecter des données brutes depuis capteurs/API
   ↓
COMPUTE  : Traiter, calculer, enrichir les données
   ↓
CONTROL  : Agir sur le système (UI, stockage, notifications)
```

---

#### Exemple 1 : Capteur Repas (Meals)

##### SENSE (Percevoir)
```dart
// L'utilisateur saisit un repas manuellement
Future<void> addMeal() async {
  final mealData = await _showMealForm();
  // Données brutes : nom, calories, protéines, glucides, lipides
}
```

##### COMPUTE (Calculer)
```dart
// Enrichissement des données
Future<void> processMeal(MealModel meal) async {
  // Calcul total calorique du jour
  final todayMeals = await _repository.getMealsByDate(DateTime.now());
  final totalCalories = todayMeals.fold(0, (sum, m) => sum + m.calories);

  // Comparaison avec objectif
  final goal = _centralData.calorieGoal;
  final progress = (totalCalories / goal) * 100;
}
```

##### CONTROL (Contrôler)
```dart
// Actions sur le système
Future<void> saveMeal(MealModel meal) async {
  // 1. Sauvegarde Hive
  await _repository.saveMeal(meal);

  // 2. Mise à jour UI
  notifyListeners();

  // 3. Notification si objectif atteint
  if (progress >= 100) {
    _showNotification("Objectif calorique atteint !");
  }
}
```

---

#### Exemple 2 : Capteur Bluetooth (Social)

##### SENSE (Percevoir)
```dart
// Scan Bluetooth toutes les 5 minutes
Timer.periodic(Duration(minutes: 5), (timer) async {
  final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
  // Données brutes : List<BluetoothDevice>
});
```

##### COMPUTE (Calculer)
```dart
// Matching avec contacts
Future<Contact?> matchContact(BluetoothDevice device) async {
  final contacts = await ContactsService.getContacts();

  // Algorithme de scoring
  for (var contact in contacts) {
    int score = 0;
    if (device.name.contains(contact.givenName)) score += 50;
    if (device.name.contains(contact.familyName)) score += 50;
    if (score >= 50) return contact;
  }

  return null;
}
```

##### CONTROL (Contrôler)
```dart
// Validation et sauvegarde
Future<void> saveInteraction(TemporaryDetection detection) async {
  // Contrainte : durée ≥5 minutes
  if (detection.duration.inMinutes >= 5) {
    final interaction = SocialInteractionModel(
      contactName: detection.contact.displayName,
      macAddress: detection.address,
      durationMinutes: detection.duration.inMinutes,
    );

    // Sauvegarde
    await _repository.saveInteraction(interaction);

    // Notification
    _showNotification("Rencontre avec ${detection.contact.displayName}");
  }
}
```

---

#### Exemple 3 : Capteur GPS (Location)

##### SENSE (Percevoir)
```dart
// Stream GPS continu
Stream<Position> positionStream = Geolocator.getPositionStream(
  locationSettings: LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Mise à jour tous les 10m
  ),
);
```

##### COMPUTE (Calculer)
```dart
// Détection d'activité basée sur vitesse
ActivityType detectActivity(double speedMs) {
  if (speedMs < 0.5) return ActivityType.stationary;
  if (speedMs < 2.0) return ActivityType.walking;
  if (speedMs < 5.0) return ActivityType.running;
  return ActivityType.cycling;
}

// Calcul distance (formule Haversine)
double calculateDistance(List<LocationPoint> points) {
  double totalDistance = 0.0;
  for (int i = 1; i < points.length; i++) {
    totalDistance += _haversine(points[i-1], points[i]);
  }
  return totalDistance;
}
```

##### CONTROL (Contrôler)
```dart
// Sauvegarde session GPS
Future<void> endSession(LocationRecordModel record) async {
  // Calcul des statistiques
  record.totalDistance = calculateDistance(record.points);
  record.averageSpeed = record.totalDistance / record.duration.inSeconds;
  record.detectedActivity = detectActivity(record.averageSpeed);

  // Sauvegarde
  await _repository.saveLocationRecord(record);

  // Mise à jour UI
  _updateMap(record.points);
}
```

---

## 🔧 Microservices Components Layer

### Architecture Microservices (4 Capteurs)

Chaque capteur fonctionne comme un **microservice indépendant** :
- Configuration propre (SensorDataModel)
- Stockage dédié (Box Hive)
- Repository isolé
- UI indépendante (Tab)

---

### Capteur 1 : 🍽️ Repas (Meals)

#### Configuration

```dart
@HiveType(typeId: 6)
class MealsSensorDataModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String goal; // "lose_weight", "gain_weight", "maintain"

  @HiveField(3)
  int targetWeight; // kg

  @HiveField(4)
  double activityLevel; // 1.2 (sedentary) à 1.9 (very active)

  @HiveField(5)
  int dailyCalorieGoal; // calculé via Mifflin-St Jeor

  @HiveField(6)
  Map<String, dynamic> nutritionPreferences;
}
```

#### Modèle de Données

```dart
@HiveType(typeId: 2)
class MealModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String description;

  @HiveField(4)
  int calories;

  @HiveField(5)
  double proteins; // grammes

  @HiveField(6)
  double carbs; // grammes

  @HiveField(7)
  double fats; // grammes

  @HiveField(8)
  String mealType; // "breakfast", "lunch", "dinner", "snack"

  @HiveField(9)
  DateTime date;
}
```

#### Fonctionnalités
- Ajout manuel de repas
- Recherche recettes (Spoonacular API)
- Calcul calories quotidiennes
- Suivi macronutriments (protéines, glucides, lipides)
- Progression vers objectif calorique

---

### Capteur 2 : 😴 Sommeil (Sleep)

#### Configuration

```dart
@HiveType(typeId: 9)
class SleepSensorDataModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  int sleepGoalHours; // Objectif heures de sommeil

  @HiveField(3)
  String bedtimeReminder; // "22:00"

  @HiveField(4)
  Map<String, dynamic> sleepPreferences;
}
```

#### Modèle de Données

```dart
@HiveType(typeId: 10)
class SleepRecordModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  DateTime bedtime; // Heure de coucher

  @HiveField(3)
  DateTime wakeTime; // Heure de réveil

  @HiveField(4)
  int durationMinutes; // Calculé automatiquement

  @HiveField(5)
  String quality; // "poor", "fair", "good", "excellent"

  @HiveField(6)
  int interruptions; // Nombre de réveils

  @HiveField(7)
  String notes; // Commentaires optionnels

  @HiveField(8)
  DateTime date;
}
```

#### Fonctionnalités
- Saisie heures coucher/réveil
- Calcul durée de sommeil
- Évaluation qualité (échelle 4 niveaux)
- Suivi interruptions nocturnes
- Statistiques hebdomadaires

---

### Capteur 3 : 👥 Bluetooth (Social)

#### Configuration

```dart
@HiveType(typeId: 12)
class SocialSensorDataModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  int dailyInteractionGoal; // Nombre interactions/jour

  @HiveField(3)
  int minimumDurationMinutes; // Durée minimale (défaut: 5)

  @HiveField(4)
  Map<String, dynamic> socialPreferences;
}
```

#### Modèle de Données

```dart
@HiveType(typeId: 13)
class SocialInteractionModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String contactName; // Nom du contact matché

  @HiveField(3)
  String macAddress; // Adresse MAC Bluetooth

  @HiveField(4)
  DateTime firstSeen; // Première détection

  @HiveField(5)
  DateTime lastSeen; // Dernière détection

  @HiveField(6)
  int durationMinutes; // Durée totale

  @HiveField(7)
  int encounterCount; // Nombre de rencontres

  @HiveField(8)
  String interactionType; // "brief", "casual", "extended"

  @HiveField(9)
  DateTime date;
}
```

#### Fonctionnalités
- Scan Bluetooth continu (toutes les 5 minutes)
- Matching nom appareil ↔ contact téléphone
- Validation durée ≥5 minutes (évite faux positifs)
- Tracking interactions sociales
- Statistiques quotidiennes

#### Contraintes Techniques
- **Limitation Flutter** : Pas de service background natif
- **Solution** : Scan foreground uniquement (app ouverte)
- **Permissions** : Bluetooth, Location, Contacts

---

### Capteur 4 : 📍 GPS (Location)

#### Configuration

```dart
@HiveType(typeId: 16)
class LocationSensorDataModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  int dailyStepsGoal; // Objectif pas/jour

  @HiveField(3)
  double dailyDistanceGoalKm; // Objectif distance

  @HiveField(4)
  Map<String, dynamic> locationPreferences;
}
```

#### Modèle de Données

```dart
@HiveType(typeId: 17)
class LocationRecordModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  DateTime startTime;

  @HiveField(3)
  DateTime endTime;

  @HiveField(4)
  List<LocationPoint> points; // Liste coordonnées GPS

  @HiveField(5)
  double totalDistanceKm; // Calculé via Haversine

  @HiveField(6)
  double averageSpeedMs; // Vitesse moyenne (m/s)

  @HiveField(7)
  String detectedActivity; // "walking", "running", "cycling"

  @HiveField(8)
  String? placeName; // Lieu associé (optionnel)

  @HiveField(9)
  DateTime date;
}

@HiveType(typeId: 18)
class LocationPoint {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  @HiveField(2)
  DateTime timestamp;
}
```

#### Fonctionnalités
- Tracking GPS temps réel (stream)
- Calcul distance parcourue (formule Haversine)
- Détection automatique activité (vitesse)
- Gestion lieux favoris (geofencing)
- Statistiques activité physique

#### Détection Activité

```dart
ActivityType detectActivity(double speedMs) {
  if (speedMs < 0.5) return ActivityType.stationary; // < 1.8 km/h
  if (speedMs < 2.0) return ActivityType.walking;    // < 7.2 km/h
  if (speedMs < 5.0) return ActivityType.running;    // < 18 km/h
  return ActivityType.cycling;                       // ≥ 18 km/h
}
```

---

## 📊 Récapitulatif Architecture

### Tableau Synoptique

| Couche | Responsabilité | Composants | Technologies |
|--------|----------------|------------|--------------|
| **Network/Entity** | Entités & Contraintes | CentralDataModel, API externe | Hive, HTTP |
| **Software Engineering** | Logique métier | Repositories, Services, SCC | Dart, Flutter |
| **Microservices** | Capteurs modulaires | Meals, Sleep, Social, GPS | Hive, Native Services |

---

### Flux de Données

```
User Input → SENSE → COMPUTE → CONTROL → Hive Storage → Export MCP → IA
```

---

### Hive Boxes (Stockage)

| Box | TypeId | Contenu | Cardinalité |
|-----|--------|---------|-------------|
| `central_data_box` | 5 | CentralDataModel | 1 |
| `meals_sensor_box` | 6 | MealsSensorDataModel | 1 |
| `meals_box` | 2 | MealModel[] | N |
| `sleep_sensor_box` | 9 | SleepSensorDataModel | 1 |
| `sleep_records_box` | 10 | SleepRecordModel[] | N |
| `social_sensor_box` | 12 | SocialSensorDataModel | 1 |
| `social_interactions_box` | 13 | SocialInteractionModel[] | N |
| `location_sensor_box` | 16 | LocationSensorDataModel | 1 |
| `location_records_box` | 17 | LocationRecordModel[] | N |

**Total : 9 Hive Boxes**

---

## 🎯 Conclusion

**HealthSync** implémente une architecture **3 couches** :

1. **Network/Entity Layer** : Entités principales + contraintes métier
2. **Software Engineering Layer** : Architecture en couches + Pattern SCC
3. **Microservices Components Layer** : 4 capteurs modulaires indépendants

Cette architecture garantit :
- ✅ Modularité (ajout/suppression capteurs)
- ✅ Scalabilité (10+ capteurs futurs)
- ✅ Maintenabilité (séparation responsabilités)
- ✅ Testabilité (logique métier isolée)
