# 🏗️ ANALYSE ARCHITECTURALE COMPLÈTE - HEALTHSYNC

## Document d'Architecture Logicielle Professionnelle
**Projet**: HealthSync (anciennement FilMeals)
**Version**: 2.0.0
**Date**: 19 Novembre 2025
**Auteur**: Analyse basée sur le cours Software Architecture

---

# TABLE DES MATIÈRES

1. [ANALYSE ARCHITECTURALE GÉNÉRALE](#1-analyse-architecturale-générale)
2. [APPLICATION DES CONCEPTS DU COURS SOFTWARE ARCHITECTURE](#2-application-des-concepts-du-cours-software-architecture)
3. [ARCHITECTURAL VIEWS (4+1)](#3-architectural-views-41)
4. [DIAGRAMMES UML](#4-diagrammes-uml)
5. [ANALYSE DE QUALITÉ](#5-analyse-de-qualité)

---

# 1️⃣ ANALYSE ARCHITECTURALE GÉNÉRALE

## 1.1 But du Système

### Vision
**HealthSync** est une plateforme mobile de collecte et d'agrégation de données de santé multi-capteurs, conçue pour faciliter l'analyse comportementale par intelligence artificielle via le protocole MCP (Model Context Protocol).

### Objectifs Principaux
1. **Collecte Multi-Capteurs**: Agréger des données hétérogènes provenant de 4 capteurs indépendants
   - 🍽️ **Capteur Repas**: Nutrition, calories, macronutriments
   - 😴 **Capteur Sommeil**: Durée, qualité, interruptions
   - 👥 **Capteur Social**: Interactions Bluetooth, contacts, durées
   - 📍 **Capteur GPS/Localisation**: Activités physiques, déplacements

2. **Stockage Local-First**: Garantir la confidentialité et le fonctionnement offline
3. **Export Structuré**: Fournir un format standardisé pour l'analyse IA (MCP)
4. **Modularité**: Permettre l'activation/désactivation indépendante de capteurs

### Utilisateurs Cibles
- **Utilisateurs finaux**: Individus souhaitant tracker leur santé globale
- **Systèmes IA externes**: Serveurs MCP pour analyse comportementale
- **Chercheurs**: Analyse de patterns de santé (export anonymisé)

---

## 1.2 Contraintes

### Contraintes Techniques
| Contrainte | Description | Impact |
|------------|-------------|--------|
| **Mobile-First** | Flutter pour iOS et Android | Architecture cross-platform |
| **Stockage Local** | Hive NoSQL embarqué | Pas de backend serveur |
| **Offline-First** | Fonctionnement sans réseau | Synchronisation différée |
| **Ressources limitées** | Batterie, GPS continu, Bluetooth | Optimisations nécessaires |
| **Permissions strictes** | Contacts, Localisation, Bluetooth | Gestion explicite du consentement |

### Contraintes Légales et Éthiques
- **RGPD/Privacy**: Données de santé sensibles, stockage local uniquement
- **Consentement explicite**: Permissions Android/iOS pour chaque capteur
- **Anonymisation**: Hash des identifiants avant export MCP
- **Transparence**: Expliquer l'usage de chaque permission

### Contraintes Architecturales
- **Séparation stricte**: Données centrales ≠ données capteurs
- **Indépendance capteurs**: Ajout/suppression sans impact sur les autres
- **Backward compatibility**: Migration depuis UserModel legacy
- **Type safety**: Hive adapters avec TypeID fixes

---

## 1.3 Enjeux

### Scalabilité
#### Scalabilité des Données
- **Volume estimé**: 3.5 MB/an pour 4 capteurs actifs
- **Croissance linéaire**: Hive supporte des millions d'enregistrements
- **Stratégie**: Compression historique après 1 an

#### Scalabilité Fonctionnelle
- **Extensibilité**: Architecture prête pour 10+ capteurs futurs
  - Capteur Activité Cardiaque (smart watch)
  - Capteur Humeur (saisie manuelle)
  - Capteur Médication (rappels)
- **Isolation**: Ajout sans modification du code existant

### Fiabilité

#### Disponibilité
- **Offline-First**: 100% disponible sans réseau
- **Pas de Single Point of Failure**: Pas de serveur central
- **Résilience**: Échecs capteurs isolés (GPS indisponible ≠ crash app)

#### Intégrité des Données
- **Transactions Hive**: ACID sur stockage local
- **Validation**: Type safety avec Dart null-safety
- **Calculs automatiques**: BMI, calories, durées (pas de saisie manuelle)

### Sécurité

#### Confidentialité
- **Stockage chiffré**: Hive encryption possible (non implémenté)
- **Pas de cloud**: Données jamais envoyées automatiquement
- **Export manuel**: Utilisateur contrôle le partage

#### Authentification
- **Non requise**: Pas de multi-utilisateurs sur un appareil
- **Device-level**: Sécurité déléguée au système d'exploitation

### Évolutivité

#### Maintenance
- **Repository Pattern**: Abstraction du stockage, migration facile
- **Service Layer**: Logique métier isolée de l'UI
- **Deprecation Strategy**: UserModel → CentralDataModel (migration progressive)

#### Innovation
- **API externes**: Spoonacular (recettes), Google Maps (visualisation)
- **MCP Protocol**: Standard émergent pour LLM context
- **Future: HealthKit/GoogleFit**: Intégration native possible

---

## 1.4 Domain Model (Concepts Importants)

### Entités Principales

```
┌─────────────────────────────────────────────────────────┐
│                    CENTRAL DATA                         │
│  - Profil utilisateur unique                            │
│  - Données physiques (height, weight, BMI)              │
│  - Liste des capteurs actifs                            │
└─────────────┬───────────────────────────────────────────┘
              │ 1:N
    ┌─────────┴───────────┬──────────────┬──────────────┐
    │                     │              │              │
┌───▼───────┐    ┌────────▼─────┐  ┌────▼──────┐  ┌────▼──────┐
│  MEALS    │    │    SLEEP     │  │  SOCIAL   │  │ LOCATION  │
│  SENSOR   │    │    SENSOR    │  │  SENSOR   │  │  SENSOR   │
│           │    │              │  │           │  │           │
│ - Config  │    │ - Config     │  │ - Config  │  │ - Config  │
│ - Goal    │    │ - Target hrs │  │ - Target  │  │ - Target  │
│ - Calories│    │              │  │   daily   │  │   steps   │
└───┬───────┘    └────┬─────────┘  └────┬──────┘  └────┬──────┘
    │ 1:N             │ 1:N             │ 1:N          │ 1:N
┌───▼──────┐    ┌─────▼────────┐  ┌────▼──────┐  ┌────▼──────┐
│  Meal    │    │ SleepRecord  │  │ Social    │  │ Location  │
│  Records │    │              │  │ Interaction│  │  Record   │
│          │    │              │  │           │  │           │
│ - Nutri  │    │ - Duration   │  │ - Contact │  │ - Route   │
│ - Type   │    │ - Quality    │  │ - MAC addr│  │ - Distance│
│ - Time   │    │ - Interrup.  │  │ - Duration│  │ - Activity│
└──────────┘    └──────────────┘  └───────────┘  └───────────┘
```

### Relations et Cardinalités

| Relation | Cardinalité | Description |
|----------|-------------|-------------|
| CentralData → SensorConfig | 1:0..1 | Un utilisateur peut activer 0 à 4 capteurs |
| SensorConfig → Records | 1:N | Une configuration génère N enregistrements |
| CentralData.userId → Record.userId | 1:N | Toutes les données liées par userId |

### Concepts Métier Clés

#### 1. **Séparation Central vs Capteur**
- **Données Centrales**: Réutilisables par tous les capteurs (âge, sexe, poids)
- **Données Capteur**: Spécifiques et isolées (repas, sommeil, etc.)

#### 2. **Activation Dynamique**
- Un capteur peut être activé/désactivé sans suppression des données
- `CentralDataModel.activeSensors: List<String>` contrôle l'état

#### 3. **Calculs Dérivés**
- **BMI**: `weight / (height/100)²`
- **Calories Goal**: Formule Mifflin-St Jeor
  ```
  Hommes: 10×poids + 6.25×taille - 5×âge + 5
  Femmes: 10×poids + 6.25×taille - 5×âge - 161
  Multiplié par facteur activité (1.2 à 1.9)
  ```
- **Durée Sommeil**: `wakeTime - bedTime`

#### 4. **Enrichissement via API**
- **Spoonacular**: Recettes et nutrition pour capteur Repas
- **Geocoding**: Conversion coordonnées → adresses pour capteur Localisation

---

# 2️⃣ APPLICATION DES CONCEPTS DU COURS SOFTWARE ARCHITECTURE

## 2.1 Architectural Styles Utilisés

### 2.1.1 **Layered Architecture (Architecture en Couches)**

HealthSync implémente une architecture en couches stricte:

```
┌──────────────────────────────────────┐  ← Couche 4
│    PRESENTATION LAYER                │    (UI Screens, Widgets)
│  - MainHubScreen, Tabs, Forms       │
└────────────┬─────────────────────────┘
             │ Dépend de ↓
┌────────────▼─────────────────────────┐  ← Couche 3
│    REPOSITORY LAYER                  │    (Data Access)
│  - CentralDataRepository             │
│  - MealRepository, etc.              │
└────────────┬─────────────────────────┘
             │ Dépend de ↓
┌────────────▼─────────────────────────┐  ← Couche 2
│    SERVICE LAYER                     │    (Business Logic)
│  - MCPExportService                  │
│  - SpoonacularService                │
│  - LocationTrackingService           │
└────────────┬─────────────────────────┘
             │ Dépend de ↓
┌────────────▼─────────────────────────┐  ← Couche 1
│    STORAGE LAYER                     │    (Persistence)
│  - LocalStorageService (Hive)       │
│  - 9 Boxes (CentralData, Meals...)  │
└──────────────────────────────────────┘
```

**Règles de dépendance**:
- Chaque couche ne peut dépendre QUE de la couche inférieure
- Pas de "skip-layer" (UI n'accède pas directement à Hive)
- Communication unidirectionnelle (pas de callbacks du Storage vers UI)

**Avantages observés**:
- ✅ Testabilité: Chaque couche mockable indépendamment
- ✅ Maintenance: Changement du storage (Hive → SQLite) sans toucher l'UI
- ✅ Réutilisabilité: Services utilisables depuis n'importe quelle UI

---

### 2.1.2 **Sense-Compute-Control (SCC)**

Architecture typique des systèmes embarqués et IoT, parfaitement adaptée aux capteurs:

```
┌──────────────────────────────────────────────────────┐
│                     SENSE                            │
│  Capteurs collectent les données brutes              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐│
│  │GPS      │  │Bluetooth│  │User     │  │API      ││
│  │Stream   │  │Scan     │  │Input    │  │Fetch    ││
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘│
└───────┼───────────┼─────────────┼──────────────┼────┘
        │           │             │              │
        └───────────┴─────────────┴──────────────┘
                        ↓
┌──────────────────────────────────────────────────────┐
│                    COMPUTE                           │
│  Traitement et enrichissement des données            │
│  ┌──────────────────────────────────────────────┐   │
│  │ - Calcul BMI (height, weight → BMI)         │   │
│  │ - Calcul Calories (Mifflin-St Jeor formula) │   │
│  │ - Détection activité (vitesse → type)       │   │
│  │ - Matching contacts (BT name → contact)     │   │
│  │ - Agrégations quotidiennes                  │   │
│  │ - Scoring adhérence aux objectifs           │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────┐
│                    CONTROL                           │
│  Actions basées sur les résultats du compute         │
│  ┌──────────────────────────────────────────────┐   │
│  │ - Sauvegarder dans Hive                      │   │
│  │ - Mettre à jour UI (streams)                 │   │
│  │ - Déclencher notifications (goal reached)    │   │
│  │ - Changer état session (pause tracking)     │   │
│  │ - Exporter vers MCP (user action)           │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

**Application par capteur**:

| Capteur | SENSE | COMPUTE | CONTROL |
|---------|-------|---------|---------|
| **Meals** | User saisit repas + API Spoonacular | Calories totales, macros, goal % | Sauvegarde, mise à jour stats |
| **Sleep** | User saisit heures | Durée (wake-bed), qualité moyenne | Sauvegarde, alerte objectif |
| **Social** | Bluetooth scan périphériques | Match contacts, validation 2min | Créer interaction si validé |
| **Location** | GPS stream positions | Distance (Haversine), vitesse, type activité | Session start/stop/save |

---

### 2.1.3 **Event-Based Architecture (via Streams)**

Flutter/Dart favorise la programmation réactive avec Streams:

```dart
// Exemple: LocationTrackingService
class LocationTrackingService {
  final _positionController = StreamController<Position>.broadcast();
  final _sessionController = StreamController<LocationRecordModel?>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;
  Stream<LocationRecordModel?> get currentSessionStream => _sessionController.stream;

  // Producteurs d'événements
  void _onGPSUpdate(Position position) {
    _positionController.add(position);  // ← EVENT: Nouvelle position
  }

  // Consommateurs d'événements (UI)
  // UI: StreamBuilder écoute currentSessionStream
}
```

**Événements clés**:
- `PositionUpdated`: GPS émet nouvelle position
- `SessionStarted`: Tracking démarre
- `SessionEnded`: Tracking termine
- `GoalReached`: Objectif quotidien atteint
- `MealAdded`: Nouveau repas enregistré

**Avantages**:
- ✅ Découplage: UI ne connaît pas la source des données
- ✅ Temps réel: Mise à jour automatique de l'UI
- ✅ Testabilité: Injection de streams mockés

---

### 2.1.4 **Client-Server (Local + Remote)**

Hybride: Pas de serveur backend, mais APIs externes:

```
┌─────────────────────────────────────┐
│     HEALTHSYNC APP (CLIENT)         │
│  ┌───────────────────────────────┐  │
│  │   Local Storage (Hive)        │  │ ← "Serveur local"
│  │   - 9 Boxes                   │  │
│  │   - CRUD operations           │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Services                    │  │
│  │   - SpoonacularService ───────┼──┼──→ API Spoonacular (HTTPS)
│  │   - MCPExportService          │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
                │
                └──→ Export manuel JSON
                     vers serveur MCP externe
```

**Caractéristiques**:
- **Local-First**: Client fonctionne totalement offline
- **Remote enrichissement**: API Spoonacular pour suggestions recettes
- **Asynchrone**: Export MCP manuel, pas de sync automatique

---

## 2.2 Architectural Patterns Employés

### 2.2.1 **Repository Pattern**

Abstraction de l'accès aux données, cache la complexité de Hive:

```dart
// Interface implicite (Dart)
abstract class Repository<T> {
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<void> save(T entity);
  Future<void> delete(String id);
}

// Implémentation concrète
class MealRepository implements Repository<MealModel> {
  final LocalStorageService _storageService;

  @override
  Future<void> save(MealModel meal) async {
    final box = _storageService.mealsBox;
    await box.put(meal.id, meal);  // Détail Hive caché
  }

  // Méthodes métier spécifiques
  Future<int> getTodayCalories(String userId) async {
    final meals = await getMealsByDate(userId, DateTime.now());
    return meals.fold(0, (sum, meal) => sum + meal.calories);
  }
}
```

**Avantages**:
- ✅ Testabilité: Mock du repository facile
- ✅ Migration: Changer Hive → SQLite sans toucher l'UI
- ✅ Logique métier: Méthodes comme `getTodayCalories()` encapsulées

**Repositories implémentés**:
- `CentralDataRepository` ✅
- `MealRepository` ✅
- `UserRepository` (legacy) ✅
- TODO: `SleepRepository`, `SocialRepository`, `LocationRepository`

---

### 2.2.2 **Service Layer Pattern**

Logique métier complexe isolée dans des services:

```dart
class MCPExportService {
  final CentralDataRepository _centralRepo;
  final MealRepository _mealRepo;

  // Logique métier: Calcul du goal adherence score
  double _calculateGoalAdherence(List<MealModel> meals, int goalCalories) {
    int daysWithinGoal = 0;
    final dailyTotals = _aggregateByDay(meals);

    for (var dayTotal in dailyTotals.values) {
      if ((dayTotal - goalCalories).abs() <= goalCalories * 0.1) {
        daysWithinGoal++;
      }
    }

    return daysWithinGoal / dailyTotals.length;
  }

  // Export orchestration
  Future<Map<String, dynamic>> exportUserData() async {
    final central = _centralRepo.getCentralData();
    final meals = await _mealRepo.getUserMeals(central.id);
    final adherence = _calculateGoalAdherence(meals, central.dailyCalorieGoal);

    return {
      'user_profile': central.toJson(),
      'meals': meals.map((m) => m.toJson()).toList(),
      'behavioral_insights': {'goal_adherence_score': adherence},
    };
  }
}
```

**Services implémentés/prévus**:
- ✅ `LocalStorageService`: Gestion Hive
- ✅ `MCPExportService`: Export et analytics
- ✅ `SpoonacularService`: API recettes
- 🔜 `LocationTrackingService`: GPS tracking
- 🔜 `BluetoothSocialService`: Détection Bluetooth
- 🔜 `PlaceManagementService`: Lieux favoris

---

### 2.2.3 **Factory Pattern (via fromJson)**

Construction d'objets complexes à partir de JSON:

```dart
class MealModel {
  final String id;
  final String name;
  final int calories;

  // Factory constructor
  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: json['calories'] as int,
      // Gestion des champs optionnels, conversion de types, etc.
    );
  }

  // Utilisé pour API Spoonacular
  factory MealModel.fromSpoonacularRecipe(Map<String, dynamic> recipe) {
    return MealModel(
      id: uuid.v4(),
      name: recipe['title'],
      calories: recipe['nutrition']['calories'].toInt(),
      // Mapping complexe API → Domain model
    );
  }
}
```

---

### 2.2.4 **Adapter Pattern (Hive TypeAdapters)**

Conversion entre objets Dart et représentation binaire Hive:

```dart
@HiveType(typeId: 5)
class CentralDataModel {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  // ...
}

// Adapter généré automatiquement par build_runner
class CentralDataModelAdapter extends TypeAdapter<CentralDataModel> {
  @override
  int get typeId => 5;

  @override
  CentralDataModel read(BinaryReader reader) {
    // Désérialisation binaire → Objet Dart
  }

  @override
  void write(BinaryWriter writer, CentralDataModel obj) {
    // Sérialisation Objet Dart → binaire
  }
}
```

**TypeIDs alloués**:
- 0-4: Legacy (UserModel, MealModel, etc.)
- 5-8: Central + Meals Sensor
- 9-11: Sleep Sensor
- 12-15: Social Sensor
- 16-19: Location Sensor
- 20-22: Nouvelles entités (Places, Stats)

---

### 2.2.5 **Observer Pattern (StreamBuilder)**

UI observe les changements de données:

```dart
class MealsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MealModel>>(
      stream: mealRepository.mealsStream,  // Observable
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final meals = snapshot.data!;
        return ListView.builder(
          itemCount: meals.length,
          itemBuilder: (context, index) => MealCard(meals[index]),
        );
      },
    );
  }
}
```

---

## 2.3 Domain-Specific Software Architecture (DSSA)

### 2.3.1 Définition du Domaine

**Domaine**: Systèmes de collecte de données de santé multi-capteurs pour analyse comportementale.

**Sous-domaines**:
- **Personal Health Tracking**: Wearables, fitness apps
- **Behavioral Analytics**: Pattern detection, habit tracking
- **IoT Sensors Aggregation**: Multi-source data fusion

---

### 2.3.2 DSSA Proposée: "Multi-Sensor Health Hub"

Architecture spécialisée pour les systèmes de santé connectée:

#### Composants Standard du DSSA

```
┌──────────────────────────────────────────────────────┐
│           CENTRAL HUB (Core Component)               │
│  - User Profile Management                           │
│  - Sensor Activation/Deactivation                    │
│  - Cross-Sensor Data Aggregation                     │
└─────────────────┬────────────────────────────────────┘
                  │
    ┌─────────────┼─────────────┬─────────────┐
    │             │             │             │
┌───▼──────┐ ┌───▼──────┐ ┌───▼──────┐ ┌───▼──────┐
│ SENSOR   │ │ SENSOR   │ │ SENSOR   │ │ SENSOR   │
│ PLUGIN   │ │ PLUGIN   │ │ PLUGIN   │ │ PLUGIN   │
│ (Meals)  │ │ (Sleep)  │ │ (Social) │ │ (GPS)    │
│          │ │          │ │          │ │          │
│ - Config │ │ - Config │ │ - Config │ │ - Config │
│ - Data   │ │ - Data   │ │ - Data   │ │ - Data   │
│ - UI Tab │ │ - UI Tab │ │ - UI Tab │ │ - UI Tab │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
                  │
    ┌─────────────┴─────────────┐
    │                           │
┌───▼────────────┐    ┌─────────▼────────┐
│ LOCAL STORAGE  │    │ EXPORT ENGINE    │
│ - Persistence  │    │ - MCP Format     │
│ - Indexing     │    │ - Anonymization  │
│ - Compression  │    │ - Analytics      │
└────────────────┘    └──────────────────┘
```

#### Règles du DSSA

1. **Isolation des Capteurs**
   - Chaque capteur = plugin indépendant
   - Interface commune: `SensorPlugin`
   ```dart
   abstract class SensorPlugin {
     String get sensorName;
     Widget get tabWidget;
     Future<void> initialize();
     Future<Map<String, dynamic>> exportData();
   }
   ```

2. **Séparation Central/Spécifique**
   - Données centrales réutilisables (démographie, physique)
   - Données capteur isolées dans boxes dédiées

3. **Format Export Standard**
   - Tous les capteurs exportent vers MCP
   - Schema version pour évolution
   - Métadonnées communes (timestamp, app_version, platform)

4. **Configuration Déclarative**
   - Chaque capteur déclare ses besoins:
     - Permissions (GPS, Bluetooth, Contacts)
     - Dépendances (APIs externes)
     - Storage boxes (Hive)
     - UI screens

---

### 2.3.3 Avantages du DSSA

| Avantage | Description |
|----------|-------------|
| **Réutilisabilité** | Sensor plugins réutilisables dans d'autres apps health |
| **Time-to-Market** | Nouveau capteur = copier template + implémenter interface |
| **Maintenance** | Bug dans capteur Meals n'affecte pas Sleep |
| **Évolutivité** | Ajout de 10+ capteurs sans refactoring |

---

## 2.4 Components (Processing, Data, Interface)

### Classification des Composants

#### 2.4.1 **Processing Components** (Calcul/Logique)

| Composant | Responsabilité | Inputs | Outputs |
|-----------|----------------|--------|---------|
| `MCPExportService` | Agrégation, analytics, export | UserData, Meals, Goals | JSON MCP |
| `LocationTrackingService` | GPS tracking, distance, activité | GPS Position stream | LocationRecord |
| `BluetoothSocialService` | Scan BT, matching contacts | BT Devices, Contacts | SocialInteraction |
| `SpoonacularService` | Enrichissement nutrition | Ingredient name | Nutrition facts |
| `Mifflin-St Jeor Calculator` | Calcul calories | Age, weight, height, sex, activity | Daily calorie goal |

#### 2.4.2 **Data Components** (Stockage/Modèles)

| Composant | Type | Persistence | Cardinalité |
|-----------|------|-------------|-------------|
| `CentralDataModel` | Entity | Hive Box (typeId 5) | 1 par utilisateur |
| `MealModel` | Entity | Hive Box (typeId 2) | N par utilisateur |
| `SleepRecordModel` | Entity | Hive Box (typeId 10) | N par utilisateur |
| `SocialInteractionModel` | Entity | Hive Box (typeId 13) | N par utilisateur |
| `LocationRecordModel` | Entity | Hive Box (typeId 17) | N par utilisateur |
| `PlaceModel` | Entity | Hive Box (typeId 21) | N par utilisateur |
| `DailyActivityStats` | Aggregate | Hive Box (typeId 22) | 1 par jour/utilisateur |

#### 2.4.3 **Interface Components** (UI)

| Composant | Type | Responsabilité |
|-----------|------|----------------|
| `MainHubScreen` | Container | Navigation 5 tabs, PageView |
| `CentralHubScreen` | Dashboard | Overview tous capteurs |
| `HomeTab` | Dashboard | Stats globales jour |
| `MealsTab` | Feature Screen | Calories, macros, liste repas |
| `SleepTab` | Feature Screen | Durée, qualité sommeil |
| `SocialTab` | Feature Screen | Interactions, contacts |
| `LocationTab` | Feature Screen | Activités, carte, sessions |
| `CentralOnboardingScreen` | Wizard | Collecte données initiales |

---

## 2.5 Connectors (Communication entre Composants)

### Types de Connecteurs du Cours

#### 2.5.1 **Procedure Call** (Appels de Méthodes)

Connecteur le plus courant en Dart:

```dart
// UI → Repository
final meals = await mealRepository.getUserMeals(userId);

// Repository → Service
final box = localStorageService.mealsBox;

// Service → API externe
final recipes = await spoonacularService.searchRecipes(query);
```

**Caractéristiques**:
- Synchrone ou asynchrone (Future)
- Type-safe (Dart)
- Bloquant ou non-bloquant (async/await)

---

#### 2.5.2 **Message Passing** (Streams)

Communication asynchrone entre composants:

```dart
// Producer
class LocationTrackingService {
  final _controller = StreamController<Position>.broadcast();

  void _onGPSUpdate(Position pos) {
    _controller.add(pos);  // Envoie message
  }
}

// Consumer
locationService.positionStream.listen((position) {
  print('New position: ${position.latitude}, ${position.longitude}');
});
```

**Avantages**:
- Découplage: Producer ne connaît pas les consumers
- N consumers possibles (broadcast stream)
- Temps réel

---

#### 2.5.3 **Streaming** (GPS, Bluetooth)

Flux continu de données depuis capteurs:

```dart
// GPS Stream
Stream<Position> positionStream = Geolocator.getPositionStream(
  locationSettings: LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,  // Nouveaux points tous les 5m
  ),
);

