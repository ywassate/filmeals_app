# Bluetooth Continuous Scan - Implementation Notes

## Overview

The Bluetooth Social Sensor has been updated to perform **continuous 24/7 scanning** with realistic timing for detecting social interactions.

## Key Changes

### 1. Timing Modifications

| Parameter | Old Value | New Value | Reason |
|-----------|-----------|-----------|---------|
| **Scan Interval** | 10 seconds | 5 minutes | Realistic meeting detection |
| **Number of Scans** | 9 (fixed) | Infinite (until stopped) | Continuous monitoring |
| **Minimum Duration** | 2 minutes | 5 minutes | Real meeting threshold |
| **Total Duration** | ~2:20 minutes (fixed) | Unlimited (24/7) | Continuous tracking |
| **Ghost Cleanup** | 30 seconds | 10 minutes | Avoid false negatives |

### 2. Scanning Behavior

#### Old Behavior (startScanWithDuration)
```
Start → Scan 1 → Wait 10s → Scan 2 → ... → Scan 9 → Stop
Total: ~2:20 minutes, then stops automatically
```

#### New Behavior (startContinuousScan)
```
Start → Scan 1 → Wait 5min → Scan 2 → Wait 5min → Scan 3 → ...
Continues until user taps "Arrêter le scan continu"
```

### 3. Validation Logic

**Device Lifecycle:**
1. **Detection** - Device detected via Bluetooth scan
2. **Contact Matching** - Device name matched against phone contacts (4-rule algorithm)
3. **Tracking** - Device tracked with firstSeen/lastSeen timestamps
4. **Validation** - After ≥5 minutes of continuous presence, device is validated and saved
5. **Cleanup** - If device not seen for 10 minutes, removed from tracking

**Example Timeline:**
```
00:00 - Person A enters room (device detected)
00:05 - First scan cycle (A is tracked, 5min elapsed)
00:10 - Second scan cycle (A is validated and saved ✓)
00:15 - Third scan cycle (A still present, encounter count incremented)
00:20 - Person A leaves room
00:30 - A not detected in scan, but still in tracking (lastSeen: 00:20)
00:40 - A removed from tracking (10 min since lastSeen)
```

### 4. Code Structure

#### BluetoothService Changes

**New Method:**
```dart
Future<void> startContinuousScan({
  Function(int, int, int)? onProgress,
})
```

**Key Features:**
- Uses `Timer.periodic(Duration(minutes: 5))` for continuous scanning
- Calls `_performScanCycle()` every 5 minutes
- Continues indefinitely until `stopScan()` is called

**New Helper Methods:**
```dart
Future<void> _performScanCycle(...)  // Single scan + validation cycle
void _cleanupGhostDevices()           // Remove stale devices (>10min)
```

#### UI Updates (social_tab.dart)

**Changed Text:**
- "Scan en cours... (~2:20 min)" → "Scan continu actif"
- "Scan toutes les 5 minutes" (new subtitle)
- "en attente (< 2min)" → "en attente (< 5min)"
- "validés (≥ 2min)" → "validés (≥ 5min)"
- "Lancer un scan" → "Démarrer le scan continu"
- "Arrêter le scan" → "Arrêter le scan continu"

**Changed Behavior:**
- Scan doesn't auto-stop after completion
- Progress updates are incremental (validated count accumulates)
- Contacts list refreshes automatically when new contacts are validated

### 5. Important Limitations

#### ⚠️ App Must Remain Open

Flutter **does not support true background services** without native Android code (Kotlin/Java). The continuous scan will **pause** if:
- App is minimized
- Screen is locked
- App is killed by the system

**Workaround for Testing:**
- Keep the app open in the foreground
- Prevent screen from turning off (Settings → Display → Screen timeout)
- Connect device to charger for long-term testing

#### Why Background Service Requires Native Code

Flutter runs in a single Activity, which Android suspends when the app is backgrounded. True background Bluetooth scanning requires:
1. Android `Service` or `WorkManager` (Kotlin/Java)
2. `FOREGROUND_SERVICE` permission with notification
3. Platform channel to communicate with Flutter UI

