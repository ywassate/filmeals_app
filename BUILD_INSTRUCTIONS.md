# 🚀 Instructions de Build - Filmeals App avec GPS Tracking

## 📦 1. Installation des dépendances

```bash
flutter pub get
```

## 🔨 2. Génération des adapters Hive

La fonctionnalité GPS utilise de nouveaux modèles Hive qui nécessitent la génération d'adapters :

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Cette commande va générer :
- `location_sensor_data_model.g.dart`
- Les adapters pour `LocationRecordModel`, `LocationPoint`, `ActivityType`

## ⚙️ 3. Configuration des permissions

### Android

Éditez `android/app/src/main/AndroidManifest.xml` et ajoutez les permissions GPS **AVANT** `<application>` :

```xml
<!-- GPS and Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Step counter -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Tracking -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### iOS

Éditez `ios/Runner/Info.plist` et ajoutez :

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nous avons besoin d'accéder à votre position pour tracker vos activités physiques.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Nous avons besoin d'accéder à votre position en arrière-plan pour continuer le tracking.</string>

<key>NSMotionUsageDescription</key>
<string>Nous utilisons le capteur de mouvement pour compter vos pas.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

## 🏃 4. Build et lancement

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Build release
flutter build apk --release
flutter build ios --release
```

## ⚠️ Important

- Le GPS ne fonctionne **pas** sur simulateur/émulateur
- Testez sur un **appareil physique**
- Les permissions GPS sont demandées au runtime

## 📱 Fonctionnalités GPS disponibles

✅ **Tracking en temps réel** avec carte interactive
✅ **Détection automatique** : marche, course, vélo, transport
✅ **Compteur de pas** intégré
✅ **Notification après activité** pour confirmation
✅ **Historique complet** avec statistiques
✅ **Export MCP** : profil d'activité physique détaillé

## 🐛 Troubleshooting

### Erreur "MissingPluginException"
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### GPS ne démarre pas
- Vérifiez les permissions dans AndroidManifest.xml
- Vérifiez que le GPS est activé sur l'appareil
- Testez sur appareil physique (pas simulateur)

### Hive errors
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📊 Structure de l'export MCP

L'export inclut maintenant :
```json
{
  "physical_activities": [...],
  "activity_profile": {
    "activity_level": "moderately_active",
    "activity_patterns": {
      "walking": {...},
      "running": {...},
      "cycling": {...}
    },
    "health_metrics": {
      "total_calories_burned": 12450,
      "total_distance_km": 145.3
    }
  }
}
```
