# 📱 Plan d'Intégration - Capteur Social (Bluetooth Tracker)

## Vue d'ensemble

Intégration du capteur de contacts sociaux basé sur Bluetooth dans **HealthSync** pour tracker les interactions sociales via la détection de périphériques Bluetooth.

---

## 🔍 Analyse du Capteur Source

### Architecture Existante (bluetooth-tracker)

**Repo GitHub** : https://github.com/saidoubari1/bluetooth-tracker

#### Modèle de Données
```dart
Contact {
  String adresseMac;           // MAC address (PRIMARY KEY)
  String nom;                  // Nom du contact
  DateTime premiereRencontre;  // Première détection
  DateTime derniereRencontre;  // Dernière détection
  int nombreRencontres;        // Compteur de rencontres
}
```

#### Fonctionnalités Principales
1. **Détection Bluetooth** :
   - Scan Classic Bluetooth (pas BLE)
   - Détection des appareils appairés + actifs
   - Validation temporelle : 2 minutes minimum de proximité

2. **Matching Contacts** :
   - Algorithme de scoring (0-100 points)
   - Correspondance avec contacts téléphone
   - Cache 24h pour optimisation

3. **Stockage** :
   - SQLite local
   - Table `contacts` avec 5 colonnes
   - Export JSON pour analyse externe

4. **Services** :
   - `BluetoothService` : Scanning et détection
   - `ContactsService` : Matching algorithme
   - `DatabaseHelper` : SQLite operations

#### Technologies
- `flutter_bluetooth_serial` : Bluetooth Classic
- `sqflite` : Base de données locale
- `flutter_contacts` : Accès contacts téléphone
- `permission_handler` : Gestion permissions

---

## 🏗️ Architecture d'Intégration dans HealthSync

### Approche : Adaptation avec notre système Hive