// Bluetooth Scan Stream
Stream<BluetoothDiscoveryResult> scanStream =
  FlutterBluetoothSerial.instance.startDiscovery();
```

**Caractéristiques**:
- Infini (jusqu'à stopTracking)
- Backpressure possible (buffer)
- Filtres applicables (distanceFilter)

---

#### 2.5.4 **Shared Memory** (Hive Boxes)

Composants partagent des données via stockage commun:

```dart
// Writer
await centralDataBox.put('user', userData);

// Reader (autre composant)
final userData = centralDataBox.get('user');
```

**Caractéristiques**:
- Accès concurrent géré par Hive
- Transactions ACID
- Pas de messages explicites

---

#### 2.5.5 **Wrappers/Adapters** (APIs Externes)

Encapsulation d'APIs tierces:

```dart
class SpoonacularService {
  final String _apiKey = '2e3642e419ea4ffd8b9f8095ae3c82f2';
  final String _baseUrl = 'https://api.spoonacular.com';

  // Wrapper autour de http.get
  Future<List<Recipe>> searchRecipes(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/recipes/complexSearch?query=$query&apiKey=$_apiKey'),
    );

    // Adaptation JSON → Domain model
    final data = jsonDecode(response.body);
    return (data['results'] as List)
        .map((json) => Recipe.fromJson(json))
        .toList();
  }
}
```

**Avantages**:
- Isolation: Changement API Spoonacular n'affecte que le wrapper
- Testabilité: Mock du service facile
- Type conversion: JSON → Dart objects

---

### Matrice Connecteurs × Composants

| Source | Destination | Connecteur | Exemple |
|--------|-------------|------------|---------|
| UI | Repository | Procedure Call | `mealRepo.addMeal(meal)` |
| Repository | Hive Box | Shared Memory | `box.put(id, meal)` |
| GPS | LocationService | Streaming | `Geolocator.getPositionStream()` |
| LocationService | UI | Message Passing | `positionStream.listen()` |
| UI | SpoonacularAPI | Wrapper | `spoonacularService.search()` |
| MCPExport | Repositories | Procedure Call | `mealRepo.getUserMeals()` |

---

# 3️⃣ ARCHITECTURAL VIEWS (4+1)

## 3.1 Logical View (Vue Logique)

### Packages et Modules

```
lib/
├── core/                          [CORE MODULE]
│   ├── services/
│   │   ├── local_storage_service.dart      (Hive initialization)
│   │   ├── mcp_export_service.dart         (Export logic)
│   │   ├── spoonacular_service.dart        (External API)
│   │   ├── location_tracking_service.dart  (GPS tracking)
│   │   ├── bluetooth_social_service.dart   (BT scan)
│   │   └── place_management_service.dart   (Places CRUD)
│   └── theme/
│       └── app_theme.dart                  (UI theming)
│
├── data/                          [DATA MODULE]
│   ├── models/                    (Domain entities)
│   │   ├── central_data_model.dart         (TypeId: 5)
│   │   ├── meals_sensor_data_model.dart    (TypeId: 6)
│   │   ├── meal_model.dart                 (TypeId: 2)
│   │   ├── sleep_sensor_data_model.dart    (TypeId: 9)
│   │   ├── sleep_record_model.dart         (TypeId: 10)
│   │   ├── social_sensor_data_model.dart   (TypeId: 12)
│   │   ├── social_interaction_model.dart   (TypeId: 13)
│   │   ├── location_sensor_data_model.dart (TypeId: 16)
│   │   ├── location_record_model.dart      (TypeId: 17)
│   │   ├── location_point.dart             (TypeId: 18)
│   │   └── place_model.dart                (TypeId: 21)
│   │
│   └── repository/                (Data access layer)
│       ├── central_data_repository.dart
│       ├── meal_repository.dart
│       ├── sleep_repository.dart           (TODO)
│       ├── social_repository.dart          (TODO)
│       └── location_repository.dart        (TODO)
│
└── presentation/                  [UI MODULE]
    └── screens/
        ├── hub/
        │   ├── main_hub_screen.dart        (5-tab navigation)
        │   ├── central_hub_screen.dart     (Overview)
        │   └── tabs/
        │       ├── home_tab.dart
        │       ├── meals_tab.dart
        │       ├── sleep_tab.dart
        │       ├── social_tab.dart
        │       └── location_tab.dart
        │
        ├── onboarding/
        │   ├── welcome_screen.dart
        │   └── central_onboarding_screen.dart
        │
        ├── meals/
        │   └── (meal detail screens)
        │
        ├── sleep/
        │   └── (sleep tracking screens - TODO)
        │
        ├── social/
        │   └── (social interaction screens - TODO)
        │
        └── location/
            └── (GPS tracking screens - TODO)
