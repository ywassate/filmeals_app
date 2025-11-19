# 📍 Plan d'Intégration - Capteur Activité Physique (GPS Tracker)

## Vue d'ensemble

Intégration du capteur d'activité physique basé sur GPS dans **HealthSync** pour tracker les déplacements, activités (marche, course, stationnaire) et calculer distances et durées.

---

## 🔍 Analyse du Capteur Source

### Architecture Existante (fitness_tracker)

**Repo GitHub** : https://github.com/mohammedarif913/fitness_tracker

#### Modèles de Données

**1. ActivityModel**
```dart
@HiveType(typeId: 0)
class ActivityModel {
  @HiveField(0) String id;
  @HiveField(1) ActivityType type;        // running, walking, stationary
  @HiveField(2) DateTime startTime;
  @HiveField(3) DateTime? endTime;
  @HiveField(4) double distance;          // km
  @HiveField(5) int duration;             // seconds
  @HiveField(6) List<LocationPoint> route; // GPS points
}

enum ActivityType {
  running,
  walking,
  stationary,
}
```

**2. LocationPoint**
```dart
@HiveType(typeId: 1)
class LocationPoint {
  @HiveField(0) double latitude;
  @HiveField(1) double longitude;
  @HiveField(2) DateTime timestamp;
}
```

**3. ActivitySession** (session continue)
```dart
@HiveType(typeId: 5)
class ActivitySession {
  @HiveField(0) String id;
  @HiveField(1) ActivityType activityType;
  @HiveField(2) DateTime startTime;
  @HiveField(3) DateTime? endTime;
  @HiveField(4) double distance;          // km
  @HiveField(5) List<LocationPoint> routePoints;
  @HiveField(6) String? placeId;
  @HiveField(7) String? placeName;        // ex: "My Gym"

  int getDuration();     // secondes
  bool isActive();       // session en cours?
}
```

**4. PlaceModel** (lieux enregistrés)
```dart
@HiveType(typeId: 6)
class PlaceModel {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) double latitude;
  @HiveField(3) double longitude;
  @HiveField(4) double radius;            // mètres
  @HiveField(5) DateTime createdAt;
}
```

#### Fonctionnalités Principales

**ActivityTrackerService** :
1. **Tracking GPS continu** :
   - Stream de positions avec filtre 5 mètres
   - Mise à jour toutes les quelques secondes
   - Accumulation des points GPS

2. **Détection automatique d'activité** :
   - Calcul vitesse moyenne (30 derniers points)
   - Classification automatique : stationnaire / marche / course
   - Changement de session automatique

3. **Calcul de distance** :
   - Distance totale via formule Haversine
   - Basé sur tous les points GPS collectés

4. **Gestion de sessions** :
   - Création automatique de nouvelles sessions
   - Fin de session quand activité change
   - Sauvegarde dans Hive

5. **Statistiques quotidiennes** :
   - Durée par type d'activité
   - Distance totale
   - Temps par lieu (si défini)

**LocationService** :
- Demande permissions GPS
- Stream de positions en temps réel
- Calcul de distance entre points
- Conversion coordonnées → adresse

**PlaceService** :
- Gestion des lieux favoris (gym, maison, etc.)
- Détection proximité lieu
- CRUD Hive pour places

#### Technologies
- `geolocator` : GPS et localisation
- `geocoding` : Adresses → Coordonnées
- `hive` : Stockage local
- `permission_handler` : Permissions

---

## 🏗️ Architecture d'Intégration dans HealthSync

### Approche : Adaptation avec nos modèles existants

On va **adapter** les modèles du fitness_tracker pour utiliser notre `LocationRecordModel` et `LocationSensorDataModel`.

### Modèles à Adapter

#### 1. LocationSensorDataModel (existant) ✅
```dart
LocationSensorDataModel {
  String id;
  String userId;
  int targetStepsPerDay;
  double targetDistanceKm;
  Map<String, dynamic> locationPreferences;
  DateTime createdAt;
  DateTime updatedAt;
}
```

