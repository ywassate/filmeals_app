# 🏗️ Architecture 2 : Hub Multi-Capteurs

## Vue d'ensemble

**FitMeals Health Hub** est une plateforme centralisée de collecte de données de santé via 4 capteurs indépendants.

### Principe

- ✅ **Hub Central** : Données communes partagées
- ✅ **4 Capteurs indépendants** : Repas, Sommeil, Social, GPS
- ✅ **Données séparées** : Centrales vs Spécifiques
- ✅ **Export modulaire MCP** : Format structuré avec métadonnées

---

## 🏛️ Architecture Globale

```
┌───────────────────────────────────────────────────┐
│          HEALTH HUB (Application Centrale)        │
├───────────────────────────────────────────────────┤
│                                                   │
│  📊 DONNÉES CENTRALES (CentralDataModel)         │
│  ├── Profil utilisateur (nom, email, photo)      │
│  ├── Données physiques (âge, sexe, taille, poids)│
│  ├── BMI (calculé automatiquement)               │
│  ├── Capteurs actifs (liste)                     │
│  └── Préférences globales                        │
│                                                   │
├───────────────────────────────────────────────────┤
│                                                   │
│  🍽️  CAPTEUR 1 : REPAS (ACTIF)                  │
│  ├── MealsSensorDataModel                        │
│  │   ├── Objectif (perte/gain/maintien)         │
│  │   ├── Poids cible                             │
│  │   ├── Niveau d'activité                       │
│  │   ├── Objectif calorique journalier          │
│  │   └── Préférences nutritionnelles            │
│  └── MealModel[] (repas enregistrés)             │
│                                                   │
│  😴 CAPTEUR 2 : SOMMEIL (À VENIR)               │
│  ├── SleepSensorDataModel                        │
│  │   ├── Objectif heures de sommeil             │
│  │   └── Préférences sommeil                     │
│  └── SleepRecordModel[] (sessions de sommeil)    │
│                                                   │
│  👥 CAPTEUR 3 : SOCIAL (À VENIR)                │
│  ├── SocialSensorDataModel                       │
│  │   ├── Objectif interactions/jour             │
│  │   └── Préférences sociales                    │
│  └── SocialInteractionModel[] (interactions)     │
│                                                   │
│  📍 CAPTEUR 4 : GPS (À VENIR)                   │
│  ├── LocationSensorDataModel                     │
│  │   ├── Objectif pas/jour                       │
│  │   ├── Objectif distance                       │
│  │   └── Préférences localisation               │
│  └── LocationRecordModel[] (activités)           │
│                                                   │
└───────────────────────────────────────────────────┘
                        ↓
                   📤 Export MCP
                        ↓
┌───────────────────────────────────────────────────┐
│              SERVEUR MCP                          │
│  Analyse croisée des données des 4 capteurs      │
└───────────────────────────────────────────────────┘
```

---

## 📊 Structure des Données

### 1. Données Centrales (Partagées)

```dart
CentralDataModel {
  id: String,
  name: String,
  email: String,
  age: int,
  gender: String,
  height: int,          // cm
  weight: int,          // kg
  profilePictureUrl: String,
  createdAt: DateTime,
  updatedAt: DateTime,
  activeSensors: List<String>,  // ['meals', 'sleep', ...]
  preferences: Map<String, dynamic>,

  // Propriétés calculées
  bmi: double,          // Calculé automatiquement
  bmiCategory: String,  // 'Normal weight', etc.
}
```

### 2. Capteur Repas