```

### Diagramme de Classes Simplifié

```
┌─────────────────────────────────┐
│   CentralDataModel              │
│  ─────────────────────────────  │
│  + id: String                   │
│  + name: String                 │
│  + age: int                     │
│  + height: int                  │
│  + weight: int                  │
│  + activeSensors: List<String>  │
│  ─────────────────────────────  │
│  + bmi: double                  │
│  + bmiCategory: String          │
│  + copyWith()                   │
└────────────┬────────────────────┘
             │ 1
             │ userId
             │
    ┌────────┼────────┬────────┬────────┐
    │        │        │        │        │
    │ 0..1   │ 0..1   │ 0..1   │ 0..1   │
┌───▼────┐ ┌─▼──────┐ ┌▼──────┐ ┌▼──────┐
│ Meals  │ │ Sleep  │ │Social │ │Locatio│
│ Sensor │ │ Sensor │ │Sensor │ │nSensor│
│ Data   │ │ Data   │ │Data   │ │Data   │
└───┬────┘ └─┬──────┘ └┬──────┘ └┬──────┘
    │ 1      │ 1       │ 1       │ 1
    │ N      │ N       │ N       │ N
┌───▼────┐ ┌─▼──────┐ ┌▼──────┐ ┌▼──────┐
│ Meal   │ │ Sleep  │ │Social │ │Locatio│
│ Model  │ │ Record │ │Interac│ │nRecord│
│        │ │ Model  │ │tion   │ │       │
└────────┘ └────────┘ └───────┘ └───────┘
```

---

## 3.2 Process View (Vue Processus)

### Threads et Exécution

#### Thread Principal (UI Thread)
```
┌───────────────────────────────────────────┐
│         MAIN THREAD (Flutter)             │
│  - Rendering (60 FPS)                     │
│  - Event handling (taps, gestures)        │
│  - Widget rebuilds                        │
│  - StreamBuilder updates                  │
└────────────┬──────────────────────────────┘
             │ async/await
             ▼
