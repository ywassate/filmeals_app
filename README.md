# HealthSync (FitMeals App)

A comprehensive Flutter health and wellness tracking application that acts as a centralized hub for multi-sensor health data collection.

## Overview

HealthSync collects data from multiple health sensors and serves as a lightweight data collector for server-side AI analysis via MCP (Model Context Protocol).

### Core Philosophy
- **App** = Lightweight data collector with basic local calculations
- **AI intelligence** = Delegated to backend MCP server
- **Modular architecture** = Independent sensor activation

## Features

### 1. Meals Tracking
- Log meals with calories and macronutrients (protein, carbs, fat)
- Spoonacular API integration for recipe search and nutrition data
- Daily calorie goal tracking
- Meal type filtering (breakfast, lunch, dinner, snack)

### 2. Sleep Tracking
- Sleep pattern monitoring
- Sleep quality assessment
- Duration tracking

### 3. Location/GPS
- Activity and movement tracking
- Steps and distance monitoring

### 4. Bluetooth Social Sensor

Tracks social interactions by detecting nearby Bluetooth devices and matching them to phone contacts.

#### How It Works

1. **Bluetooth Scanning**: Performs multi-pass scanning (9 scans × 10 seconds) to detect nearby devices
2. **Duration Validation**: Only validates devices present for ≥2 minutes (configurable)
3. **Contact Matching**: Uses a 4-rule scoring algorithm to match device names to contacts:
   - Rule 1: Exact match (score 100)
   - Rule 2: Bluetooth name contains contact name (score 80+)
   - Rule 3: Contact name contains Bluetooth name (score 70+)
   - Rule 4: Word boundary match on first/last name (score 60+)
4. **Persistence**: Stores validated encounters with encounter count tracking

#### Features
- Real-time scan progress display
- Permission handling for Bluetooth and Contacts
- Contact list with encounter history
- Device name and MAC address tracking
- Cache optimization for battery efficiency

#### Permissions Required (Android)
```xml
<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>

<!-- Location (required for Bluetooth scanning) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Contacts -->
<uses-permission android:name="android.permission.READ_CONTACTS"/>
```

#### Files Structure
```
lib/core/services/
├── bluetooth_service.dart         # Core scanning logic with duration validation
├── contacts_matching_service.dart # 4-rule contact matching algorithm
├── permission_service.dart        # Permission handling

lib/data/models/
└── social_sensor_data_model.dart  # BluetoothContactModel (Hive typeId: 20)

lib/presentation/screens/hub/tabs/
└── social_tab.dart                # Bluetooth scanner UI
```

## Architecture

### Data Layer
- **Hive** for local persistence (offline-first)
- Repository pattern for data access
- Centralized user data model

### Service Layer
- `LocalStorageService` - Hive initialization and box management
- `SpoonacularService` - Nutrition API integration
- `BluetoothService` - Bluetooth scanning and contact matching
- `PermissionService` - Runtime permission handling

### Presentation Layer
- Material Design 3 with minimalist black/white/gray theme
- 5-tab bottom navigation (Home, Meals, Sleep, Location, Social)
- Google Fonts (Poppins)

## Dependencies

```yaml
dependencies:
  # Core
  flutter_sdk: ^3.9.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # UI
  google_fonts: ^6.2.1
  smooth_page_indicator: ^1.2.0+3

  # Utilities
  uuid: ^4.5.1
  intl: ^0.19.0
  http: ^1.2.0
  path_provider: ^2.1.1

  # Bluetooth Social Sensor
  flutter_bluetooth_serial: ^0.4.0
  flutter_contacts: ^1.1.9
  permission_handler: ^11.0.1
  share_plus: ^7.2.1
```

## Getting Started

### Prerequisites
- Flutter SDK ^3.9.2
- Android SDK 21+ (for Bluetooth features)
- Android device with Bluetooth (emulator won't work for Bluetooth)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd filmeals_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Generate Hive adapters
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Run the app
```bash
flutter run
```

### Build APK

```bash
flutter build apk --debug
# or for release
flutter build apk --release
```

## Usage

### Bluetooth Social Sensor

1. Navigate to the **Social** tab
2. Grant **Bluetooth** and **Contacts** permissions when prompted
3. Tap **"Lancer un scan"** to start scanning
4. The scan takes ~2:20 minutes to complete
5. Devices matching your contacts (present ≥2 min) will be validated and saved
6. View your encounter history in the contacts list

### Configuration

You can adjust the minimum duration in `BluetoothService`:
```dart
BluetoothService.instance.setMinimumDuration(120); // 120 seconds = 2 minutes
```

## Project Structure

```
lib/
├── core/
│   ├── services/           # Business logic services
│   │   ├── local_storage_service.dart
│   │   ├── spoonacular_service.dart
│   │   ├── bluetooth_service.dart
│   │   ├── contacts_matching_service.dart
│   │   ├── permission_service.dart
│   │   └── mcp_export_service.dart
│   └── theme/
│       └── app_theme.dart
├── data/
│   ├── models/             # Hive-serializable data models
│   │   ├── central_data_model.dart
│   │   ├── meal_model.dart
│   │   ├── social_sensor_data_model.dart
│   │   ├── sleep_sensor_data_model.dart
│   │   └── location_sensor_data_model.dart
│   └── repository/         # Data access layer
│       ├── central_data_repository.dart
│       ├── meal_repository.dart
│       └── user_repository.dart
└── presentation/
    └── screens/
        ├── hub/            # Main navigation hub
        │   ├── main_hub_screen.dart
        │   └── tabs/
        │       ├── home_tab.dart
        │       ├── meals_tab.dart
        │       ├── sleep_tab.dart
        │       ├── social_tab.dart
        │       └── location_tab.dart
        ├── meals/          # Meal-specific screens
        ├── home/           # Home screen variants
        └── onboarding/     # User setup flow
```

## Contributing

This is a collaborative project. Each team member is responsible for their sensor module:
- **Meals Sensor** - Spoonacular API integration
- **Sleep Sensor** - Sleep tracking
- **Location Sensor** - GPS/activity tracking
- **Social Sensor** - Bluetooth contact detection

When integrating your module:
1. Do NOT modify `main_hub_screen.dart` structure
2. Add your dependencies to `pubspec.yaml`
3. Register Hive adapters in `local_storage_service.dart`
4. Create your tab in `lib/presentation/screens/hub/tabs/`

## License

This project is private and not published to pub.dev.
