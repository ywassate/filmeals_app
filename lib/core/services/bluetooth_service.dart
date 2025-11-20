import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:filmeals_app/data/models/social_sensor_data_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/core/services/contacts_matching_service.dart';

/// Classe pour tracker les détections temporaires
class TemporaryDetection {
  final String address;
  final String name;
  final DateTime firstSeen;
  DateTime lastSeen;

  TemporaryDetection({
    required this.address,
    required this.name,
    required this.firstSeen,
    required this.lastSeen,
  });

  Duration get duration => lastSeen.difference(firstSeen);

  bool isStillPresent(int maxSecondsSinceLastSeen) {
    final now = DateTime.now();
    return now.difference(lastSeen).inSeconds <= maxSecondsSinceLastSeen;
  }

  @override
  String toString() {
    return 'Detection: $name ($address) - ${duration.inMinutes}min ${duration.inSeconds % 60}s';
  }
}

/// Service de gestion du Bluetooth avec tracking temporel des appareils
///
/// ARCHITECTURE:
/// 1. Détection rapide de TOUS les devices (sans blocage)
/// 2. Filtrage par contacts APRÈS le scan (pour ne pas ralentir)
/// 3. Validation uniquement des devices présents ≥ minimumDurationSeconds
/// 4. Cache des résultats de matching pour économiser la batterie
class BluetoothService {
  static final BluetoothService instance = BluetoothService._init();

  BluetoothService._init();

  bool _isScanning = false;
  LocalStorageService? _storageService;
  Timer? _continuousScanTimer;
  Function(int, int, int)? _onProgressCallback;

  // === Tracking temporel ===
  // Durée minimum: 5 minutes (300 secondes)
  int minimumDurationSeconds = 300;

  Map<String, TemporaryDetection> _temporaryDetections = {};
  Set<String> _alreadyFilteredAddresses = {};

  // === Cache pour optimisation batterie ===
  Map<String, String?> _contactMatchCache = {};
  Map<String, DateTime> _cacheTimestamp = {};
  static const Duration _cacheDuration = Duration(hours: 24);

  bool get isScanning => _isScanning;

  // Getters pour l'état actuel
  int get currentTrackedDevices => _temporaryDetections.length;
  int get currentPendingCount => _getPendingValidCount();
  int get currentValidatedCount => getAllContacts().length;

  /// Initialiser avec le storage service
  void init(LocalStorageService storageService) {
    _storageService = storageService;
  }

  void setMinimumDuration(int seconds) {
    minimumDurationSeconds = seconds;
    print('⏱️ Durée minimum: ${seconds}s (${seconds ~/ 60}min)');
  }

  void _cleanExpiredCache() {
    final now = DateTime.now();
    _cacheTimestamp.removeWhere((deviceName, timestamp) {
      bool expired = now.difference(timestamp) > _cacheDuration;
      if (expired) {
        _contactMatchCache.remove(deviceName);
      }
      return expired;
    });
  }

  void clearContactCache() {
    _contactMatchCache.clear();
    _cacheTimestamp.clear();
    print('🗑️ Cache contacts vidé');
  }

  Future<String?> _checkContactWithCache(String deviceName) async {
    _cleanExpiredCache();

    if (_contactMatchCache.containsKey(deviceName)) {
      return _contactMatchCache[deviceName];
    }

    final matchedContact = await ContactsMatchingService.instance.findMatchingContact(deviceName);

    _contactMatchCache[deviceName] = matchedContact;
    _cacheTimestamp[deviceName] = DateTime.now();

    return matchedContact;
  }

  List<TemporaryDetection> getPendingDetections() {
    return _temporaryDetections.values.toList();
  }

  int getPendingCount() {
    return _temporaryDetections.length;
  }

  Map<String, int> getCacheStats() {
    return {
      'total_entries': _contactMatchCache.length,
      'matches': _contactMatchCache.values.where((v) => v != null).length,
      'non_matches': _contactMatchCache.values.where((v) => v == null).length,
    };
  }