#### 2. LocationRecordModel (à enrichir)
```dart
// AVANT (notre modèle actuel)
LocationRecordModel {
  String id;
  String userId;
  DateTime startTime;
  DateTime endTime;
  double distanceKm;
  int stepsCount;
  ActivityType activityType;
  List<LocationPoint> route;
  String notes;
}

// APRÈS (enrichi avec fitness_tracker)
LocationRecordModel {
  String id;
  String userId;
  DateTime startTime;
  DateTime? endTime;              // nullable si session active
  double distanceKm;
  int durationSeconds;            // calculé automatiquement
  ActivityType activityType;      // running, walking, stationary
  List<LocationPoint> route;      // points GPS
  String? placeId;                // référence à PlaceModel
  String? placeName;              // "My Gym", "Home", etc.
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

  // Méthodes calculées
  int get durationMinutes => durationSeconds ~/ 60;
  bool isActive() => endTime == null;
  double get averageSpeed;        // km/h
}
```

#### 3. LocationPoint (déjà existant) ✅
```dart
@HiveType(typeId: 18)
class LocationPoint {
  @HiveField(0) double latitude;
  @HiveField(1) double longitude;
  @HiveField(2) DateTime timestamp;
}
```

#### 4. PlaceModel (nouveau)
```dart
@HiveType(typeId: 21)
class PlaceModel {
  @HiveField(0) String id;
  @HiveField(1) String userId;
  @HiveField(2) String name;              // "Gym", "Travail", etc.
  @HiveField(3) double latitude;
  @HiveField(4) double longitude;
  @HiveField(5) double radiusMeters;      // Zone de détection
  @HiveField(6) String? icon;             // Icône personnalisée
  @HiveField(7) DateTime createdAt;
  @HiveField(8) DateTime updatedAt;
}
```

#### 5. DailyActivityStats (nouveau - statistiques)
```dart
@HiveType(typeId: 22)
class DailyActivityStats {
  @HiveField(0) String id;
  @HiveField(1) String userId;
  @HiveField(2) DateTime date;            // Jour
  @HiveField(3) int runningSeconds;       // Durée course
  @HiveField(4) int walkingSeconds;       // Durée marche
  @HiveField(5) int stationarySeconds;    // Durée stationnaire
  @HiveField(6) double totalDistanceKm;   // Distance totale
  @HiveField(7) Map<String, int> placeTimings; // Temps par lieu
  @HiveField(8) int totalSessions;        // Nombre de sessions
}
```

---

## 📦 Dépendances à Ajouter

### pubspec.yaml
```yaml
dependencies:
  # GPS & Location
  geolocator: ^10.1.0
  geocoding: ^2.1.1

  # Permissions
  permission_handler: ^11.0.1

  # Maps (optionnel, pour visualisation)
  google_maps_flutter: ^2.5.0
  flutter_polyline_points: ^2.0.0
```

---

## 🔧 Services à Créer

### 1. LocationTrackingService
**Fichier** : `lib/core/services/location_tracking_service.dart`

**Responsabilités** :
- Stream GPS en temps réel
- Détection automatique d'activité
- Calcul de distance
- Gestion de sessions
- Sauvegarde Hive

