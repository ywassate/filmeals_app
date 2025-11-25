import 'package:hive/hive.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';

/// Repository pour gérer les données de localisation et activités GPS
class LocationRepository {
  static const String _sensorBoxName = 'location_sensor_data';
  static const String _recordsBoxName = 'location_records';

  Box<LocationSensorDataModel>? _sensorBox;
  Box<LocationRecordModel>? _recordsBox;

  /// Initialise les boxes Hive
  Future<void> initialize() async {
    if (_sensorBox == null || !_sensorBox!.isOpen) {
      _sensorBox = await Hive.openBox<LocationSensorDataModel>(_sensorBoxName);
    }
    if (_recordsBox == null || !_recordsBox!.isOpen) {
      _recordsBox = await Hive.openBox<LocationRecordModel>(_recordsBoxName);
    }
  }

  /// Crée ou met à jour les données du capteur location
  Future<void> saveLocationSensorData(LocationSensorDataModel data) async {
    await initialize();
    await _sensorBox!.put(data.userId, data);
  }

  /// Récupère les données du capteur location pour un utilisateur
  Future<LocationSensorDataModel?> getLocationSensorData(String userId) async {
    await initialize();
    return _sensorBox!.get(userId);
  }

  /// Crée ou met à jour une activité location
  Future<void> saveLocationRecord(LocationRecordModel record) async {
    await initialize();
    await _recordsBox!.put(record.id, record);
  }

  /// Récupère une activité par ID
  Future<LocationRecordModel?> getLocationRecord(String recordId) async {
    await initialize();
    return _recordsBox!.get(recordId);
  }

  /// Récupère toutes les activités d'un utilisateur
  Future<List<LocationRecordModel>> getUserLocationRecords(
    String userId,
  ) async {
    await initialize();
    return _recordsBox!.values
        .where((record) => record.userId == userId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Plus récent d'abord
  }

  /// Récupère les activités d'un utilisateur par type
  Future<List<LocationRecordModel>> getUserLocationRecordsByType(
    String userId,
    ActivityType type,
  ) async {
    await initialize();
    return _recordsBox!.values
        .where((record) =>
            record.userId == userId && record.activityType == type)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Récupère les activités d'un utilisateur dans une période
  Future<List<LocationRecordModel>> getUserLocationRecordsInPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await initialize();
    return _recordsBox!.values
        .where((record) =>
            record.userId == userId &&
            record.startTime.isAfter(startDate) &&
            record.startTime.isBefore(endDate))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Supprime une activité
  Future<void> deleteLocationRecord(String recordId) async {
    await initialize();
    await _recordsBox!.delete(recordId);
  }

  /// Met à jour le type d'activité (après correction utilisateur)
  Future<void> updateActivityType(
    String recordId,
    ActivityType newType,
  ) async {
    await initialize();
    final record = _recordsBox!.get(recordId);
    if (record != null) {
      final updatedRecord = record.copyWith(
        activityType: newType,
        updatedAt: DateTime.now(),
      );
      await _recordsBox!.put(recordId, updatedRecord);
    }
  }

  /// Calcule les statistiques globales pour un utilisateur
  Future<Map<String, dynamic>> getUserActivityStats(String userId) async {
    await initialize();
    final records = await getUserLocationRecords(userId);

    if (records.isEmpty) {
      return {
        'total_activities': 0,
        'total_distance_km': 0.0,
        'total_duration_min': 0,
        'by_type': {},
      };
    }

    final totalDistance =
        records.fold(0.0, (sum, record) => sum + record.distanceKm);
    final totalDuration =
        records.fold(0, (sum, record) => sum + record.durationMinutes);

    // Statistiques par type
    final byType = <String, Map<String, dynamic>>{};
    for (var type in ActivityType.values) {
      final typeRecords = records.where((r) => r.activityType == type).toList();
      if (typeRecords.isNotEmpty) {
        byType[type.toString().split('.').last] = {
          'count': typeRecords.length,
          'total_distance_km':
              typeRecords.fold(0.0, (sum, r) => sum + r.distanceKm),
          'total_duration_min':
              typeRecords.fold(0, (sum, r) => sum + r.durationMinutes),
          'avg_distance_km': typeRecords.fold(0.0, (sum, r) => sum + r.distanceKm) /
              typeRecords.length,
          'avg_duration_min':
              typeRecords.fold(0, (sum, r) => sum + r.durationMinutes) /
                  typeRecords.length,
        };
      }
    }

    return {
      'total_activities': records.length,
      'total_distance_km': totalDistance,
      'total_duration_min': totalDuration,
      'by_type': byType,
    };
  }

  /// Récupère les activités des N derniers jours
  Future<List<LocationRecordModel>> getRecentActivities(
    String userId,
    int days,
  ) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final endDate = DateTime.now();
    return getUserLocationRecordsInPeriod(userId, startDate, endDate);
  }

  /// Nettoie les anciennes activités (> X jours)
  Future<void> cleanOldRecords(int daysToKeep) async {
    await initialize();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final keysToDelete = <String>[];

    for (var record in _recordsBox!.values) {
      if (record.startTime.isBefore(cutoffDate)) {
        keysToDelete.add(record.id);
      }
    }

    for (var key in keysToDelete) {
      await _recordsBox!.delete(key);
    }
  }

  /// Ferme les boxes
  Future<void> close() async {
    await _sensorBox?.close();
    await _recordsBox?.close();
  }
}
