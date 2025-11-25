# Configuration des Permissions GPS

## ⚠️ IMPORTANT : Permissions à ajouter manuellement

### 📱 Android (AndroidManifest.xml)

Ajoutez ces permissions dans `android/app/src/main/AndroidManifest.xml` **AVANT** la balise `<application>` :

```xml
<!-- GPS and Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Activity recognition for step counter -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Keep device awake during tracking -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### 🍎 iOS (Info.plist)

Ajoutez ces clés dans `ios/Runner/Info.plist` :

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nous avons besoin d'accéder à votre position pour tracker vos activités physiques (marche, course, vélo).</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Nous avons besoin d'accéder à votre position en arrière-plan pour continuer le tracking pendant vos activités.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Nous utilisons votre position pour enregistrer vos trajets et activités physiques.</string>

<key>NSMotionUsageDescription</key>
<string>Nous utilisons le capteur de mouvement pour compter vos pas pendant les activités.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
</array>
```

## 📝 Étapes après configuration

1. Lancer `flutter pub get`
2. Lancer `flutter pub run build_runner build` pour générer les adapters Hive
3. Tester sur un appareil physique (le GPS ne fonctionne pas sur simulateur)

## ✅ Fonctionnalités implémentées

- ✅ Tracking GPS en temps réel
- ✅ Détection automatique du type d'activité (marche/course/vélo/transport)
- ✅ Compteur de pas
- ✅ Carte interactive avec trajectoire
- ✅ Notifications de confirmation après activité
- ✅ Historique des activités
- ✅ Export MCP avec profil d'activité physique complet