**Méthodes principales** :
```dart
class LocationTrackingService {
  // === TRACKING ===
  Future<void> startTracking();
  Future<void> stopTracking();
  Future<void> pauseTracking();
  Future<void> resumeTracking();

  // === STREAMS ===
  Stream<Position> get positionStream;
  Stream<LocationRecordModel?> get currentSessionStream;
  Stream<DailyActivityStats> get dailyStatsStream;

  // === ACTIVITÉ ===
  Future<void> _detectActivity();      // Toutes les 10 secondes
  ActivityType _classifyActivity(double avgSpeed);

  // === DISTANCE ===
  double calculateDistance(List<LocationPoint> points);
  double _haversineDistance(LocationPoint p1, LocationPoint p2);

  // === SESSIONS ===
  Future<void> _createNewSession(ActivityType type);
  Future<void> _endCurrentSession();
  Future<void> _updateSession(Position position);

  // === PLACES ===
  PlaceModel? _detectNearbyPlace(Position position);
  Future<void> _updatePlaceTime(String placeId, int seconds);

  // === STATISTIQUES ===
  Future<DailyActivityStats> getDailyStats(DateTime date);
  Future<void> _updateDailyStats();
}
```

**Algorithme de détection d'activité** :
```dart
ActivityType _classifyActivity(double avgSpeed) {
  // avgSpeed en km/h
  if (avgSpeed < 1.0) return ActivityType.stationary;
  if (avgSpeed < 6.0) return ActivityType.walking;
  if (avgSpeed < 12.0) return ActivityType.running;
  return ActivityType.cycling; // optionnel
}
```

**Calcul vitesse moyenne** :
```dart
double _calculateAverageSpeed() {
  if (_recentPoints.length < 2) return 0.0;

  // Prendre les 30 derniers points (ou moins)
  final points = _recentPoints.take(30).toList();

  final distance = calculateDistance(points); // km
  final duration = points.last.timestamp
      .difference(points.first.timestamp)
      .inSeconds / 3600.0; // heures

  if (duration == 0) return 0.0;
  return distance / duration; // km/h
}
```

### 2. PlaceManagementService
**Fichier** : `lib/core/services/place_management_service.dart`

**Responsabilités** :
- CRUD pour lieux favoris
- Détection proximité
- Statistiques par lieu

**Méthodes** :
```dart
class PlaceManagementService {
  // CRUD
  Future<void> createPlace(PlaceModel place);
  Future<PlaceModel?> getPlace(String id);
  Future<List<PlaceModel>> getAllPlaces(String userId);
  Future<void> updatePlace(PlaceModel place);
  Future<void> deletePlace(String id);

  // Détection
  PlaceModel? findNearbyPlace(Position position, List<PlaceModel> places);
  bool isInsidePlace(Position position, PlaceModel place);

  // Statistiques
  Future<Map<String, int>> getPlaceTimings(String userId, DateTime date);
}
```

### 3. LocationSensorRepository
**Fichier** : `lib/data/repository/location_sensor_repository.dart`

**Responsabilités** :
- CRUD pour LocationSensorDataModel
- CRUD pour LocationRecordModel
- CRUD pour PlaceModel
- CRUD pour DailyActivityStats
- Statistiques et agrégations

---

## 🎨 UI à Créer

### 1. Location Tab (écran principal)
**Fichier** : `lib/presentation/screens/location/location_tab.dart`

```
┌─────────────────────────────────────┐
│ 📍 Activité Physique                │
├─────────────────────────────────────┤
│                                     │
│ 📊 Aujourd'hui                      │
│ ┌─────────────────────────────────┐ │
│ │ 🏃 Course : 15 min              │ │
│ │ 🚶 Marche : 45 min              │ │
│ │ 📏 Distance : 5.2 km            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🎯 Objectifs du jour                │
│ Distance: ████████░░ 5.2/10 km     │
│ Pas: ████████████ 10,000 pas       │
│                                     │
│ 🗺️ Session en cours                │
│ ┌─────────────────────────────────┐ │
│ │  [Mini-carte avec route]        │ │
│ │  🏃 Course - 2.5 km             │ │
│ │  ⏱️ 12:34 en cours              │ │
│ │                                  │ │
│ │  [⏸️ Pause] [⏹️ Stop]           │ │
│ └─────────────────────────────────┘ │
│                                     │
│ OU (si pas de session)              │
│ ┌─────────────────────────────────┐ │
│ │  [▶️ Démarrer le tracking]      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📜 Historique des sessions          │
│ ┌─────────────────────────────────┐ │
│ │ 🏃 Course matinale              │ │
│ │    3.2 km • 18 min • 10:00      │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🚶 Promenade                    │ │
│ │    1.5 km • 25 min • 15:30      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📌 Lieux favoris                    │
│ [Gérer mes lieux]                   │
│                                     │
└─────────────────────────────────────┘
```

