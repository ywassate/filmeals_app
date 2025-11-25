import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart' as models;

/// Service de tracking GPS en temps réel
class GpsTrackingService {
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<StepCount>? _stepCountStreamSubscription;

  final List<models.LocationPoint> _routePoints = [];
  Position? _lastPosition;
  DateTime? _startTime;
  int _stepCount = 0;
  int _initialStepCount = 0;

  bool _isTracking = false;

  // Callbacks
  Function(models.LocationPoint)? onLocationUpdate;
  Function(double distance, double speed)? onStatsUpdate;
  Function(int steps)? onStepUpdate;

  bool get isTracking => _isTracking;
  List<models.LocationPoint> get routePoints => List.unmodifiable(_routePoints);
  int get stepCount => _stepCount - _initialStepCount;

  /// Vérifie et demande les permissions de localisation
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Démarre le tracking GPS
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return false;

    _isTracking = true;
    _startTime = DateTime.now();
    _routePoints.clear();
    _lastPosition = null;

    // Démarrer le compteur de pas
    _startStepCounter();

    // Configuration du stream GPS
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Mise à jour tous les 10 mètres
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        print('GPS Error: $error');
      },
    );

    return true;
  }

  /// Démarre le compteur de pas
  void _startStepCounter() {
    try {
      _stepCountStreamSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (_initialStepCount == 0) {
            _initialStepCount = event.steps;
          }
          _stepCount = event.steps;
          onStepUpdate?.call(stepCount);
        },
        onError: (error) {
          print('Step Counter Error: $error');
        },
      );
    } catch (e) {
      print('Pedometer not available: $e');
    }
  }

  /// Callback appelé à chaque mise à jour GPS
  void _onPositionUpdate(Position position) {
    final locationPoint = models.LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );

    _routePoints.add(locationPoint);
    onLocationUpdate?.call(locationPoint);

    // Calculer la distance et la vitesse
    if (_lastPosition != null) {
      final distance = getTotalDistance();
      final speed = position.speed * 3.6; // m/s vers km/h
      onStatsUpdate?.call(distance, speed);
    }

    _lastPosition = position;
  }

  /// Arrête le tracking GPS
  Future<models.LocationRecordModel?> stopTracking(String userId) async {
    if (!_isTracking) return null;

    _isTracking = false;
    await _positionStreamSubscription?.cancel();
    await _stepCountStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _stepCountStreamSubscription = null;

    if (_routePoints.isEmpty || _startTime == null) {
      return null;
    }

    final endTime = DateTime.now();
    final distance = getTotalDistance();

    // Ne pas enregistrer les activités trop courtes
    if (distance < 0.1) {
      _resetTracking();
      return null;
    }

    final record = models.LocationRecordModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      startTime: _startTime!,
      endTime: endTime,
      distanceKm: distance,
      stepsCount: stepCount,
      activityType: models.ActivityType.other, // Sera détecté plus tard
      route: List.from(_routePoints),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _resetTracking();
    return record;
  }

  /// Remet à zéro le tracking
  void _resetTracking() {
    _routePoints.clear();
    _lastPosition = null;
    _startTime = null;
    _stepCount = 0;
    _initialStepCount = 0;
  }

  /// Calcule la distance totale parcourue en km
  double getTotalDistance() {
    if (_routePoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      totalDistance += _calculateDistance(
        _routePoints[i].latitude,
        _routePoints[i].longitude,
        _routePoints[i + 1].latitude,
        _routePoints[i + 1].longitude,
      );
    }

    return totalDistance;
  }

  /// Calcule la vitesse moyenne en km/h
  double getAverageSpeed() {
    if (_startTime == null || _routePoints.isEmpty) return 0.0;

    final duration = DateTime.now().difference(_startTime!).inSeconds;
    if (duration == 0) return 0.0;

    final distance = getTotalDistance();
    return (distance / duration) * 3600; // km/h
  }

  /// Calcule la durée écoulée en minutes
  int getDuration() {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inMinutes;
  }

  /// Calcule la distance entre deux points GPS (formule Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Rayon de la Terre en km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Nettoie les ressources
  void dispose() {
    _positionStreamSubscription?.cancel();
    _stepCountStreamSubscription?.cancel();
  }
}
