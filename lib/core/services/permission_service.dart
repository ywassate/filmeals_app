import 'package:permission_handler/permission_handler.dart';

/// Service de gestion des permissions pour le Bluetooth et les Contacts
class PermissionService {
  /// Vérifier et demander les permissions Bluetooth
  static Future<bool> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    return allGranted;
  }

  /// Vérifier et demander la permission Contacts
  static Future<bool> requestContactsPermission() async {
    PermissionStatus status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Vérifier si les permissions Bluetooth sont accordées
  static Future<bool> hasBluetoothPermissions() async {
    bool bluetoothScan = await Permission.bluetoothScan.isGranted;
    bool bluetoothConnect = await Permission.bluetoothConnect.isGranted;
    bool location = await Permission.locationWhenInUse.isGranted;

    return bluetoothScan && bluetoothConnect && location;
  }

  /// Vérifier si la permission Contacts est accordée
  static Future<bool> hasContactsPermission() async {
    return await Permission.contacts.isGranted;
  }

  /// Ouvrir les paramètres de l'app si permission refusée définitivement
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
