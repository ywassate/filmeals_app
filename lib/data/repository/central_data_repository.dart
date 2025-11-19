import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/models/central_data_model.dart';
import 'package:hive/hive.dart';

/// Repository pour gérer les données centrales partagées
class CentralDataRepository {
  final LocalStorageService _storageService;

  CentralDataRepository(this._storageService);

  Box<CentralDataModel> get _box => _storageService.centralDataBox;

  /// Créer ou mettre à jour les données centrales de l'utilisateur
  Future<void> saveCentralData(CentralDataModel centralData) async {
    await _box.put(centralData.id, centralData);
  }

  /// Récupérer les données centrales de l'utilisateur
  CentralDataModel? getCentralData() {
    if (_box.isEmpty) return null;
    // On suppose qu'il n'y a qu'un seul utilisateur pour l'instant
    return _box.values.first;
  }

  /// Récupérer les données centrales par ID
  CentralDataModel? getCentralDataById(String id) {
    return _box.get(id);
  }

  /// Mettre à jour les données centrales
  Future<void> updateCentralData(CentralDataModel centralData) async {
    await _box.put(centralData.id, centralData);
  }

  /// Mettre à jour les capteurs actifs
  Future<void> updateActiveSensors(List<String> sensors) async {
    final currentData = getCentralData();
    if (currentData != null) {
      final updatedData = currentData.copyWith(
        activeSensors: sensors,
        updatedAt: DateTime.now(),
      );
      await saveCentralData(updatedData);
    }
  }

  /// Activer un capteur
  Future<void> activateSensor(String sensorName) async {
    final currentData = getCentralData();
    if (currentData != null) {
      final sensors = List<String>.from(currentData.activeSensors);
      if (!sensors.contains(sensorName)) {
        sensors.add(sensorName);
        await updateActiveSensors(sensors);
      }
    }
  }

  /// Désactiver un capteur
  Future<void> deactivateSensor(String sensorName) async {
    final currentData = getCentralData();
    if (currentData != null) {
      final sensors = List<String>.from(currentData.activeSensors);
      sensors.remove(sensorName);
      await updateActiveSensors(sensors);
    }
  }

  /// Vérifier si un capteur est actif
  bool isSensorActive(String sensorName) {
    final currentData = getCentralData();
    return currentData?.activeSensors.contains(sensorName) ?? false;
  }

  /// Supprimer les données centrales
  Future<void> deleteCentralData(String id) async {
    await _box.delete(id);
  }

  /// Supprimer toutes les données centrales
  Future<void> deleteAll() async {
    await _box.clear();
  }

  /// Vérifier si des données existent
  bool hasData() {
    return _box.isNotEmpty;
  }
}