### 2. Tracking Screen (session active)
**Fichier** : `lib/presentation/screens/location/tracking_screen.dart`

```
┌─────────────────────────────────────┐
│ 🏃 Course en cours                  │
├─────────────────────────────────────┤
│                                     │
│  [Carte plein écran avec route]    │
│  • Point de départ (vert)          │
│  • Route tracée (bleu)             │
│  • Position actuelle (rouge)       │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │  ⏱️ Durée                        │ │
│ │     00:12:34                     │ │
│ │                                  │ │
│ │  📏 Distance                     │ │
│ │     2.5 km                       │ │
│ │                                  │ │
│ │  🏃 Vitesse                      │ │
│ │     8.5 km/h                     │ │
│ │                                  │ │
│ │  📍 Lieu                         │ │
│ │     Parc Central                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│  [⏸️ Pause]  [⏹️ Terminer]         │
│                                     │
└─────────────────────────────────────┘
```

### 3. Session Details Screen
**Fichier** : `lib/presentation/screens/location/session_details_screen.dart`

```
┌─────────────────────────────────────┐
│ ← 🏃 Course matinale                │
├─────────────────────────────────────┤
│                                     │
│  [Carte avec route complète]       │
│                                     │
│ 📊 Statistiques                     │
│ ┌─────────────────────────────────┐ │
│ │ Distance : 3.2 km               │ │
│ │ Durée : 18 min 23 sec           │ │
│ │ Vitesse moy : 10.5 km/h         │ │
│ │ Départ : 10:00                  │ │
│ │ Arrivée : 10:18                 │ │
│ │ Lieu : Parc Central             │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🗺️ Détails du parcours             │
│ ┌─────────────────────────────────┐ │
│ │ 📍 Départ                        │ │
│ │    Lat: 48.8566, Lon: 2.3522    │ │
│ │    10:00:00                      │ │
│ │                                  │ │
│ │ ... 245 points GPS ...           │ │
│ │                                  │ │
│ │ 📍 Arrivée                       │ │
│ │    Lat: 48.8590, Lon: 2.3550    │ │
│ │    10:18:23                      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📝 Notes                            │
│ [Ajouter une note...]               │
│                                     │
│ [🗑️ Supprimer]  [📤 Partager]      │
│                                     │
└─────────────────────────────────────┘
```

### 4. Places Management Screen
**Fichier** : `lib/presentation/screens/location/places_screen.dart`

```
┌─────────────────────────────────────┐
│ ← 📌 Mes Lieux                      │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🏠 Maison                       │ │
│ │    10 rue de Paris              │ │
│ │    Rayon: 100m                  │ │
│ │    [✏️] [🗑️]                    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💪 Gym                          │ │
│ │    5 avenue du Sport            │ │
│ │    Rayon: 50m                   │ │
│ │    [✏️] [🗑️]                    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🏢 Travail                      │ │
│ │    20 boulevard Commerce        │ │
│ │    Rayon: 200m                  │ │
│ │    [✏️] [🗑️]                    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [➕ Ajouter un lieu]                │
│                                     │
└─────────────────────────────────────┘
```

### 5. Add Place Screen
```
┌─────────────────────────────────────┐
│ ← Ajouter un lieu                   │
├─────────────────────────────────────┤
│                                     │
│  [Carte interactive]                │
│  • Marker déplaçable               │
│  • Cercle de rayon                 │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📝 Nom du lieu                  │ │
│ │    [Maison]                      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🎨 Icône                        │ │
│ │    🏠 🏢 💪 🏫 🏥 🍽️            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📏 Rayon de détection           │ │
│ │    [100] mètres                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📍 Position                         │
│ Lat: 48.8566, Lon: 2.3522          │
│ [📍 Utiliser ma position actuelle] │
│                                     │
│ [💾 Sauvegarder]                    │
│                                     │
└─────────────────────────────────────┘
```