┌───────────────────────────────────────────┐
│      ISOLATE / COMPUTE THREADS            │
│  - Hive read/write (async)                │
│  - JSON parsing (compute)                 │
│  - Distance calculation (compute)         │
│  - Export generation (isolate)            │
└───────────────────────────────────────────┘
```

#### Flux de Traitement: Ajout Repas

```
[User Tap "Add Meal"]
        ↓
  [UI Thread]
        ↓ Future
  [Validation Input]
        ↓
  [Create MealModel]
        ↓ async
  [MealRepository.addMeal()]
        ↓ Background I/O
  [Hive Box Write]
        ↓ await completion
  [Update Stream]
        ↓
  [StreamBuilder Rebuild]
        ↓
  [UI Shows New Meal]

Temps total: ~50-100ms
```

#### Flux de Traitement: GPS Tracking

```
[User Start Tracking]
        ↓
  [LocationTrackingService.startTracking()]
        ↓ Subscribe to stream
  [Geolocator.getPositionStream()]
        │
        │ ┌─────────────────────────────┐
        │ │  GPS THREAD (Native)        │
        │ │  - Position updates every 5s│
        ▼ └─────────────────────────────┘
  [Stream Callback]
        ↓ Every 5 seconds
  [Add LocationPoint to Route]
        ↓
  [Calculate Distance (compute)]
        ↓
  [Detect Activity (compute)]
        ↓ If changed
  [Save Session (async Hive)]
        ↓
  [Emit Stream Event]
        ↓
  [UI Updates]

Continuous process, runs until stopTracking()
```

### Diagramme de Flux MCP Export

```
┌──────────────────────────────────────────────────────┐
│                USER THREAD                           │
│                                                      │
│  [User Tap Export Button]                           │
│          ↓                                           │
│  [MCPExportService.exportUserData()]                 │
│          ↓                                           │
│  ┌─────────────────────────────────────────────┐    │
│  │   COMPUTE ISOLATE                          │    │
│  │                                             │    │
│  │   1. Fetch CentralData (Hive)              │    │
│  │   2. Fetch All Meals (Hive)                │    │
│  │   3. Calculate Daily Aggregates (compute)  │    │
│  │   4. Calculate Goal Adherence (compute)    │    │
│  │   5. Analyze Patterns (compute)            │    │
│  │   6. Generate JSON                         │    │
│  │   7. Anonymize IDs (hash)                  │    │
│  │                                             │    │
│  │   Durée: ~500ms pour 1000 repas            │    │
│  └────────────────┬────────────────────────────┘    │
│                   ↓ Return JSON                     │
│  [Save to File (path_provider)]                     │
│          ↓                                           │
│  [Show Success Dialog with path]                    │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 3.3 Development View (Vue Développement)

### Structure des Packages

```
healthsync/
├── android/                    # Configuration Android
│   └── app/
│       └── src/main/
│           └── AndroidManifest.xml  (permissions)
│
├── ios/                        # Configuration iOS
│   └── Runner/
│       └── Info.plist          (permissions)
│
├── lib/
│   ├── main.dart               # Entry point
│   ├── core/                   # Package core
│   ├── data/                   # Package data
│   └── presentation/           # Package UI
│
├── test/                       # Tests unitaires
│   └── widget_test.dart
│
├── pubspec.yaml                # Dependencies
├── analysis_options.yaml       # Linting rules
└── README.md
```

### Dépendances (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1

  # UI
  google_fonts: ^6.2.1
  cupertino_icons: ^1.0.8

  # Utils
  uuid: ^4.5.1
  intl: ^0.19.0

  # APIs
  http: ^1.2.0

  # GPS (à ajouter)
  geolocator: ^10.1.0
  geocoding: ^2.1.1

  # Bluetooth (à ajouter)
  flutter_bluetooth_serial: ^0.4.0
  flutter_contacts: ^1.1.7+1

  # Permissions
  permission_handler: ^11.0.1

dev_dependencies:
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  flutter_lints: ^5.0.0
```

### Build Process

```
1. Code Generation
   $ flutter pub run build_runner build
   → Génère Hive TypeAdapters (.g.dart files)

2. Compilation
   $ flutter build apk --release     (Android)
   $ flutter build ios --release     (iOS)

3. Testing
   $ flutter test                    (Unit tests)
   $ flutter test integration_test   (Integration)

4. Linting
   $ flutter analyze
   → Vérifie conformité à flutter_lints
```

---

## 3.4 Physical / Deployment View (Vue Déploiement)

### Architecture de Déploiement

```
┌─────────────────────────────────────────────────────────┐
│              USER DEVICE (Android/iOS)                  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │          HEALTHSYNC APP (Flutter)                 │ │
│  │  ┌─────────────────────────────────────────────┐  │ │
│  │  │  UI Layer (Widgets)                         │  │ │
│  │  └──────────────┬──────────────────────────────┘  │ │
│  │                 │                                  │ │
│  │  ┌──────────────▼──────────────────────────────┐  │ │
│  │  │  Business Layer (Services, Repositories)    │  │ │
│  │  └──────────────┬──────────────────────────────┘  │ │
│  │                 │                                  │ │
│  │  ┌──────────────▼──────────────────────────────┐  │ │
│  │  │  Data Layer (Hive - Local Storage)          │  │ │
│  │  │  • central_data.hive                        │  │ │
│  │  │  • meals.hive                               │  │ │
│  │  │  • sleep_records.hive                       │  │ │
│  │  │  • social_interactions.hive                 │  │ │
│  │  │  • location_records.hive                    │  │ │
│  │  │  Location: /data/data/com.app/files/        │  │ │
│  │  └──────────────┬──────────────────────────────┘  │ │
│  └─────────────────┼──────────────────────────────────┘ │
│                    │                                    │
│  ┌─────────────────▼──────────────────────────────┐    │
│  │       DEVICE SENSORS                           │    │
│  │  • GPS Module (Location Tracking)              │    │
│  │  • Bluetooth Adapter (Social Tracking)         │    │
│  │  • Contact Database (Matching)                 │    │
│  └────────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTPS
                      │
         ┌────────────┴────────────┐
         │                         │
         ▼                         ▼
┌─────────────────┐      ┌─────────────────┐
│  SPOONACULAR    │      │  MCP SERVER     │
│  API            │      │  (External)     │
│  (Cloud)        │      │                 │
│  • Recipes      │      │  • Analysis     │
│  • Nutrition    │      │  • Insights     │
└─────────────────┘      └─────────────────┘
      Remote                   Remote
      Always On                On-Demand