  /// Arrêter le scan continu
  Future<void> stopScan() async {
    try {
      _continuousScanTimer?.cancel();
      _continuousScanTimer = null;
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      _isScanning = false;
      print('⏹️ Scan continu arrêté');
    } catch (e) {
      print('❌ Erreur arrêt scan: $e');
    }
  }

  /// Démarrer le scan continu 24/7 - MÉTHODE PRINCIPALE
  ///
  /// Scan toutes les 5 minutes en continu jusqu'à stopScan()
  /// Valide uniquement les devices présents ≥ 5 minutes
  Future<void> startContinuousScan({
    Function(int, int, int)? onProgress,
  }) async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _onProgressCallback = onProgress; // Sauvegarder le callback
      _temporaryDetections.clear();
      _alreadyFilteredAddresses.clear();

      print('🔍 Démarrage du scan continu (intervalle: 5min, validation: ≥5min)');
      print('⚠️ Gardez l\'application ouverte pour un scan continu');

      // Premier scan immédiat
      await _performScanCycle(_onProgressCallback);

      // Configurer le scan périodique toutes les 5 minutes
      _continuousScanTimer = Timer.periodic(
        const Duration(minutes: 5),
        (timer) async {
          if (_isScanning) {
            await _performScanCycle(_onProgressCallback);
          } else {
            timer.cancel();
          }
        },
      );

    } catch (e) {
      print('❌ Erreur scan continu: $e');
      _isScanning = false;
      rethrow;
    }
  }

  /// Réenregistrer un callback pour recevoir les updates
  void setProgressCallback(Function(int, int, int)? callback) {
    _onProgressCallback = callback;
  }

  /// Effectuer un cycle de scan complet
  Future<void> _performScanCycle(Function(int, int, int)? onProgress) async {
    try {
      print('📡 Cycle de scan en cours...');

      // Effectuer le scan
      await _performSingleScanForTracking();

      // Filtrer par contacts
      if (_alreadyFilteredAddresses.isEmpty) {
        await _filterByContacts();
      } else {
        await _filterNewDevicesByContacts();
      }

      // Valider les détections qui ont atteint la durée minimum (5 min)
      int validated = await _validateDetections();

      // Notifier l'UI
      if (onProgress != null) {
        onProgress(
          _temporaryDetections.length,
          _getPendingValidCount(),
          validated,
        );
      }

      // Nettoyer les devices fantômes (non vus depuis 10 minutes)
      _cleanupGhostDevices();

      print('✅ Cycle terminé: $_temporaryDetections.length devices trackés, $validated validés');

    } catch (e) {
      print('❌ Erreur cycle scan: $e');
    }
  }

  /// Nettoyer les devices qui ne sont plus présents
  void _cleanupGhostDevices() {
    final now = DateTime.now();
    _temporaryDetections.removeWhere((address, detection) {
      // Supprimer si non vu depuis 10 minutes
      bool isExpired = now.difference(detection.lastSeen).inMinutes >= 10;
      if (isExpired) {
        _alreadyFilteredAddresses.remove(address);
        print('🧹 Nettoyage: ${detection.name} ($address) non vu depuis 10min');
      }
      return isExpired;
    });
  }

  Future<void> _performSingleScanForTracking() async {
    try {
      Set<String> processedAddresses = {};

      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled == null || !isEnabled) {
        throw Exception('Bluetooth désactivé');
      }

      final discoveryCompleter = Completer<void>();

      FlutterBluetoothSerial.instance.startDiscovery().listen(
        (result) {
          if (!processedAddresses.contains(result.device.address)) {
            processedAddresses.add(result.device.address);
            String deviceName = result.device.name ?? 'Inconnu';
            _trackDevice(result.device.address, deviceName);
          }
        },
        onDone: () => discoveryCompleter.complete(),
      );

      await Future.any([
        discoveryCompleter.future,
        Future.delayed(Duration(seconds: 10)),
      ]);

      await FlutterBluetoothSerial.instance.cancelDiscovery();

    } catch (e) {
      print('❌ Erreur scan unique: $e');
    }
  }

  void _trackDevice(String address, String name) {
    final now = DateTime.now();

    if (_temporaryDetections.containsKey(address)) {
      var detection = _temporaryDetections[address]!;
      detection.lastSeen = now;
    } else {
      _temporaryDetections[address] = TemporaryDetection(
        address: address,
        name: name,
        firstSeen: now,
        lastSeen: now,
      );
    }
  }

  Future<void> _filterByContacts() async {
    final detectionsToCheck = Map<String, TemporaryDetection>.from(_temporaryDetections);

    for (var entry in detectionsToCheck.entries) {
      final detection = entry.value;
      final matchedContactName = await _checkContactWithCache(detection.name);

      if (matchedContactName == null) {
        _temporaryDetections.remove(entry.key);
      } else {
        _alreadyFilteredAddresses.add(entry.key);
      }
    }
  }

  Future<void> _filterNewDevicesByContacts() async {
    final newDevices = _temporaryDetections.entries
        .where((entry) => !_alreadyFilteredAddresses.contains(entry.key))
        .toList();

    if (newDevices.isEmpty) return;

    for (var entry in newDevices) {
      final detection = entry.value;
      final matchedContactName = await _checkContactWithCache(detection.name);

      if (matchedContactName == null) {
        _temporaryDetections.remove(entry.key);
      } else {
        _alreadyFilteredAddresses.add(entry.key);
      }
    }
  }

  Future<int> _validateDetections() async {
    int validated = 0;
    final detectionsToCheck = Map<String, TemporaryDetection>.from(_temporaryDetections);

    for (var entry in detectionsToCheck.entries) {
      final detection = entry.value;
      int durationSeconds = detection.duration.inSeconds;

      if (durationSeconds >= minimumDurationSeconds) {
        bool wasMatched = await _processDevice(detection.name, detection.address);
        if (wasMatched) validated++;

        _temporaryDetections.remove(entry.key);
        _alreadyFilteredAddresses.remove(entry.key);
      }
    }

    return validated;
  }

  int _getPendingValidCount() {
    return _temporaryDetections.values
        .where((d) => d.duration.inSeconds < minimumDurationSeconds)
        .length;
  }

  /// Enregistrer un device validé en base de données Hive
  Future<bool> _processDevice(String bluetoothName, String macAddress) async {
    try {
      if (_storageService == null) {
        print('❌ StorageService non initialisé');
        return false;
      }

      final matchedContactName = await ContactsMatchingService.instance
          .findMatchingContact(bluetoothName);

      if (matchedContactName == null) {
        return false;
      }

      final box = _storageService!.bluetoothContactsBox;
      final existingContact = box.get(macAddress);

      final now = DateTime.now();

      if (existingContact != null) {
        final updatedContact = BluetoothContactModel(
          macAddress: macAddress,
          contactName: matchedContactName,
          deviceName: bluetoothName,
          firstEncounter: existingContact.firstEncounter,
          lastEncounter: now,
          encounterCount: existingContact.encounterCount + 1,
        );
        await box.put(macAddress, updatedContact);
        print('✅ $matchedContactName enregistré (rencontre #${updatedContact.encounterCount})');
      } else {
        final newContact = BluetoothContactModel(
          macAddress: macAddress,
          contactName: matchedContactName,
          deviceName: bluetoothName,
          firstEncounter: now,
          lastEncounter: now,
          encounterCount: 1,
        );
        await box.put(macAddress, newContact);
        print('✅ $matchedContactName enregistré (nouvelle rencontre)');
      }

      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement: $e');
      return false;
    }
  }

  /// Récupérer tous les contacts Bluetooth enregistrés
  List<BluetoothContactModel> getAllContacts() {
    if (_storageService == null) return [];

    final box = _storageService!.bluetoothContactsBox;
    final contacts = box.values.toList();

    // Trier par dernière rencontre (plus récent en premier)
    contacts.sort((a, b) => b.lastEncounter.compareTo(a.lastEncounter));

    return contacts;
  }

  /// Supprimer tous les contacts
  Future<void> deleteAllContacts() async {
    if (_storageService == null) return;
    await _storageService!.bluetoothContactsBox.clear();
  }

  /// Supprimer un contact spécifique
  Future<void> deleteContact(String macAddress) async {
    if (_storageService == null) return;
    await _storageService!.bluetoothContactsBox.delete(macAddress);
  }
}