Au lieu de SQLite, on va adapter pour utiliser **Hive** (cohérent avec l'architecture HealthSync).

### Modèles à Créer/Adapter

#### 1. SocialSensorDataModel (existant) ✅
```dart
SocialSensorDataModel {
  String id;
  String userId;
  int targetInteractionsPerDay;
  Map<String, dynamic> socialPreferences;
  DateTime createdAt;
  DateTime updatedAt;
}
```

#### 2. SocialInteractionModel (à adapter)
```dart
// AVANT (notre modèle actuel)
SocialInteractionModel {
  String id;
  String userId;
  InteractionType type;          // inPerson, phoneCall, etc.
  int durationMinutes;
  int peopleCount;
  SocialSentiment sentiment;
  String description;
  DateTime timestamp;
}

// APRÈS (adapté pour Bluetooth)
SocialInteractionModel {
  String id;
  String userId;
  String contactName;              // Nom du contact détecté
  String macAddress;               // Adresse MAC Bluetooth
  DateTime firstEncounter;         // Première détection
  DateTime lastEncounter;          // Dernière détection
  int encounterCount;              // Nombre de rencontres
  int durationMinutes;             // Durée totale
  InteractionType type;            // = bluetooth
  String notes;                    // Notes optionnelles
  DateTime createdAt;
  DateTime updatedAt;
}
```

#### 3. BluetoothEncounter (nouveau modèle temporaire)
```dart
@HiveType(typeId: 20)
class BluetoothEncounter {
  @HiveField(0)
  String macAddress;

  @HiveField(1)
  String deviceName;

  @HiveField(2)
  DateTime firstSeen;

  @HiveField(3)
  DateTime lastSeen;

  @HiveField(4)
  bool isValidated;  // true si durée > 2 min

  // Calculé
  Duration get duration => lastSeen.difference(firstSeen);
}
```

---

## 📦 Dépendances à Ajouter

### pubspec.yaml
```yaml
dependencies:
  # Bluetooth
  flutter_bluetooth_serial: ^0.4.0

  # Contacts
  flutter_contacts: ^1.1.7+1

  # Permissions
  permission_handler: ^11.0.1

  # Export/Share
  share_plus: ^7.2.1
  path_provider: ^2.1.1
```

---

## 🔧 Services à Créer

### 1. BluetoothSocialService
**Fichier** : `lib/core/services/bluetooth_social_service.dart`

**Responsabilités** :
- Scanner les appareils Bluetooth à proximité
- Valider la durée de proximité (2 min minimum)
- Matcher avec contacts téléphone
- Sauvegarder les interactions dans Hive

**Méthodes principales** :
```dart
class BluetoothSocialService {
  // Démarrer le scan
  Future<void> startScanning();

  // Arrêter le scan
  Future<void> stopScanning();

  // Obtenir les appareils détectés
  Stream<List<BluetoothEncounter>> get detectedDevices;

  // Valider une rencontre (durée > 2 min)
  Future<void> validateEncounter(BluetoothEncounter encounter);

  // Matcher avec contacts téléphone
  Future<String?> matchWithContact(String deviceName);

  // Sauvegarder dans Hive
  Future<void> saveInteraction(SocialInteractionModel interaction);
}
```

### 2. ContactsMatchingService
**Fichier** : `lib/core/services/contacts_matching_service.dart`

**Responsabilités** :
- Accéder aux contacts téléphone
- Algorithme de scoring (0-100)
- Cache des correspondances (24h)

**Algorithme de scoring** :
```dart
int calculateMatchScore(String bluetoothName, String contactName) {
  // Exact match
  if (normalize(bluetoothName) == normalize(contactName)) return 100;

  // Bluetooth name contains contact name
  if (normalize(bluetoothName).contains(normalize(contactName))) return 80;

  // Contact name contains Bluetooth name
  if (normalize(contactName).contains(normalize(bluetoothName))) return 70;

  // Word boundary match
  if (hasWordBoundaryMatch(bluetoothName, contactName)) return 60;

  return 0; // No match
}
```

### 3. SocialSensorRepository
**Fichier** : `lib/data/repository/social_sensor_repository.dart`

**Responsabilités** :
- CRUD pour SocialSensorDataModel
- CRUD pour SocialInteractionModel
- Statistiques (nombre d'interactions, durées, etc.)

---

## 🎨 UI à Créer

### 1. Social Tab (écran principal)
**Fichier** : `lib/presentation/screens/social/social_tab.dart`

**Sections** :
```
┌─────────────────────────────────────┐
│ 👥 Capteur Social                   │
├─────────────────────────────────────┤
│                                     │
│ 📊 Aujourd'hui                      │
│ ┌─────────────────────────────────┐ │
│ │ 3 interactions détectées        │ │
│ │ 45 minutes total                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🎯 Objectif : 5 interactions/jour   │
│ Progress: ████░░ 60%                │
│                                     │
│ 📡 Scanner Bluetooth                │
│ ┌─────────────────────────────────┐ │
│ │  [▶️ Démarrer le scan]          │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📜 Historique des rencontres        │
│ ┌─────────────────────────────────┐ │
│ │ 👤 John Doe                     │ │
│ │    3 rencontres | 14:30         │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 👤 Marie Martin                 │ │
│ │    1 rencontre | 09:15          │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### 2. Scanning Screen
**Fichier** : `lib/presentation/screens/social/scanning_screen.dart`

**Animation de scan** :
```
┌─────────────────────────────────────┐
│ 📡 Scan en cours...                 │
├─────────────────────────────────────┤
│                                     │
│       ⚪️ ⚪️ ⚪️                       │
│      ⚪️  📱  ⚪️                      │
│       ⚪️ ⚪️ ⚪️                       │
│                                     │
│ Recherche d'appareils Bluetooth... │
│                                     │
│ Appareils détectés : 5              │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📱 iPhone de John               │ │
│ │    Validation en cours... 1:30  │ │
│ └─────────────────────────────────┘ │
│                                     │
│        [⏸️ Arrêter le scan]         │
│                                     │
└─────────────────────────────────────┘
```

### 3. Contact Details Screen
**Fichier** : `lib/presentation/screens/social/contact_details_screen.dart`

**Détails d'un contact** :
```
┌─────────────────────────────────────┐
│ ← 👤 John Doe                       │
├─────────────────────────────────────┤
│                                     │
│ 📊 Statistiques                     │
│ ┌─────────────────────────────────┐ │
│ │ Total rencontres : 12           │ │
│ │ Première rencontre : 15/01/2025 │ │
│ │ Dernière rencontre : 20/01/2025 │ │
│ │ Durée moyenne : 25 min          │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📅 Historique                       │
│ ┌─────────────────────────────────┐ │
│ │ 20 Jan 2025 - 14:30 (30 min)   │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 19 Jan 2025 - 09:15 (20 min)   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🔧 Informations techniques          │
│ MAC: AA:BB:CC:DD:EE:FF             │
│                                     │
└─────────────────────────────────────┘
```

---

## 🔐 Permissions Nécessaires

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>

<!-- Location (requis pour Bluetooth scan) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Contacts -->
<uses-permission android:name="android.permission.READ_CONTACTS"/>
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>HealthSync utilise Bluetooth pour détecter les interactions sociales</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>La localisation est requise pour le scan Bluetooth</string>
<key>NSContactsUsageDescription</key>
<string>HealthSync accède à vos contacts pour identifier vos interactions</string>
```

---

## 🔄 Flux de Données

### 1. Initialisation
```
User active le capteur Social
    ↓
Demande permissions (Bluetooth, Location, Contacts)
    ↓
Si accordées :
  - Charger SocialSensorDataModel
  - Initialiser BluetoothSocialService
  - Afficher Social Tab
```

### 2. Scan Bluetooth
```
User clique "Démarrer le scan"
    ↓
BluetoothSocialService.startScanning()
    ↓
Pour chaque appareil détecté :
  1. Créer BluetoothEncounter (firstSeen = now)
  2. Mettre à jour lastSeen toutes les 5 secondes
  3. Si (lastSeen - firstSeen) > 2 minutes :
     - Marquer comme validé
     - Matcher avec contacts téléphone
     - Créer SocialInteractionModel
     - Sauvegarder dans Hive
    ↓
Afficher dans l'UI en temps réel
```

### 3. Sauvegarde et Statistiques
```
BluetoothEncounter validé
    ↓
ContactsMatchingService.matchWithContact()
    ↓
Si match trouvé :
  - Créer SocialInteractionModel
    ↓
SocialSensorRepository.saveInteraction()
    ↓
Mise à jour statistiques :
  - Compteur interactions du jour
  - Durée totale
  - Progression objectif
    ↓
Affichage dans Social Tab
```

---

## 📤 Export vers MCP

### Format JSON enrichi
```json
{
  "sensor_type": "social",
  "status": "active",
  "config": {
    "target_interactions_per_day": 5,
    "detection_method": "bluetooth",
    "min_duration_seconds": 120
  },
  "data_summary": {
    "total_interactions": 45,
    "unique_contacts": 12,
    "date_range": {
      "start": "2025-01-01",
      "end": "2025-01-20"
    },
    "avg_duration_minutes": 25,
    "most_frequent_contact": "John Doe"
  },
  "interactions": [
    {
      "id": "interaction_001",
      "contact_name": "John Doe",
      "mac_address": "AA:BB:CC:DD:EE:FF",
      "first_encounter": "2025-01-15T14:30:00Z",
      "last_encounter": "2025-01-20T14:30:00Z",
      "encounter_count": 12,
      "total_duration_minutes": 300,
      "detection_method": "bluetooth",
      "validation_status": "validated"
    }
  ]
}
```

---

## 🚀 Plan d'Implémentation

### Phase 1 : Setup (1-2h)
- [ ] Ajouter dépendances dans pubspec.yaml
- [ ] Configurer permissions Android/iOS
- [ ] Mettre à jour les adaptateurs Hive (typeId 20+)

### Phase 2 : Modèles (30min)
- [ ] Adapter SocialInteractionModel pour Bluetooth
- [ ] Créer BluetoothEncounter
- [ ] Générer adaptateurs Hive

### Phase 3 : Services (3-4h)
- [ ] Créer BluetoothSocialService
- [ ] Créer ContactsMatchingService
- [ ] Créer SocialSensorRepository
- [ ] Tests unitaires basiques

### Phase 4 : UI (2-3h)
- [ ] Social Tab (écran principal)
- [ ] Scanning Screen (animation)
- [ ] Contact Details Screen
- [ ] Intégration dans CentralHubScreen

### Phase 5 : Tests & Polish (1-2h)
- [ ] Tests sur appareil réel (Bluetooth requis)
- [ ] Gestion des erreurs
- [ ] UX polish (loading states, animations)
- [ ] Documentation utilisateur

**Temps total estimé** : 8-12 heures

---

## ⚠️ Limitations & Considérations

### Limitations Techniques
1. **Classic Bluetooth uniquement** : Pas de BLE (Bluetooth Low Energy)
2. **Foreground seulement** : Pas de scan en arrière-plan
3. **Android principal** : Support iOS limité
4. **Permissions strictes** : Location requise pour Bluetooth scan

### Considérations de Confidentialité
1. **Données locales uniquement** : Aucun envoi automatique
2. **Anonymisation MAC** : Hash des adresses MAC avant export MCP
3. **Consent utilisateur** : Demande explicite de permissions
4. **Transparence** : Expliquer pourquoi chaque permission est requise

### Alternatives Futures
- **BLE Beacons** : Pour détection plus fine
- **WiFi Direct** : Alternative au Bluetooth
- **NFC** : Pour interactions très proches
- **Saisie manuelle** : Fallback si Bluetooth indisponible

---

## 📚 Ressources

### Documentation
- Flutter Bluetooth Serial : https://pub.dev/packages/flutter_bluetooth_serial
- Flutter Contacts : https://pub.dev/packages/flutter_contacts
- Permission Handler : https://pub.dev/packages/permission_handler

### Repo Source
- Bluetooth Tracker : https://github.com/saidoubari1/bluetooth-tracker

### Articles pertinents
- Bluetooth Proximity Detection : [Best Practices]
- Privacy in Social Tracking Apps : [Guidelines]

---

## ✅ Checklist de Validation

Avant de déployer le capteur Social :

- [ ] Scan Bluetooth fonctionne
- [ ] Matching contacts opérationnel (score > 60)
- [ ] Validation temporelle (2 min minimum)
- [ ] Sauvegarde Hive persistante
- [ ] UI responsive et intuitive
- [ ] Permissions gérées correctement
- [ ] Pas de crash sur erreurs Bluetooth
- [ ] Export MCP formaté correctement
- [ ] Tests sur 2+ appareils réels
- [ ] Documentation utilisateur écrite

---

## 🎯 Objectif Final

Intégrer le capteur Social dans HealthSync pour permettre un tracking automatique et non-intrusif des interactions sociales via Bluetooth, tout en respectant la vie privée et en maintenant la cohérence avec l'architecture multi-capteurs existante.

**Résultat attendu** : Un capteur Social fonctionnel, activable depuis le Hub Central, collectant des données enrichies pour analyse MCP.