---

## 🔐 Permissions Nécessaires

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

<!-- Activity Recognition (optionnel) -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>HealthSync suit vos activités physiques pour calculer distances et durées</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Le tracking continu permet de suivre vos sessions d'activité</string>
```

---

## 🔄 Flux de Données

### 1. Démarrage d'une session
```
User clique "Démarrer le tracking"
    ↓
Demande permissions GPS
    ↓
Si accordées :
  - LocationTrackingService.startTracking()
  - Initialiser stream GPS
  - Créer nouvelle session
  - Démarrer timer (toutes les 10s)
    ↓
Pour chaque position GPS :
  1. Ajouter point à la route
  2. Calculer distance totale
  3. Mettre à jour session
  4. Broadcaster via stream
    ↓
Toutes les 10 secondes :
  1. Calculer vitesse moyenne
  2. Classifier activité
  3. Si changement d'activité :
     - Terminer session actuelle
     - Créer nouvelle session
  4. Détecter lieu proche
  5. Mettre à jour statistiques
```

### 2. Arrêt d'une session
```
User clique "Terminer"
    ↓
LocationTrackingService.stopTracking()
    ↓
Finaliser session actuelle :
  - endTime = now
  - Calculer durée totale
  - Calculer distance finale
    ↓
Sauvegarder dans Hive :
  - LocationRecordModel (session complète)
  - DailyActivityStats (mise à jour)
    ↓
Arrêter streams GPS
    ↓
Naviguer vers Session Details Screen
```

### 3. Détection automatique lieu
```
Nouvelle position GPS reçue
    ↓
PlaceManagementService.findNearbyPlace()
    ↓
Pour chaque lieu enregistré :
  - Calculer distance entre position et lieu
  - Si distance < lieu.radius :
     - Marquer présence dans le lieu
     - Incrémenter compteur temps
     - Associer lieu à la session