```

### Composants Déployés

| Composant | Emplacement | Type | Persistance |
|-----------|-------------|------|-------------|
| **Flutter App** | Device | Mobile App | Non |
| **Hive Boxes** | `/data/data/com.healthsync.app/files/` | Files (.hive) | Oui |
| **MCP Export JSON** | `Downloads/` ou `Documents/` | File (.json) | Temporaire |
| **Spoonacular API** | Cloud (api.spoonacular.com) | REST API | N/A |
| **MCP Server** | External (user-managed) | LLM Server | N/A |

### Volumes de Données

| Box Hive | Taille/Record | Records/An | Total/An |
|----------|---------------|------------|----------|
| `central_data` | 500 bytes | 1 | 500 B |
| `meals_sensor` | 300 bytes | 1 | 300 B |
| `meals` | 500 bytes | 1500 | 750 KB |
| `sleep_records` | 300 bytes | 365 | 110 KB |
| `social_interactions` | 400 bytes | 1800 | 720 KB |
| `location_records` | 2 KB (avec route) | 365 | 730 KB |
| **TOTAL** | | | **~3.5 MB/an** |

---

## 3.5 Scenarios (Use Cases)

### Scénario 1: Configuration Initiale

**Acteurs**: Utilisateur, Système

**Séquence**:
```
1. User lance l'app pour la première fois
2. System détecte absence de CentralDataModel
3. System affiche CentralOnboardingScreen
4. User remplit formulaire (nom, email, âge, sexe, height, weight)
5. System valide inputs
6. System calcule BMI automatiquement
7. System crée CentralDataModel
8. System sauve dans central_data box (Hive)
9. System initialise activeSensors = ['meals']
10. System crée MealsSensorDataModel avec objectif par défaut
11. System calcule dailyCalorieGoal (Mifflin-St Jeor)
12. System sauve dans meals_sensor box
13. System navigue vers MainHubScreen
14. User voit CentralHubScreen avec capteur Meals actif
```

**Postconditions**:
- CentralDataModel existant dans Hive
- MealsSensorDataModel configuré
- UI affiche hub principal

---

### Scénario 2: Ajout d'un Repas

**Acteurs**: Utilisateur, MealRepository, SpoonacularService

**Séquence**:
```
1. User navigue vers MealsTab
2. User clique bouton "+"
3. System affiche formulaire (nom, calories, macros)
4. User cherche recette "Chicken Salad" via search
5. System appelle SpoonacularService.searchRecipes("Chicken Salad")
6. SpoonacularService envoie requête HTTPS vers API
7. API retourne liste de recettes avec nutrition
8. System affiche résultats dans autocomplete
9. User sélectionne "Grilled Chicken Caesar Salad"
10. System pré-remplit formulaire avec nutrition API
11. User ajuste si nécessaire et clique "Save"
12. System crée MealModel avec uuid
13. System appelle MealRepository.addMeal(meal)
14. Repository sauve dans meals box (Hive)
15. Repository calcule nouvelles stats quotidiennes
16. Repository émet événement via stream
17. System met à jour MealsTab (StreamBuilder)
18. User voit nouveau repas dans la liste
19. System vérifie si goal quotidien atteint
20. Si oui, System affiche notification encourageante
```

**Postconditions**:
- Nouveau MealModel dans Hive
- Calories totales jour mises à jour
- UI rafraîchie

---

### Scénario 3: Tracking GPS Session

**Acteurs**: Utilisateur, LocationTrackingService, GPS

**Séquence**:
```
1. User navigue vers LocationTab
2. User clique "Start Tracking"
3. System demande permission ACCESS_FINE_LOCATION
4. User accorde permission
5. System appelle LocationTrackingService.startTracking()
6. Service initialise liste de LocationPoints vide
7. Service subscribe à Geolocator.getPositionStream()
8. GPS démarre et émet Position toutes les 5 secondes
9. Service reçoit Position #1 (départ)
   - Crée LocationRecordModel (startTime = now, activityType = stationary)
   - Sauve session dans location_records box
10. Service reçoit Position #2, #3... (toutes les 5s)
   - Pour chaque position:
     a. Ajoute LocationPoint à route
     b. Calcule distance avec Haversine
     c. Accumule dans distanceKm
11. Après 30 points (2.5 minutes), Service calcule vitesse moyenne
   - avgSpeed = 8.5 km/h
   - Classification: activityType = running
12. Service met à jour LocationRecordModel
13. Service émet événement via currentSessionStream
14. UI (TrackingScreen) reçoit event et affiche:
   - Distance: 2.5 km
   - Durée: 12:34
   - Vitesse: 8.5 km/h
   - Type: Running