**This is acceptable for an academic project** where the limitation is documented and testing can be performed with the app in the foreground.

## Testing Recommendations

### Test Scenario 1: Short Meeting (< 5 minutes)
1. Start continuous scan
2. Place another device with Bluetooth enabled nearby
3. Wait 2-3 minutes
4. Move device away
5. **Expected**: Device tracked but NOT validated (duration < 5min)

### Test Scenario 2: Real Meeting (≥ 5 minutes)
1. Start continuous scan
2. Place another device nearby
3. Wait at least 10 minutes (2 scan cycles)
4. **Expected**: Device validated and saved to contacts list

### Test Scenario 3: Multiple Encounters
1. Start continuous scan
2. Device A nearby for 10 minutes → validated
3. Device A leaves
4. Wait 15 minutes
5. Device A returns for 10 minutes
6. **Expected**: Encounter count incremented (device already exists)

### Test Scenario 4: Ghost Device Cleanup
1. Start continuous scan
2. Device detected at 00:00
3. Device leaves at 00:05
4. Wait until 00:15
5. **Expected**: Device removed from tracking (10min cleanup threshold)

## Configuration Options

### Change Minimum Encounter Duration

In `social_tab.dart` line 138:
```dart
BluetoothService.instance.setMinimumDuration(300); // 300s = 5min

// For testing with shorter durations:
BluetoothService.instance.setMinimumDuration(60);  // 1 minute (testing only)
```

### Change Scan Interval

In `bluetooth_service.dart` line 156:
```dart
_continuousScanTimer = Timer.periodic(
  const Duration(minutes: 5),  // Change to 1-10 minutes
  (timer) async { ... }
);
```

### Change Ghost Cleanup Threshold

In `bluetooth_service.dart` line 216:
```dart
bool isExpired = now.difference(detection.lastSeen).inMinutes >= 10;
// Change 10 to desired threshold (minutes)
```

## Performance Considerations

### Battery Impact
- **Scan frequency**: Every 5 minutes (vs. every 10 seconds previously)
- **Expected battery drain**: ~3-5% per hour (much lower than old implementation)
- **Cache optimization**: 24-hour cache reduces redundant contact matching

### Memory Usage
- **Tracked devices**: Stored in `Map<String, TemporaryDetection>` (in-memory)
- **Cleanup**: Automatic removal after 10 minutes of absence
- **Expected memory**: < 1 MB for typical usage (< 100 tracked devices)

### Network Usage
- **Contact matching**: Local operation (no network)
- **Hive storage**: Local database (no network)
- **Expected**: 0 bytes network usage (all local operations)

## Comparison with Original bluetooth_tracker App

| Feature | Original App | Integrated App |
|---------|--------------|----------------|
| Scan Type | Single 2-minute scan | Continuous 24/7 |
| Scan Interval | Manual trigger | Automatic (5 min) |
| Min Duration | 2 minutes | 5 minutes |
| Storage | SQLite | Hive (NoSQL) |
| UI Integration | Standalone app | Social tab in hub |
| Background Support | No | No (Flutter limitation) |

## Future Enhancements (Out of Scope)

If background scanning is required in the future:

1. **Create Android Native Service** (Kotlin)
   ```kotlin
   class BluetoothScanService : Service() {
       override fun onStartCommand(...) {
           // Bluetooth scanning logic
           // Send results to Flutter via MethodChannel
       }
   }
   ```

2. **Add Platform Channel** (Flutter)
   ```dart
   static const platform = MethodChannel('com.example/bluetooth');
   await platform.invokeMethod('startBackgroundScan');
   ```

3. **Update AndroidManifest.xml**
   ```xml
   <service android:name=".BluetoothScanService"
            android:foregroundServiceType="connectedDevice"/>
   ```

This would require significant additional work and is not necessary for an academic demonstration.

## Conclusion

The continuous scanning implementation provides a **realistic simulation** of 24/7 social interaction tracking while working within Flutter's limitations. For academic purposes, the requirement to keep the app open is acceptable and well-documented.