#### Configuration
```dart
MealsSensorDataModel {
  id: String,
  userId: String,       // → CentralDataModel.id
  goal: GoalType,       // maintainWeight, loseWeight, gainWeight
  targetWeight: int?,
  activityLevel: ActivityLevel,
  dailyCalorieGoal: int,  // Calculé avec Mifflin-St Jeor
  nutritionPreferences: Map<String, dynamic>,
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

#### Données collectées
```dart
MealModel {
  id: String,
  userId: String,
  name: String,
  description: String,
  calories: int,
  protein: double,      // g
  carbs: double,        // g
  fat: double,          // g
  mealType: MealType,   // breakfast, lunch, dinner, snack
  date: DateTime,
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

### 3. Capteur Sommeil

#### Configuration
```dart
SleepSensorDataModel {
  id: String,
  userId: String,
  targetSleepHours: int,  // Objectif en heures
  sleepPreferences: Map<String, dynamic>,
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

#### Données collectées
```dart
SleepRecordModel {
  id: String,
  userId: String,
  bedTime: DateTime,
  wakeTime: DateTime,
  durationMinutes: int,
  quality: SleepQuality,     // poor, fair, good, excellent
  interruptionsCount: int,
  notes: String,
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

### 4. Capteur Social

#### Configuration
```dart
SocialSensorDataModel {
  id: String,
  userId: String,
  targetInteractionsPerDay: int,
  socialPreferences: Map<String, dynamic>,
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

#### Données collectées
```dart
SocialInteractionModel {
  id: String,
  userId: String,
  type: InteractionType,  // inPerson, phoneCall, videoCall, etc.
  durationMinutes: int,
  peopleCount: int,
  sentiment: SocialSentiment,  // negative, neutral, positive, veryPositive
  description: String,
  timestamp: DateTime,
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

### 5. Capteur GPS/Localisation

#### Configuration
```dart
LocationSensorDataModel {
  id: String,
  userId: String,
  targetStepsPerDay: int,
  targetDistanceKm: double,
  locationPreferences: Map<String, dynamic>,
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

#### Données collectées
```dart
LocationRecordModel {
  id: String,
  userId: String,
  startTime: DateTime,
  endTime: DateTime,
  distanceKm: double,
  stepsCount: int,
  activityType: ActivityType,  // walking, running, cycling, etc.
  route: List<LocationPoint>,  // Points GPS
  notes: String,
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

---

## 💾 Stockage Local (Hive)

### Structure des Boxes

```
📦 Hive Storage
├── central_data (Box<CentralDataModel>)
│   └── user_data
│
├── meals_sensor (Box<MealsSensorDataModel>)
│   └── meals_config
├── meals (Box<MealModel>)
│   ├── meal_001
│   ├── meal_002
│   └── ...
│
├── sleep_sensor (Box<SleepSensorDataModel>)
│   └── sleep_config
├── sleep_records (Box<SleepRecordModel>)
│   ├── sleep_001
│   ├── sleep_002
│   └── ...
│
├── social_sensor (Box<SocialSensorDataModel>)
│   └── social_config
├── social_interactions (Box<SocialInteractionModel>)
│   ├── interaction_001
│   ├── interaction_002
│   └── ...
│
├── location_sensor (Box<LocationSensorDataModel>)
│   └── location_config
└── location_records (Box<LocationRecordModel>)
    ├── location_001
    ├── location_002
    └── ...
```

### Taille estimée

- **Données centrales** : ~2 KB
- **Capteur Repas** : ~750 KB/an (1500 repas)
- **Capteur Sommeil** : ~100 KB/an (365 nuits)
- **Capteur Social** : ~500 KB/an (1800 interactions)
- **Capteur GPS** : ~2 MB/an (avec routes GPS)

**Total estimé** : ~3.5 MB pour 1 an de données complètes

---

## 📤 Export MCP Modulaire

### Format JSON avec Métadonnées

```json
{
  "schema_version": "2.0",
  "export_metadata": {
    "timestamp": "2025-01-13T10:00:00Z",
    "app_version": "2.0.0",
    "platform": "android",
    "export_id": "exp_1705143600000"
  },

  "central_data": {
    "anonymous_id": "a3f5e7c9",
    "demographics": {
      "age": 25,
      "gender": "male",
      "height_cm": 180,
      "weight_kg": 75,
      "bmi": 23.1,
      "bmi_category": "Normal weight"
    },
    "active_sensors": ["meals", "sleep", "social", "location"],
    "account_created_at": "2025-01-01T10:00:00Z"
  },

  "sensors": [
    {
      "sensor_type": "meals",
      "status": "active",
      "config": {
        "goal": "maintainWeight",
        "activity_level": "moderatelyActive",
        "daily_calorie_goal": 2500
      },
      "data_summary": {
        "total_records": 120,
        "date_range": {
          "start": "2025-01-01",
          "end": "2025-01-13"
        },
        "total_calories": 30000,
        "avg_calories_per_day": 2308
      },
      "records": [
        {
          "id": "meal_001",
          "timestamp": "2025-01-13T08:00:00Z",
          "type": "breakfast",
          "calories": 450,
          "macros": {
            "protein_g": 25,
            "carbs_g": 50,
            "fat_g": 15
          }
        }
        // ... plus de repas
      ]
    },
    {
      "sensor_type": "sleep",
      "status": "inactive",
      "config": null,
      "data_summary": null,
      "records": []
    },
    {
      "sensor_type": "social",
      "status": "inactive",
      "config": null,
      "data_summary": null,
      "records": []
    },
    {
      "sensor_type": "location",
      "status": "inactive",
      "config": null,
      "data_summary": null,
      "records": []
    }
  ],

  "cross_sensor_insights": {
    "data_quality_score": 0.85,
    "consistency_score": 0.92,
    "days_with_all_sensors": 0,
    "days_with_partial_data": 13
  }
}
```

---

## 🎨 Interface Utilisateur

### Hub Central (Écran principal)

```
┌─────────────────────────────────────┐
│        Health Hub                   │
├─────────────────────────────────────┤
│                                     │
│  👤 Bienvenue, John                 │
│  📅 13 Janvier 2025                 │
│                                     │
│  ┌─────┐  ┌─────┐  ┌─────┐        │
│  │✅ 4  │  │📊 7  │  │📈92%│        │
│  │Actifs│  │Jours │  │Obj. │        │
│  └─────┘  └─────┘  └─────┘        │
│                                     │
│  Capteurs                           │
│  ┌─────────┐  ┌─────────┐         │
│  │🍽️ Repas │  │😴Sommeil│         │
│  │  ACTIF  │  │ Bientôt │         │
│  └─────────┘  └─────────┘         │
│  ┌─────────┐  ┌─────────┐         │
│  │👥Social │  │📍  GPS  │         │
│  │ Bientôt │  │ Bientôt │         │
│  └─────────┘  └─────────┘         │
│                                     │
│  Activité récente                   │
│  🍽️ Petit-déjeuner ajouté         │
│  😴 8h de sommeil                  │
│  👥 3 interactions                 │
│                                     │
└─────────────────────────────────────┘
```

### Navigation

```
Hub Central (CentralHubScreen)
  ├── Capteur Repas → MealsTab (existant)
  ├── Capteur Sommeil → SleepTab (à créer)
  ├── Capteur Social → SocialTab (à créer)
  └── Capteur GPS → LocationTab (à créer)
```

---

## 📁 Structure des Fichiers

```
lib/
├── data/
│   ├── models/
│   │   ├── central_data_model.dart ✅
│   │   ├── meals_sensor_data_model.dart ✅
│   │   ├── meal_model.dart (existant)
│   │   ├── sleep_sensor_data_model.dart ✅
│   │   ├── social_sensor_data_model.dart ✅
│   │   └── location_sensor_data_model.dart ✅
│   │
│   └── repository/
│       ├── central_data_repository.dart ✅
│       ├── meals_sensor_repository.dart (à créer)
│       ├── meal_repository.dart (existant, modifié)
│       ├── sleep_repository.dart (à créer)
│       ├── social_repository.dart (à créer)
│       └── location_repository.dart (à créer)
│
├── core/
│   └── services/
│       ├── local_storage_service.dart ✅ (mis à jour)
│       └── mcp_export_service.dart (à mettre à jour)
│
└── presentation/
    └── screens/
        ├── hub/
        │   └── central_hub_screen.dart ✅ (nouveau)
        ├── meals/ (existant)
        ├── sleep/ (à créer)
        ├── social/ (à créer)
        └── location/ (à créer)
```

---

## 🔄 Flux de Données

### 1. Premier lancement

```
User lance l'app pour la première fois
    ↓
Onboarding : Collecte des données centrales
    ↓
CentralDataModel créé et sauvegardé
    ↓
Sélection des capteurs à activer
    ↓
Pour chaque capteur activé :
  - Créer le SensorDataModel correspondant
  - Configurer les objectifs
  - Sauvegarder dans Hive
    ↓
Hub Central affiché
```

### 2. Ajout d'une donnée (ex: repas)

```
User clique sur "Capteur Repas"
    ↓
Affichage de l'écran Repas
    ↓
User ajoute un repas
    ↓
MealModel créé
    ↓
Sauvegarde dans meals_box
    ↓
Retour au Hub Central
    ↓
Mise à jour de l'activité récente
```

### 3. Export vers MCP

```
User clique sur "Exporter vers MCP"
    ↓
MCPExportService :
  1. Récupère CentralDataModel
  2. Récupère la liste des capteurs actifs
  3. Pour chaque capteur actif :
     - Récupère le SensorDataModel
     - Récupère tous les records
     - Calcule les statistiques
  4. Génère le JSON modulaire
  5. Anonymise les données
    ↓
Sauvegarde du fichier JSON
    ↓
Affichage du résumé à l'utilisateur
```

---

## ✅ Avantages de l'Architecture Multi-Capteurs

### 1. Modularité
- Chaque capteur est indépendant
- Activation/désactivation facile
- Ajout de nouveaux capteurs sans impacter les existants

### 2. Séparation des Données
- **Données centrales** : Partagées et réutilisables
- **Données capteurs** : Spécifiques et isolées
- Meilleure organisation du code

### 3. Scalabilité
- Ajout de capteurs futurs facilité
- Extension des capteurs existants sans migration
- Structure prête pour des dizaines de capteurs

### 4. Export MCP Flexible
- Format modulaire avec métadonnées
- Analyse cross-capteur possible
- Facile d'ajouter de nouveaux champs

### 5. Performance
- Boxes Hive séparées = accès rapide
- Pas de chargement de données inutiles
- Cache possible par capteur

---

## 🚀 Roadmap

### ✅ Phase 1 : Hub Central (FAIT)
- [x] CentralDataModel créé
- [x] 4 SensorDataModel créés
- [x] LocalStorageService mis à jour (9 boxes)
- [x] CentralHubScreen UI créé
- [x] CentralDataRepository créé

### 🔄 Phase 2 : Capteur Repas (EN COURS)
- [x] MealsSensorDataModel créé
- [ ] Adapter onboarding pour données centrales
- [ ] MealsSensorRepository créé
- [ ] Lier MealsTab au Hub

### 📅 Phase 3 : Capteurs Sommeil (À VENIR)
- [ ] UI SleepTab
- [ ] Sleep tracking features
- [ ] Sleep analytics

### 📅 Phase 4 : Capteurs Social (À VENIR)
- [ ] UI SocialTab
- [ ] Social interaction logging
- [ ] Social analytics

### 📅 Phase 5 : Capteurs GPS (À VENIR)
- [ ] UI LocationTab
- [ ] GPS tracking
- [ ] Activity detection
- [ ] Maps integration

### 📅 Phase 6 : Export MCP Modulaire
- [ ] Mettre à jour MCPExportService
- [ ] Format JSON modulaire
- [ ] Cross-sensor insights
- [ ] UI d'export améliorée

---

## 📚 Documentation Technique

### LocalStorageService

```dart
class LocalStorageService {
  // 9 Boxes Hive
  Box<CentralDataModel> centralDataBox;
  Box<MealsSensorDataModel> mealsSensorBox;
  Box<MealModel> mealsBox;
  Box<SleepSensorDataModel> sleepSensorBox;
  Box<SleepRecordModel> sleepRecordsBox;
  Box<SocialSensorDataModel> socialSensorBox;
  Box<SocialInteractionModel> socialInteractionsBox;
  Box<LocationSensorDataModel> locationSensorBox;
  Box<LocationRecordModel> locationRecordsBox;
}
```

### CentralDataRepository

```dart
class CentralDataRepository {
  Future<void> saveCentralData(CentralDataModel data);
  CentralDataModel? getCentralData();
  Future<void> updateActiveSensors(List<String> sensors);
  Future<void> activateSensor(String sensorName);
  Future<void> deactivateSensor(String sensorName);
  bool isSensorActive(String sensorName);
}
```

---

## 🎯 Conclusion

L'Architecture Multi-Capteurs transforme FitMeals en une **plateforme de santé complète** :

- 🏛️ **Hub Central** : Point d'entrée unique
- 📊 **Données structurées** : Centrales vs Capteurs
- 🔌 **Modulaire** : Ajout facile de capteurs
- 📤 **Export intelligent** : Format MCP avec métadonnées
- 🤖 **Prêt pour l'IA** : Analyse cross-capteur possible

Cette architecture garantit une **évolution facile** du projet tout en maintenant une **séparation claire des responsabilités**.