15. Service détecte proximité avec PlaceModel "Parc Central"
16. Service associe placeId à session
17. [Boucle continue jusqu'à stop...]
18. User clique "Stop"
19. Service appelle stopTracking()
   - Finalise session (endTime = now)
   - Calcule durée totale
   - Sauvegarde définitive dans Hive
20. Service met à jour DailyActivityStats
   - runningSeconds += durationSeconds
   - totalDistanceKm += distanceKm
21. System navigue vers SessionDetailsScreen
22. User voit carte avec route complète
```

**Postconditions**:
- LocationRecordModel complet dans Hive
- DailyActivityStats mis à jour
- GPS arrêté (économie batterie)

---

### Scénario 4: Export MCP Complet

**Acteurs**: Utilisateur, MCPExportService, Repositories

**Séquence**:
```
1. User navigue vers Settings/Profile
2. User clique "Export to MCP"
3. System affiche dialogue de confirmation
4. User confirme
5. System appelle MCPExportService.exportUserData()
6. Service récupère CentralDataModel
   - Anonymise: id → hash(id)
7. Service récupère activeSensors list
8. Pour chaque capteur actif:

   == MEALS SENSOR ==
   a. Récupère MealsSensorDataModel
   b. Récupère tous MealModel (last 30 days)
   c. Calcule daily aggregates (calories/jour)
   d. Calcule goal adherence score
   e. Détecte meal timing patterns
   f. Génère section "meals" du JSON

   == SLEEP SENSOR ==
   g. Récupère SleepSensorDataModel
   h. Récupère tous SleepRecordModel (last 30 days)
   i. Calcule durée moyenne, qualité moyenne
   j. Génère section "sleep" du JSON

   == SOCIAL SENSOR ==
   k. Récupère SocialSensorDataModel
   l. Récupère tous SocialInteractionModel
   m. Anonymise MAC addresses
   n. Calcule fréquence interactions
   o. Génère section "social" du JSON

   == LOCATION SENSOR ==
   p. Récupère LocationSensorDataModel
   q. Récupère tous LocationRecordModel
   r. Agrège par type d'activité
   s. Anonymise coordonnées GPS (arrondi 2 décimales)
   t. Génère section "location" du JSON

9. Service calcule cross-sensor insights
   - Corrélation calories vs activité physique
   - Impact sommeil sur activité
   - Cohérence temporelle (repas vs exercise)
10. Service génère JSON final avec metadata:
   - schema_version: "2.0"
   - export_timestamp
   - app_version
11. Service sauve JSON vers fichier
   - Path: Downloads/mcp_export_2025_11_19.json
12. System affiche dialogue succès avec path
13. User clique "Share"
14. System ouvre système de partage natif
15. User sélectionne destination (email, cloud, etc.)
```

**Postconditions**:
- Fichier JSON créé dans Downloads
- Données anonymisées
- Prêt pour import dans MCP server

---

# 4️⃣ DIAGRAMMES UML

## 4.1 Diagramme de Composants

```plantuml
@startuml HealthSync_Components

!define RECTANGLE class

skinparam componentStyle rectangle
skinparam backgroundColor #FEFEFE
skinparam component {
    BackgroundColor<<central>> #FFE6CC
    BackgroundColor<<sensor>> #D5E8D4
    BackgroundColor<<service>> #DAE8FC
    BackgroundColor<<storage>> #F8CECC
    BackgroundColor<<external>> #E1D5E7
    BorderColor #333333
    FontSize 11
}

package "PRESENTATION LAYER" {
    [MainHubScreen] <<central>>
    [CentralHubScreen] <<central>>
    [HomeTab] <<central>>
    [MealsTab] <<sensor>>
    [SleepTab] <<sensor>>
    [SocialTab] <<sensor>>
    [LocationTab] <<sensor>>
}

package "REPOSITORY LAYER" {
    [CentralDataRepository] <<central>>
    [MealRepository] <<sensor>>
    [SleepRepository] <<sensor>>
    [SocialRepository] <<sensor>>
    [LocationRepository] <<sensor>>
}

package "SERVICE LAYER" {
    [LocalStorageService] <<storage>>
    [MCPExportService] <<service>>
    [SpoonacularService] <<external>>
    [LocationTrackingService] <<service>>
    [BluetoothSocialService] <<service>>
    [PlaceManagementService] <<service>>
}

package "DATA LAYER" {
    database "Hive Storage" {
        [central_data.hive] <<storage>>
        [meals.hive] <<storage>>
        [sleep_records.hive] <<storage>>
        [social_interactions.hive] <<storage>>
        [location_records.hive] <<storage>>
    }
}

package "EXTERNAL SYSTEMS" {
    cloud "Spoonacular API" as SpoonAPI <<external>>
    cloud "MCP Server" as MCPServer <<external>>
    component "Device GPS" as GPS <<external>>
    component "Device Bluetooth" as BT <<external>>
}

' Connections Presentation → Repository
MainHubScreen --> CentralHubScreen
MainHubScreen --> HomeTab
MainHubScreen --> MealsTab
MainHubScreen --> SleepTab
MainHubScreen --> SocialTab
MainHubScreen --> LocationTab

MealsTab --> MealRepository
SleepTab --> SleepRepository
SocialTab --> SocialRepository
LocationTab --> LocationRepository
CentralHubScreen --> CentralDataRepository

' Connections Repository → Service
CentralDataRepository --> LocalStorageService
MealRepository --> LocalStorageService
MealRepository --> SpoonacularService
SleepRepository --> LocalStorageService
SocialRepository --> LocalStorageService
SocialRepository --> BluetoothSocialService
LocationRepository --> LocalStorageService
LocationRepository --> LocationTrackingService

' Connections Service → Service
MCPExportService --> CentralDataRepository
MCPExportService --> MealRepository
MCPExportService --> SleepRepository
MCPExportService --> SocialRepository
MCPExportService --> LocationRepository

LocationTrackingService --> PlaceManagementService
PlaceManagementService --> LocationRepository

' Connections Service → Storage
LocalStorageService --> [central_data.hive]
LocalStorageService --> [meals.hive]
LocalStorageService --> [sleep_records.hive]
LocalStorageService --> [social_interactions.hive]
LocalStorageService --> [location_records.hive]

' Connections Service → External
SpoonacularService --> SpoonAPI : HTTPS
MCPExportService ..> MCPServer : export JSON
LocationTrackingService --> GPS : Position Stream
BluetoothSocialService --> BT : Scan Stream

note right of [MainHubScreen]
  Entry point
  5-tab navigation
end note

note right of [MCPExportService]
  Orchestrates export
  of all sensors
end note

note bottom of "Hive Storage"
  Local NoSQL
  9 boxes total
  ~3.5 MB/year
end note

@enduml
```

---

## 4.2 Diagramme de Séquence: Ajout d'un Repas

```plantuml
@startuml Add_Meal_Sequence

actor User
participant "MealsTab\n(UI)" as UI
participant "SpoonacularService" as Spoon
participant "MealRepository" as Repo
participant "LocalStorageService" as Storage
participant "Hive Box\n(meals)" as Hive
participant "StreamController" as Stream

User -> UI : Tap "Add Meal"
activate UI

UI -> UI : Show AddMealForm
User -> UI : Search "Chicken Salad"

UI -> Spoon : searchRecipes("Chicken Salad")
activate Spoon
Spoon -> Spoon : Build HTTPS request\n+ API key
Spoon --> : HTTP GET to\napi.spoonacular.com
... API call ~200ms ...
<-- Spoon : JSON recipes list
Spoon -> Spoon : Parse JSON\n→ List<Recipe>
Spoon --> UI : Return recipes
deactivate Spoon

UI -> UI : Display autocomplete\nwith nutrition

User -> UI : Select recipe\n"Grilled Chicken Caesar"
UI -> UI : Pre-fill form\n(name, calories, macros)

User -> UI : Adjust & Tap "Save"
UI -> UI : Validate inputs

UI -> UI : Create MealModel\n(id=uuid, userId=...)

UI -> Repo : addMeal(meal)
activate Repo

Repo -> Storage : Get meals box
activate Storage
Storage --> Repo : Box<MealModel>
deactivate Storage

Repo -> Hive : box.put(meal.id, meal)
activate Hive
Hive -> Hive : Serialize with\nTypeAdapter
Hive -> Hive : Write to disk
Hive --> Repo : Future<void> completes
deactivate Hive

Repo -> Repo : Calculate today's\ntotal calories

Repo -> Stream : _mealsController.add(meal)
activate Stream
Stream --> UI : StreamBuilder receives event
deactivate Stream

Repo --> UI : Future<void> completes
deactivate Repo

UI -> UI : Rebuild MealsList widget
UI -> UI : Show SnackBar\n"Meal added!"
UI --> User : Display updated list

deactivate UI

note over UI, Hive
  Total duration: ~300ms
  - API call: ~200ms
  - Hive write: ~50ms
  - UI rebuild: ~16ms (1 frame)
end note

@enduml
```

---

## 4.3 Diagramme de Séquence: GPS Tracking Session

```plantuml
@startuml GPS_Tracking_Sequence

actor User
participant "LocationTab\n(UI)" as UI
participant "LocationTrackingService" as Service
participant "Geolocator\n(GPS)" as GPS
participant "LocationRepository" as Repo
participant "PlaceManagementService" as PlaceService
participant "Hive Box\n(location_records)" as Hive

User -> UI : Tap "Start Tracking"
activate UI

UI -> UI : Check permissions
alt Permission Granted
    UI -> Service : startTracking()
    activate Service

    Service -> Service : Initialize empty route:\nList<LocationPoint>()
    Service -> Service : Create LocationRecordModel\n(startTime=now)

    Service -> GPS : getPositionStream(\naccuracy: high,\ndistanceFilter: 5m)
    activate GPS
    GPS --> Service : Stream<Position>

    Service -> UI : Emit "Tracking Started" event
    UI -> UI : Navigate to TrackingScreen
    deactivate UI

    loop Every 5 seconds
        GPS -> Service : emit Position\n(lat, lon, timestamp)

        Service -> Service : Create LocationPoint\n(lat, lon, timestamp)
        Service -> Service : Append to route list

        Service -> Service : Calculate distance\n(Haversine formula)
        Service -> Service : Update distanceKm

        alt Every 30 points (2.5 minutes)
            Service -> Service : Calculate avg speed\nfrom last 30 points
            Service -> Service : Classify activity:\nif speed < 1: stationary\nif speed < 6: walking\nif speed < 12: running

            alt Activity changed
                Service -> Repo : Save current session
                activate Repo
                Repo -> Hive : put(session.id, session)
                Hive --> Repo : Future<void>
                deactivate Repo

                Service -> Service : Create new session\nwith new activityType
            end
        end

        Service -> PlaceService : findNearbyPlace(position)
        activate PlaceService
        PlaceService -> PlaceService : Check distance to\nall saved places
        alt Within radius
            PlaceService --> Service : PlaceModel
            Service -> Service : Associate place to session\n(placeId, placeName)
        end
        deactivate PlaceService

        Service -> Service : Emit currentSessionStream\nevent
        note right: UI updates in real-time\nvia StreamBuilder
    end

    ... User continues activity 12:34 ...

    User -> UI : Tap "Stop Tracking"
    activate UI

    UI -> Service : stopTracking()
    Service -> GPS : Cancel stream subscription
    deactivate GPS

    Service -> Service : Finalize session:\nendTime = now\ncalculate durationSeconds

    Service -> Repo : saveLocationRecord(session)
    activate Repo
    Repo -> Hive : put(session.id, session)
    Hive --> Repo : Future<void>

    Repo -> Repo : Update DailyActivityStats:\nrunningSeconds += duration\ntotalDistanceKm += distance
    Repo -> Hive : put(stats.id, stats)
    Hive --> Repo : Future<void>
    deactivate Repo

    Service --> UI : Future<void> completes
    deactivate Service

    UI -> UI : Navigate to\nSessionDetailsScreen
    UI --> User : Display session summary\nwith map
    deactivate UI

else Permission Denied
    UI -> UI : Show permission\nrationale dialog
    UI --> User : "GPS required for tracking"
end

note over Service, Hive
  Continuous process
  Duration: Variable (user-controlled)
  GPS updates: ~5s interval
  Distance filter: 5 meters
end note

@enduml
```

---

## 4.4 Diagramme de Déploiement

```plantuml
@startuml Deployment_Diagram

skinparam backgroundColor #FEFEFE
skinparam node {
    BackgroundColor #E1F5FE
    BorderColor #01579B
    FontSize 11
}
skinparam component {
    BackgroundColor #FFF9C4
    BorderColor #F57F17
}
skinparam database {
    BackgroundColor #F8BBD0
    BorderColor #880E4F
}
skinparam cloud {
    BackgroundColor #E8EAF6
    BorderColor #283593
}

node "User Device\n(Android/iOS Smartphone)" as Device {

    component "Flutter Runtime\n(Dart VM)" as Flutter {

        artifact "healthsync.apk/.ipa\n(~50 MB)" as App

        package "App Components" {
            component "UI Layer\n(Widgets)" as UILayer
            component "Business Layer\n(Services, Repos)" as BizLayer
            component "Data Layer\n(Hive)" as DataLayer
        }
    }

    database "Local Storage\n/data/data/com.healthsync/" as Storage {
        file "central_data.hive\n(~1 KB)" as CentralDB
        file "meals.hive\n(~750 KB/year)" as MealsDB
        file "sleep_records.hive\n(~100 KB/year)" as SleepDB
        file "social_interactions.hive\n(~500 KB/year)" as SocialDB
        file "location_records.hive\n(~2 MB/year)" as LocationDB
    }

    node "Device Sensors" as Sensors {
        component "GPS Module" as GPS
        component "Bluetooth Adapter" as BT
        component "Contact Database" as Contacts
    }

    folder "Downloads/Documents" as Downloads {
        file "mcp_export_2025_11_19.json\n(~5 MB)" as ExportFile
    }
}

cloud "Spoonacular API\napi.spoonacular.com" as SpoonAPI {
    component "Recipe Search\nEndpoint" as RecipeAPI
    component "Nutrition Info\nEndpoint" as NutritionAPI
}

cloud "External MCP Server\n(User-Managed)" as MCPServer {
    component "LLM Context\nProcessor" as LLMProcessor
    component "Behavioral\nAnalysis Engine" as AnalysisEngine
}

' Connections
App --> UILayer
UILayer --> BizLayer
BizLayer --> DataLayer

DataLayer --> CentralDB
DataLayer --> MealsDB
DataLayer --> SleepDB
DataLayer --> SocialDB
DataLayer --> LocationDB

BizLayer --> GPS : Position\nStream
BizLayer --> BT : Scan\nStream
BizLayer --> Contacts : Read\nContacts

BizLayer --> RecipeAPI : HTTPS\nGET /recipes
BizLayer --> NutritionAPI : HTTPS\nGET /nutrition

BizLayer ..> ExportFile : Generate\nJSON

User -> ExportFile : Manual\nTransfer
ExportFile ..> LLMProcessor : Upload\n(manual)
LLMProcessor --> AnalysisEngine : Process

note right of Device
  OS: Android 10+ / iOS 14+
  RAM: 2 GB minimum
  Storage: 100 MB app + 10 MB data
  Network: WiFi/4G (optional)
end note

note right of Storage
  Format: Hive binary
  Encryption: Not implemented
  Backup: Device-level only
  Retention: Unlimited
end note

note bottom of SpoonAPI
  Protocol: HTTPS/REST
  Auth: API Key in URL
  Rate Limit: 150 calls/day (free tier)
  Latency: ~200ms
end note

note bottom of MCPServer
  Deployment: User's choice
  Options: Local, Cloud, Self-hosted
  Protocol: Custom (JSON file input)
  No automatic sync
end note

@enduml
```

---

## 4.5 Diagramme d'États: Session de Tracking GPS

```plantuml
@startuml GPS_Session_State_Diagram

[*] --> Idle : App launched

state Idle {
    Idle : No active session
    Idle : GPS off
    Idle : UI shows "Start Tracking" button
}

Idle --> PermissionCheck : User taps\n"Start Tracking"

state PermissionCheck <<choice>>
PermissionCheck --> Idle : Permission\nDenied
PermissionCheck --> Tracking : Permission\nGranted

state Tracking {
    [*] --> Initializing

    state Initializing {
        Initializing : Create LocationRecordModel
        Initializing : startTime = now
        Initializing : route = []
        Initializing : distanceKm = 0
    }

    Initializing --> Active : GPS stream\nstarted

    state Active {
        Active : Receiving GPS positions
        Active : Accumulating LocationPoints
        Active : Calculating distance
        Active : activityType = detected
        Active : UI shows live stats

        Active --> Active : New position\n(every 5s)

        state "Activity Detection" as ActivityDetect <<fork>>
        Active --> ActivityDetect : Every 30 points

        state Stationary {
            Stationary : avgSpeed < 1 km/h
        }
        state Walking {
            Walking : 1 ≤ avgSpeed < 6 km/h
        }
        state Running {
            Running : 6 ≤ avgSpeed < 12 km/h
        }
        state Cycling {
            Cycling : avgSpeed ≥ 12 km/h
        }

        ActivityDetect --> Stationary
        ActivityDetect --> Walking
        ActivityDetect --> Running
        ActivityDetect --> Cycling

        Stationary --> Active : Activity\nchanged
        Walking --> Active
        Running --> Active
        Cycling --> Active
    }

    Active --> Paused : User taps\n"Pause"

    state Paused {
        Paused : GPS stream paused
        Paused : Timer stopped
        Paused : Last position saved
        Paused : UI shows "Resume"
    }

    Paused --> Active : User taps\n"Resume"

    Active --> Finalizing : User taps\n"Stop"
    Paused --> Finalizing : User taps\n"Stop"

    state Finalizing {
        Finalizing : endTime = now
        Finalizing : Calculate total duration
        Finalizing : Calculate total distance
        Finalizing : Save to Hive
        Finalizing : Update DailyStats
        Finalizing : Stop GPS stream
    }

    Finalizing --> [*]
}

Tracking --> SessionComplete : Session\nfinalized

state SessionComplete {
    SessionComplete : LocationRecordModel saved
    SessionComplete : GPS off
    SessionComplete : UI shows SessionDetailsScreen
}

SessionComplete --> Idle : User returns\nto LocationTab

note right of Active
  GPS updates: every 5s
  Distance filter: 5m
  Battery: High consumption
end note

note right of Paused
  GPS paused to save battery
  Resume maintains same session
  No new points added
end note

note bottom of Finalizing
  Hive write: ~50ms
  Stats update: ~10ms
  Total: ~100ms
end note

@enduml
```

---

## 4.6 Diagramme d'États: Capteur Sensor (Générique)

```plantuml
@startuml Sensor_State_Diagram

[*] --> Inactive : App installed

state Inactive {
    Inactive : Sensor not activated
    Inactive : No SensorDataModel
    Inactive : UI shows "Activate" button
    Inactive : No data collection
}

Inactive --> Activating : User activates sensor\nfrom CentralHubScreen

state Activating {
    Activating : Request required permissions
    Activating : Create SensorDataModel
    Activating : Initialize configuration
    Activating : Save to Hive
    Activating : Update CentralData.activeSensors
}

state PermissionResult <<choice>>
Activating --> PermissionResult : Permissions check

PermissionResult --> Active : All permissions\ngranted
PermissionResult --> Error : Permissions\ndenied

state Active {
    [*] --> Configured

    state Configured {
        Configured : SensorDataModel exists
        Configured : Permissions granted
        Configured : UI tab enabled
        Configured : Ready to collect data
    }

    Configured --> Collecting : Data collection\nstarts

    state Collecting {
        [*] --> Sensing

        state Sensing {
            Sensing : Sensor reading data
            Sensing : (GPS, Bluetooth, User input)
        }

        Sensing --> Computing : Raw data\nreceived

        state Computing {
            Computing : Processing data
            Computing : Calculations
            Computing : Validations
        }

        Computing --> Storing : Processed\ndata ready

        state Storing {
            Storing : Create Record Model
            Storing : Save to Hive box
            Storing : Update statistics
            Storing : Emit stream event
        }

        Storing --> Sensing : Continue\ncollection

        note right of Sensing
          Sense-Compute-Control
          pattern applied
        end note
    }

    Collecting --> Configured : Collection\nstops

    Configured --> Exporting : User requests\nMCP export

    state Exporting {
        Exporting : Fetch all records
        Exporting : Aggregate data
        Exporting : Calculate insights
        Exporting : Anonymize IDs
        Exporting : Generate JSON section
    }

    Exporting --> Configured : Export\ncomplete
}

Active --> Deactivating : User deactivates sensor

state Deactivating {
    Deactivating : Stop data collection
    Deactivating : Update CentralData.activeSensors
    Deactivating : UI tab disabled
    Deactivating : Data preserved in Hive
}

Deactivating --> Inactive : Deactivation\ncomplete

state Error {
    Error : Permissions denied
    Error : Sensor unavailable
    Error : Show error message
}

Error --> Inactive : User dismisses

note right of Active
  Data preserved even
  when deactivated
  Can be reactivated anytime
end note

note bottom of Collecting
  Continuous process
  Runs until user stops
  or app closes
end note

@enduml
```

---

## 4.7 Diagramme de Classes: Modèles de Données

```plantuml
@startuml Data_Models_Class_Diagram

skinparam classAttributeIconSize 0
skinparam backgroundColor #FEFEFE

class CentralDataModel <<Entity>> {
    + id: String
    + name: String
    + email: String
    + age: int
    + gender: String
    + height: int {cm}
    + weight: int {kg}
    + profilePictureUrl: String?
    + activeSensors: List<String>
    + preferences: Map<String, dynamic>
    + createdAt: DateTime
    + updatedAt: DateTime
    --
    + {computed} bmi: double
    + {computed} bmiCategory: String
    --
    + copyWith(...): CentralDataModel
    + toJson(): Map<String, dynamic>
    + {static} fromJson(json): CentralDataModel
}

class MealsSensorDataModel <<Entity>> {
    + id: String
    + userId: String
    + goal: GoalType
    + targetWeight: int?
    + activityLevel: ActivityLevel
    + dailyCalorieGoal: int
    + nutritionPreferences: Map<String, dynamic>
    + createdAt: DateTime
    + updatedAt: DateTime
    --
    + calculateDailyCalories(): int
    + copyWith(...): MealsSensorDataModel
}

enum GoalType {
    maintainWeight
    loseWeight
    gainWeight
}

enum ActivityLevel {
    sedentary
    lightlyActive
    moderatelyActive
    veryActive
    extraActive
}

class MealModel <<Entity>> {
    + id: String
    + userId: String
    + name: String
    + description: String
    + calories: int
    + protein: double {g}
    + carbs: double {g}
    + fat: double {g}
    + mealType: MealType
    + date: DateTime
    + createdAt: DateTime
    + updatedAt: DateTime
    --
    + copyWith(...): MealModel
}

enum MealType {
    breakfast
    lunch
    dinner
    snack
}

class SleepSensorDataModel <<Entity>> {
    + id: String
    + userId: String
    + targetSleepHours: int
    + sleepPreferences: Map<String, dynamic>
    + createdAt: DateTime
    + updatedAt: DateTime
}

class SleepRecordModel <<Entity>> {
    + id: String
    + userId: String
    + bedTime: DateTime
    + wakeTime: DateTime
    + quality: SleepQuality
    + interruptionsCount: int
    + notes: String
    + createdAt: DateTime
    + updatedAt: DateTime
    --
    + {computed} durationMinutes: int
}

enum SleepQuality {
    poor
    fair
    good
    excellent
}

class SocialSensorDataModel <<Entity>> {
    + id: String
    + userId: String
    + targetInteractionsPerDay: int
    + socialPreferences: Map<String, dynamic>
    + createdAt: DateTime
    + updatedAt: DateTime
}

class SocialInteractionModel <<Entity>> {
    + id: String
    + userId: String
    + contactName: String
    + macAddress: String
    + firstEncounter: DateTime
    + lastEncounter: DateTime
    + encounterCount: int
    + durationMinutes: int
    + type: InteractionType
    + sentiment: SocialSentiment?
    + notes: String
    + createdAt: DateTime
    + updatedAt: DateTime
}

enum InteractionType {
    bluetooth
    inPerson
    phoneCall
    videoCall
    messaging
    socialMedia
    groupActivity
}

enum SocialSentiment {
    negative
    neutral
    positive
    veryPositive
}

class LocationSensorDataModel <<Entity>> {
    + id: String
    + userId: String
    + targetStepsPerDay: int
    + targetDistanceKm: double
    + locationPreferences: Map<String, dynamic>
    + createdAt: DateTime
    + updatedAt: DateTime
}

class LocationRecordModel <<Entity>> {
    + id: String
    + userId: String
    + startTime: DateTime
    + endTime: DateTime?
    + distanceKm: double
    + activityType: ActivityType
    + route: List<LocationPoint>
    + placeId: String?
    + placeName: String?
    + notes: String
    + createdAt: DateTime
    + updatedAt: DateTime
    --
    + {computed} durationSeconds: int
    + {computed} durationMinutes: int
    + {computed} averageSpeed: double
    + isActive(): bool
}

class LocationPoint <<ValueObject>> {
    + latitude: double
    + longitude: double
    + timestamp: DateTime
}

enum ActivityType {
    stationary
    walking
    running
    cycling
    driving
    other
}

class PlaceModel <<Entity>> {
    + id: String
    + userId: String
    + name: String
    + latitude: double
    + longitude: double
    + radiusMeters: double
    + icon: String?
    + createdAt: DateTime
    + updatedAt: DateTime
    --
    + isInside(position): bool
}

' Relationships
CentralDataModel "1" -- "0..1" MealsSensorDataModel : userId
CentralDataModel "1" -- "0..1" SleepSensorDataModel : userId
CentralDataModel "1" -- "0..1" SocialSensorDataModel : userId
CentralDataModel "1" -- "0..1" LocationSensorDataModel : userId

MealsSensorDataModel "1" -- "N" MealModel : userId
SleepSensorDataModel "1" -- "N" SleepRecordModel : userId
SocialSensorDataModel "1" -- "N" SocialInteractionModel : userId
LocationSensorDataModel "1" -- "N" LocationRecordModel : userId

MealsSensorDataModel --> GoalType
MealsSensorDataModel --> ActivityLevel
MealModel --> MealType

SleepRecordModel --> SleepQuality

SocialInteractionModel --> InteractionType
SocialInteractionModel --> SocialSentiment

LocationRecordModel "1" *-- "N" LocationPoint : composition
LocationRecordModel --> ActivityType
LocationRecordModel "N" -- "0..1" PlaceModel : placeId

note top of CentralDataModel
  HiveType: typeId = 5
  Primary user profile
  Shared across all sensors
end note

note bottom of MealModel
  HiveType: typeId = 2
  Nutrition tracking
  API enrichment via Spoonacular
end note

note right of LocationRecordModel
  HiveType: typeId = 17
  GPS tracking session
  Haversine distance calculation
end note

@enduml
```

---

# 5️⃣ ANALYSE DE QUALITÉ

## 5.1 Qualités Architecturales (ISO 25010)

### Modifiability (Modifiabilité)
**Score: 9/10**

✅ **Forces**:
- Architecture en couches stricte facilite les changements
- Repository pattern isole le stockage
- Sensors indépendants (changement Meals n'affecte pas Sleep)
- Service layer encapsule logique métier complexe

⚠️ **Faiblesses**:
- Migration UserModel → CentralDataModel en cours
- Pas de gestion centralisée d'état (Provider/Riverpod manquant)

**Exemple**: Changer Hive → SQLite nécessite uniquement modification de LocalStorageService + Repositories. UI et Services inchangés.

---

### Testability (Testabilité)
**Score: 7/10**

✅ **Forces**:
- Repositories mockables
- Services isolés avec interfaces claires
- Pas de dépendances cachées (Dependency Injection manuelle)

⚠️ **Faiblesses**:
- Pas de DI framework (GetIt, Riverpod)
- Tests unitaires manquants (seulement widget_test.dart)
- Services dépendent directement de Hive (difficile à mocker)

**Recommandation**: Implémenter interfaces abstraites pour repositories et injecter via constructeur.

---

### Scalability (Scalabilité)
**Score: 8/10**

✅ **Forces**:
- Stockage local évite bottleneck serveur
- Hive performant jusqu'à millions d'enregistrements
- Architecture modulaire (ajout sensors facile)
- Calculs dérivés (BMI, calories) efficients

⚠️ **Faiblesses**:
- Pas de pagination dans UI (liste repas complète chargée)
- Pas de compression historique (données > 1 an)
- Export MCP synchrone (bloquant pour gros volumes)

**Capacité estimée**:
- 10 ans de données: ~35 MB
- 10,000 repas: Export JSON ~8 MB, durée ~2s

---

### Performance
**Score: 8/10**

✅ **Forces**:
- Hive très rapide (write ~1ms, read ~0.5ms)
- Streams pour UI temps réel (pas de polling)
- Calculs en isolates (compute) pour éviter jank
- Caching implicite de Hive en mémoire

⚠️ **Faiblesses**:
- GPS tracking continu consomme batterie
- Bluetooth scan périodique consomme ressources
- Export MCP génère gros JSON en mémoire (pas de streaming)

**Benchmarks**:
- Ajout repas: ~50ms
- Chargement 100 repas: ~30ms
- Export 1000 repas: ~500ms
- GPS update: ~5s interval

---

### Security (Sécurité)
**Score: 6/10**

✅ **Forces**:
- Données stockées localement uniquement
- Export MCP anonymise userId (hash)
- Pas de transmission automatique vers cloud
- Permissions explicites (GPS, Bluetooth, Contacts)

⚠️ **Faiblesses**:
- ❌ Hive NON chiffré (données santé sensibles)
- ❌ API Key Spoonacular hardcodée dans code source
- ❌ Pas d'authentification utilisateur (device-level seulement)
- ❌ Export JSON en clair (pas de chiffrement)

**Recommandations critiques**:
1. Activer Hive encryption: `HiveAES256` avec clé dérivée du device
2. API Keys dans variables d'environnement (flutter_dotenv)
3. Chiffrer exports MCP (AES-256)
4. Ajouter PIN/biométrie pour accès app

---

### Usability (Utilisabilité)
**Score: 8/10**

✅ **Forces**:
- UI intuitive avec 5 tabs dédiées
- Navigation par swipe (PageView)
- Onboarding guidé pour premier lancement
- Feedback visuel (SnackBars, progress bars)
- Material Design + Cupertino (cross-platform)

⚠️ **Faiblesses**:
- Pas de mode sombre (dark mode)
- Pas de localisation (français hardcodé)
- Absence de tutoriels in-app
- Pas d'accessibilité (screen readers)

---

### Maintainability (Maintenabilité)
**Score: 7/10**

✅ **Forces**:
- Code structuré en packages (core, data, presentation)
- Naming conventions cohérentes
- Documentation inline (commentaires)
- Linting activé (flutter_lints)

⚠️ **Faiblesses**:
- Absence de documentation API (Dart Doc)
- Pas de tests automatisés
- Debt technique (UserModel legacy)
- Duplication de code (tous les sensors suivent même pattern mais pas d'abstraction)

**Recommandations**:
1. Générer documentation: `dart doc`
2. Implémenter interface `SensorPlugin` commune
3. Ajouter CI/CD (GitHub Actions pour tests + linting)

---

## 5.2 Risques Identifiés

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| **Perte de données (Hive corruption)** | Faible | Critique | Backup automatique vers cloud, export régulier |
| **Battery drain (GPS continu)** | Élevée | Moyen | Mode économie, pause automatique si stationnaire |
| **API Spoonacular rate limit** | Moyenne | Faible | Cache local des recettes, limitation recherches |
| **Permissions refusées** | Élevée | Moyen | Fallback vers saisie manuelle |
| **Évolution schema Hive** | Moyenne | Élevé | Migrations versionnées, backup avant migration |
| **Security breach (données santé)** | Faible | Critique | Activer encryption Hive + PIN app |

---

## 5.3 Conformité aux Principes SOLID

### Single Responsibility Principle (SRP)
✅ **Respecté**: Chaque classe a une responsabilité unique
- `MealRepository`: CRUD meals uniquement
- `MCPExportService`: Export logic seulement
- `LocationTrackingService`: GPS tracking seulement

### Open/Closed Principle (OCP)
⚠️ **Partiellement respecté**:
- ✅ Ajout nouveau sensor sans modifier existants
- ❌ Changement format MCP nécessite modification MCPExportService

**Amélioration**: Utiliser Strategy pattern pour export formats multiples.

### Liskov Substitution Principle (LSP)
✅ **Respecté**: Pas de hiérarchies d'héritage complexes. Préférence pour composition.

### Interface Segregation Principle (ISP)
⚠️ **À améliorer**: Pas d'interfaces explicites (Dart permet implicite). Créer interfaces abstraites pour repositories.

### Dependency Inversion Principle (DIP)
⚠️ **Partiellement respecté**:
- ❌ UI dépend directement de repositories concrets
- ❌ Services dépendent de LocalStorageService concret

**Amélioration**: Injecter abstractions via DI framework (GetIt/Riverpod).

---

## 5.4 Métriques de Complexité

### Complexité Cyclomatique (estimée)

| Composant | Méthodes | Complexité Moy. | Évaluation |
|-----------|----------|-----------------|------------|
| `CentralDataRepository` | 6 | 2.3 | Très simple |
| `MealRepository` | 12 | 4.5 | Simple |
| `MCPExportService` | 8 | 7.2 | Modérée |
| `LocationTrackingService` | 15 | 8.5 | Modérée à élevée |
| `BluetoothSocialService` | 10 | 6.8 | Modérée |

**Seuils**:
- 1-5: Simple ✅
- 6-10: Modérée ⚠️
- 11+: Complexe ❌ (refactoring nécessaire)

**Recommandation**: Extraire sous-méthodes dans LocationTrackingService (détection activité, calcul distance).

---

## 5.5 Couverture de Code

**Actuelle**: ~0% (pas de tests automatisés)

**Cible recommandée**:
- Repositories: 80%+
- Services: 70%+
- Models: 90%+ (sérialization tests)
- UI: 50%+ (widget tests)

---

# CONCLUSION

## Forces de l'Architecture

1. ✅ **Modularité exemplaire**: Séparation centrale/capteurs permet évolutivité infinie
2. ✅ **Offline-first**: Pas de dépendance réseau, 100% fonctionnel hors ligne
3. ✅ **Sense-Compute-Control**: Pattern adapté aux systèmes IoT/capteurs
4. ✅ **Repository Pattern**: Abstraction solide du stockage
5. ✅ **Scalabilité**: Architecture prête pour 10+ capteurs supplémentaires
6. ✅ **Export MCP standardisé**: Format structuré pour analyse IA
7. ✅ **UI intuitive**: Navigation claire, feedback visuel

## Axes d'Amélioration Prioritaires

### Court Terme (1-2 semaines)
1. 🔒 **Sécurité**: Activer Hive encryption + externaliser API keys
2. 🧪 **Tests**: Implémenter tests unitaires pour repositories et services
3. 📱 **Compléter capteurs**: Sleep, Social, Location (actuellement modèles seulement)

### Moyen Terme (1-2 mois)
4. 🎨 **State Management**: Migrer vers Riverpod pour gestion d'état centralisée
5. 🔌 **Dependency Injection**: Utiliser GetIt pour injection dépendances
6. 🌐 **Localisation**: Implémenter i18n (flutter_localizations)
7. 🌙 **Dark Mode**: Thème sombre

### Long Terme (3-6 mois)
8. 🔄 **Sync Cloud optionnel**: Backup chiffré vers Firebase/AWS S3
9. 🤖 **MCP Integration native**: API directe vers serveur MCP (pas export manuel)
10. 📊 **Analytics avancées**: Corrélations cross-capteurs, ML on-device
11. ⌚ **Wearables**: Intégration Apple Watch, Garmin, Fitbit

---

## Adéquation avec le Cours Software Architecture

Cette analyse a appliqué systématiquement les concepts du cours:

✅ **Architectural Styles**: Layered, Sense-Compute-Control, Event-Based, Client-Server
✅ **Patterns**: Repository, Service Layer, Factory, Adapter, Observer
✅ **DSSA**: "Multi-Sensor Health Hub" spécialisé
✅ **Components**: Processing (services), Data (models), Interface (UI)
✅ **Connectors**: Procedure Call, Message Passing, Streaming, Shared Memory, Wrappers
✅ **Views 4+1**: Logical, Process, Development, Physical, Scenarios
✅ **UML Diagrams**: Composants, Séquence, Déploiement, États, Classes

L'architecture HealthSync démontre une application rigoureuse des principes architecturaux, avec une séparation claire des responsabilités, une modularité exemplaire, et une évolutivité à long terme.

---

**Fin du Document**
