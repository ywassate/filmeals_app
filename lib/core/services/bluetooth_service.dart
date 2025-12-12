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
  // Durée minimum pour valider une rencontre (par défaut: 2 minutes = 120 secondes)
  int minimumDurationSeconds = 120;

  Map<String, TemporaryDetection> _temporaryDetections = {};
  Set<String> _alreadyFilteredAddresses = {};
  Set<String> _alreadyValidatedAddresses = {}; // Adresses déjà validées pour cette session
  Map<String, DateTime> _sessionStartTimes = {}; // Heure de début de chaque session de rencontre

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
  /// Scan toutes les 1 minute en continu jusqu'à stopScan()
  /// Valide uniquement les devices présents ≥ minimumDurationSeconds
  Future<void> startContinuousScan({
    Function(int, int, int)? onProgress,
  }) async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _onProgressCallback = onProgress; // Sauvegarder le callback
      _temporaryDetections.clear();
      _alreadyFilteredAddresses.clear();
      _alreadyValidatedAddresses.clear(); // Reset des validations
      _sessionStartTimes.clear(); // Reset des heures de début

      print('🔍 Démarrage du scan continu (intervalle: 1min, validation: ≥${minimumDurationSeconds}s)');
      print('⚠️ Gardez l\'application ouverte pour un scan continu');

      // Premier scan immédiat
      await _performScanCycle(_onProgressCallback);

      // Configurer le scan périodique toutes les 1 minute
      _continuousScanTimer = Timer.periodic(
        const Duration(minutes: 1),
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

      // Valider les détections qui ont atteint la durée minimum (2 min)
      int validated = await _validateDetections();

      // Notifier l'UI (TOUJOURS, même si validated = 0, pour forcer le refresh)
      if (onProgress != null) {
        onProgress(
          _temporaryDetections.length,
          _getPendingValidCount(),
          validated,
        );
      }

      // Forcer le rechargement de la liste si des devices sont trackés
      if (_temporaryDetections.isNotEmpty && onProgress != null) {
        print('💫 Forcer le rechargement de l\'UI (${_temporaryDetections.length} devices trackés)');
      }

      // Nettoyer les devices fantômes (non vus depuis 2 minutes)
      _cleanupGhostDevices();

      print('✅ Cycle terminé: ${_temporaryDetections.length} devices trackés, $validated validés');

    } catch (e) {
      print('❌ Erreur cycle scan: $e');
    }
  }

  /// Mettre à jour lastEncounter dans Hive quand la personne part
  Future<void> _updateLastEncounterOnDeparture(String macAddress, DateTime lastSeenTime) async {
    try {
      if (_storageService == null) return;

      final box = _storageService!.bluetoothContactsBox;
      final existingContact = box.get(macAddress);

      if (existingContact != null) {
        // Récupérer l'heure de début de cette session
        final sessionStart = _sessionStartTimes[macAddress];

        if (sessionStart != null) {
          // Calculer la durée réelle de cette rencontre
          final duration = lastSeenTime.difference(sessionStart);
          final minutes = duration.inMinutes;
          final seconds = duration.inSeconds % 60;

          // Ajouter la durée à l'historique
          final updatedDurations = List<int>.from(existingContact.encounterDurations)..add(minutes);
          final updatedTotalDuration = existingContact.totalDurationMinutes + minutes;

          // Mettre à jour avec l'heure réelle de fin et les durées
          final updatedContact = existingContact.copyWith(
            lastEncounter: lastSeenTime,
            encounterDurations: updatedDurations,
            totalDurationMinutes: updatedTotalDuration,
          );
          await box.put(macAddress, updatedContact);

          print('⏱️ Durée de la rencontre: ${minutes}min ${seconds}s avec ${existingContact.contactName}');
          print('📊 Début: ${sessionStart.hour}:${sessionStart.minute.toString().padLeft(2, '0')} → Fin: ${lastSeenTime.hour}:${lastSeenTime.minute.toString().padLeft(2, '0')}');
          print('📈 Total cumulé: ${updatedTotalDuration}min (${updatedDurations.length} rencontres enregistrées)');
        }
      }
    } catch (e) {
      print('❌ Erreur mise à jour lastEncounter: $e');
    }
  }

  /// Nettoyer les devices qui ne sont plus présents
  void _cleanupGhostDevices() {
    final now = DateTime.now();
    _temporaryDetections.removeWhere((address, detection) {
      // Supprimer si non vu depuis 2 minutes
      bool isExpired = now.difference(detection.lastSeen).inMinutes >= 2;
      if (isExpired) {
        // Si l'appareil était validé, mettre à jour lastEncounter dans Hive avec l'heure réelle de fin
        if (_alreadyValidatedAddresses.contains(address)) {
          _updateLastEncounterOnDeparture(address, detection.lastSeen);
        }

        _alreadyFilteredAddresses.remove(address);
        _alreadyValidatedAddresses.remove(address); // Oublier la validation
        _sessionStartTimes.remove(address); // Oublier l'heure de début
        print('🧹 Nettoyage: ${detection.name} ($address) non vu depuis 2min - Rencontre terminée');
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
      final totalSeconds = detection.duration.inSeconds;
      print('🔄 Mise à jour: $name - Durée: ${detection.duration.inMinutes}min ${totalSeconds % 60}s (total: ${totalSeconds}s/${minimumDurationSeconds}s requis)');
    } else {
      _temporaryDetections[address] = TemporaryDetection(
        address: address,
        name: name,
        firstSeen: now,
        lastSeen: now,
      );
      _sessionStartTimes[address] = now; // Stocker l'heure de début de cette session
      print('🆕 Nouveau device tracké: $name à ${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _filterByContacts() async {
    final detectionsToCheck = Map<String, TemporaryDetection>.from(_temporaryDetections);

    for (var entry in detectionsToCheck.entries) {
      final detection = entry.value;
      final matchedContactName = await _checkContactWithCache(detection.name);

      if (matchedContactName == null) {
        _temporaryDetections.remove(entry.key);
        _sessionStartTimes.remove(entry.key); // Nettoyer aussi l'heure de début
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
        _sessionStartTimes.remove(entry.key); // Nettoyer aussi l'heure de début
      } else {
        _alreadyFilteredAddresses.add(entry.key);
      }
    }
  }

  Future<int> _validateDetections() async {
    int validated = 0;
    final detectionsToCheck = Map<String, TemporaryDetection>.from(_temporaryDetections);

    print('━━━━━━━━━━ VALIDATION CYCLE ━━━━━━━━━━');
    print('📋 Devices à vérifier: ${detectionsToCheck.length}');

    for (var entry in detectionsToCheck.entries) {
      final detection = entry.value;
      int durationSeconds = detection.duration.inSeconds;

      print('\n🔍 Vérification: ${detection.name}');
      print('   MAC: ${entry.key}');
      print('   Durée: ${durationSeconds}s (min: ${minimumDurationSeconds}s requis)');
      print('   FirstSeen: ${detection.firstSeen.toIso8601String()}');
      print('   LastSeen: ${detection.lastSeen.toIso8601String()}');

      // Vérifier si déjà validé pour cette session de présence continue
      if (_alreadyValidatedAddresses.contains(entry.key)) {
        print('   ⏭️ SKIP : Déjà validé pour cette session');
        continue;
      }

      // Vérifier si dans la liste filtrée
      if (!_alreadyFilteredAddresses.contains(entry.key)) {
        print('   ⚠️ SKIP : Pas dans la liste filtrée (pas de match contact)');
        continue;
      }

      if (durationSeconds >= minimumDurationSeconds) {
        print('   ✅ Durée SUFFISANTE ! Tentative de validation...');
        bool wasMatched = await _processDevice(detection.name, detection.address);
        if (wasMatched) {
          validated++;
          _alreadyValidatedAddresses.add(entry.key); // Marquer comme validé
          print('   🎉 SUCCÈS : Device validé et enregistré dans Hive !');
        } else {
          print('   ❌ ÉCHEC : Validation échouée (matching contact failed)');
        }
      } else {
        int remaining = minimumDurationSeconds - durationSeconds;
        print('   ⏳ En attente : encore ${remaining}s requis');
      }
    }

    print('\n━━━━━━━━━━ RÉSULTAT : ${validated} validés ━━━━━━━━━━\n');
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
      print('   📝 _processDevice() appelé pour: $bluetoothName ($macAddress)');

      if (_storageService == null) {
        print('   ❌ ERREUR : StorageService non initialisé');
        return false;
      }

      // Utiliser le cache pour éviter de re-vérifier le matching
      print('   🔍 Recherche contact match dans cache...');
      final matchedContactName = await _checkContactWithCache(bluetoothName);

      if (matchedContactName == null) {
        print('   ❌ ERREUR : Aucun match trouvé pour "$bluetoothName"');
        print('   💡 Vérifiez que ce nom correspond à un contact dans votre téléphone');
        return false;
      }

      print('   ✅ Contact trouvé : "$matchedContactName"');

      final box = _storageService!.bluetoothContactsBox;
      final existingContact = box.get(macAddress);

      final now = DateTime.now();

      if (existingContact != null) {
        // Contact existant : nouvelle session de rencontre
        print('   📱 Contact EXISTANT trouvé dans Hive');
        print('   🔄 Incrémentation encounterCount: ${existingContact.encounterCount} → ${existingContact.encounterCount + 1}');

        final updatedContact = BluetoothContactModel(
          macAddress: macAddress,
          contactName: matchedContactName,
          deviceName: bluetoothName,
          firstEncounter: existingContact.firstEncounter,
          lastEncounter: now,
          encounterCount: existingContact.encounterCount + 1,
          encounterDurations: existingContact.encounterDurations,
          totalDurationMinutes: existingContact.totalDurationMinutes,
        );
        await box.put(macAddress, updatedContact);
        print('   💾 Contact mis à jour dans Hive');
        print('   ✅ $matchedContactName enregistré (rencontre #${updatedContact.encounterCount})');
      } else {
        // Nouveau contact : première rencontre
        print('   🆕 NOUVEAU contact - Première rencontre');

        // Utiliser l'heure de début de session au lieu de l'heure de validation
        final sessionStart = _sessionStartTimes[macAddress] ?? now;
        print('   🕐 Heure de début: ${sessionStart.hour}:${sessionStart.minute.toString().padLeft(2, '0')}:${sessionStart.second.toString().padLeft(2, '0')}');

        final newContact = BluetoothContactModel(
          macAddress: macAddress,
          contactName: matchedContactName,
          deviceName: bluetoothName,
          firstEncounter: sessionStart, // Heure de début réelle, pas validation
          lastEncounter: sessionStart,  // Sera mis à jour au cleanup
          encounterCount: 1,
          encounterDurations: [], // Pas encore de durée enregistrée
          totalDurationMinutes: 0,
        );
        await box.put(macAddress, newContact);
        print('   💾 Contact enregistré dans Hive');
        print('   ✅ $matchedContactName enregistré (première rencontre)');
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