```

---

## 📤 Export vers MCP

### Format JSON
```json
{
  "sensor_type": "location",
  "status": "active",
  "config": {
    "target_steps_per_day": 10000,
    "target_distance_km": 5.0,
    "detection_method": "gps",
    "min_accuracy_meters": 10
  },
  "data_summary": {
    "total_sessions": 45,
    "total_distance_km": 125.5,
    "date_range": {
      "start": "2025-01-01",
      "end": "2025-01-20"
    },
    "avg_session_duration_minutes": 25,
    "activity_breakdown": {
      "running_percent": 30,
      "walking_percent": 60,
      "stationary_percent": 10
    },
    "favorite_places": [
      {"name": "Gym", "visits": 15},
      {"name": "Parc", "visits": 10}
    ]
  },
  "sessions": [
    {
      "id": "session_001",
      "activity_type": "running",
      "start_time": "2025-01-20T10:00:00Z",
      "end_time": "2025-01-20T10:18:23Z",
      "duration_seconds": 1103,
      "distance_km": 3.2,
      "average_speed_kmh": 10.5,
      "place_name": "Parc Central",
      "route_points_count": 245,
      "route": [
        {"lat": 48.8566, "lon": 2.3522, "timestamp": "..."},
        {"lat": 48.8570, "lon": 2.3525, "timestamp": "..."}
      ]
    }
  ],
  "daily_stats": [
    {
      "date": "2025-01-20",
      "running_seconds": 1103,
      "walking_seconds": 2700,
      "stationary_seconds": 300,
      "total_distance_km": 5.2,
      "total_sessions": 3,
      "place_timings": {
        "Parc Central": 1800,
        "Gym": 1200
      }
    }
  ]
}
```

---

## 🚀 Plan d'Implémentation

### Phase 1 : Setup (1-2h)
- [ ] Ajouter dépendances (geolocator, geocoding)
- [ ] Configurer permissions Android/iOS
- [ ] Adapter LocationRecordModel
- [ ] Créer PlaceModel et DailyActivityStats
- [ ] Générer adaptateurs Hive (typeId 21, 22)

### Phase 2 : Services Core (4-5h)
- [ ] LocationTrackingService complet
- [ ] Algorithme détection activité
- [ ] Calcul distance (Haversine)
- [ ] Gestion sessions automatique
- [ ] PlaceManagementService

### Phase 3 : Repositories (1h)
- [ ] LocationSensorRepository
- [ ] CRUD pour tous les modèles
- [ ] Méthodes statistiques

### Phase 4 : UI Principale (3-4h)
- [ ] Location Tab (dashboard)
- [ ] Tracking Screen (session active)
- [ ] Session Details
- [ ] Intégration Google Maps (optionnel)

### Phase 5 : Gestion Lieux (2-3h)
- [ ] Places Screen (liste)
- [ ] Add/Edit Place Screen
- [ ] Carte interactive
- [ ] Détection proximité

### Phase 6 : Polish & Tests (2h)
- [ ] Tests sur appareil réel (GPS requis)
- [ ] Background tracking (optionnel)
- [ ] Animations et transitions
- [ ] Export MCP

**Temps total estimé** : 13-17 heures

---

## ⚠️ Limitations & Considérations

### Limitations Techniques
1. **GPS requis** : Ne fonctionne pas sans GPS
2. **Batterie** : Tracking continu consomme beaucoup
3. **Précision** : 5-10 mètres en conditions normales
4. **Background** : Limité sur iOS (nécessite configuration spéciale)

### Optimisations Batterie
1. **Filtre distance** : 5 mètres minimum entre points
2. **Pause automatique** : Si stationnaire trop longtemps
3. **Fréquence adaptative** : Réduire en intérieur
4. **Mode économie** : Précision réduite, moins de points

### Alternatives
- **Pedometer** : Comptage de pas via accéléromètre (moins précis mais économique)
- **ActivityRecognition** : API Android/iOS pour détecter activité
- **Saisie manuelle** : Fallback si GPS indisponible

---

## 📚 Ressources

### Documentation
- Geolocator : https://pub.dev/packages/geolocator
- Geocoding : https://pub.dev/packages/geocoding
- Google Maps Flutter : https://pub.dev/packages/google_maps_flutter

### Repo Source
- Fitness Tracker : https://github.com/mohammedarif913/fitness_tracker

### Formules
- **Haversine Distance** : Calcul distance entre coordonnées GPS
- **Vitesse moyenne** : distance / temps
- **Classification activité** : Par seuils de vitesse

---

## ✅ Checklist de Validation

- [ ] GPS tracking fonctionne en temps réel
- [ ] Distance calculée correctement (Haversine)
- [ ] Détection activité automatique opérationnelle
- [ ] Sessions créées/terminées automatiquement
- [ ] Lieux détectés correctement (rayon)
- [ ] Statistiques quotidiennes à jour
- [ ] UI responsive et fluide
- [ ] Carte affiche route correctement
- [ ] Permissions gérées proprement
- [ ] Export MCP formaté
- [ ] Batterie optimisée
- [ ] Tests sur appareil réel (2+ sessions)

---

## 🎯 Objectif Final

Intégrer un capteur d'activité physique GPS complet dans HealthSync, permettant le tracking automatique des déplacements, la classification des activités, la gestion de lieux favoris, et la génération de statistiques détaillées pour analyse MCP.

**Résultat attendu** : Un capteur GPS/Location fonctionnel, activable depuis le Hub Central, avec tracking en temps réel, carte interactive, et export de données enrichies.
