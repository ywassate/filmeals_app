import 'package:filmeals_app/data/models/location_sensor_data_model.dart';

/// Service de détection automatique du type d'activité
class ActivityDetectionService {
  /// Détecte le type d'activité basé sur les données GPS et de mouvement
  ActivityType detectActivityType({
    required double averageSpeedKmh,
    required double maxSpeedKmh,
    required int stepCount,
    required List<double> speedSamples,
  }) {
    // 1️⃣ TRANSPORT - Vitesse élevée
    if (averageSpeedKmh > 30 || maxSpeedKmh > 40) {
      return ActivityType.driving;
    }

    // 2️⃣ IMMOBILE
    if (averageSpeedKmh < 3) {
      return ActivityType.stationary;
    }

    // 3️⃣ Détecter BUS/TRAM vs VÉLO (15-30 km/h)
    if (averageSpeedKmh >= 15 && averageSpeedKmh <= 30) {
      // Bus/tram : beaucoup d'arrêts complets
      if (_hasFrequentStops(speedSamples)) {
        return ActivityType.driving; // Transport public
      }
      // Vélo : pas de pas détectés
      if (stepCount == 0 || stepCount < 100) {
        return ActivityType.cycling;
      }
    }

    // 4️⃣ VÉLO détecté par vitesse moyenne sans pas
    if (averageSpeedKmh >= 10 && stepCount < 100) {
      return ActivityType.cycling;
    }

    // 5️⃣ MARCHE vs COURSE (avec compteur de pas)
    if (stepCount > 0) {
      if (averageSpeedKmh < 7) {
        return ActivityType.walking;
      }
      if (averageSpeedKmh < 15) {
        return ActivityType.running;
      }
      // Vitesse élevée avec beaucoup de pas = course rapide
      return ActivityType.running;
    }

    // 6️⃣ Par défaut basé sur la vitesse uniquement
    if (averageSpeedKmh < 7) return ActivityType.walking;
    if (averageSpeedKmh < 15) return ActivityType.running;
    if (averageSpeedKmh < 30) return ActivityType.cycling;

    return ActivityType.driving;
  }

  /// Détecte les arrêts fréquents (bus/tram)
  bool _hasFrequentStops(List<double> speedSamples) {
    if (speedSamples.length < 10) return false;

    int stopCount = 0;
    for (int i = 0; i < speedSamples.length - 1; i++) {
      // Arrêt = passage de > 10 km/h à < 3 km/h
      if (speedSamples[i] > 10 && speedSamples[i + 1] < 3) {
        stopCount++;
      }
    }

    // Bus/tram ont beaucoup d'arrêts (> 20% des points)
    return stopCount > (speedSamples.length * 0.2);
  }

  /// Calcule la confiance de la détection (0.0 - 1.0)
  double getDetectionConfidence({
    required ActivityType detectedType,
    required double averageSpeedKmh,
    required int stepCount,
  }) {
    switch (detectedType) {
      case ActivityType.driving:
        // Haute confiance si vitesse très élevée
        if (averageSpeedKmh > 40) return 0.95;
        if (averageSpeedKmh > 30) return 0.85;
        return 0.70;

      case ActivityType.cycling:
        // Haute confiance si vitesse cycliste ET pas de pas
        if (averageSpeedKmh >= 15 && stepCount < 50) return 0.90;
        if (averageSpeedKmh >= 12 && stepCount < 100) return 0.75;
        return 0.60;

      case ActivityType.running:
        // Haute confiance si vitesse course ET beaucoup de pas
        if (averageSpeedKmh >= 8 && stepCount > 1000) return 0.90;
        if (averageSpeedKmh >= 7 && stepCount > 500) return 0.80;
        return 0.65;

      case ActivityType.walking:
        // Haute confiance si vitesse marche ET pas détectés
        if (averageSpeedKmh < 6 && stepCount > 500) return 0.90;
        if (averageSpeedKmh < 7 && stepCount > 200) return 0.80;
        return 0.70;

      case ActivityType.stationary:
        return 0.95; // Très facile à détecter

      case ActivityType.other:
        return 0.50;
    }
  }

  /// Analyse l'activité et retourne le type + confiance
  Map<String, dynamic> analyzeActivity(LocationRecordModel record) {
    // Calculer la vitesse moyenne
    final durationHours = record.durationMinutes / 60;
    final averageSpeedKmh = durationHours > 0
        ? record.distanceKm / durationHours
        : 0.0;

    // Calculer la vitesse max à partir des points GPS
    final speedSamples = _calculateSpeedSamples(record.route);
    final maxSpeedKmh = speedSamples.isNotEmpty
        ? speedSamples.reduce((a, b) => a > b ? a : b)
        : averageSpeedKmh;

    // Détecter le type d'activité
    final activityType = detectActivityType(
      averageSpeedKmh: averageSpeedKmh,
      maxSpeedKmh: maxSpeedKmh,
      stepCount: record.stepsCount,
      speedSamples: speedSamples,
    );

    // Calculer la confiance
    final confidence = getDetectionConfidence(
      detectedType: activityType,
      averageSpeedKmh: averageSpeedKmh,
      stepCount: record.stepsCount,
    );

    return {
      'activityType': activityType,
      'confidence': confidence,
      'averageSpeedKmh': averageSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
    };
  }

  /// Calcule les vitesses instantanées entre les points GPS
  List<double> _calculateSpeedSamples(List<LocationPoint> route) {
    if (route.length < 2) return [];

    final speeds = <double>[];
    for (int i = 0; i < route.length - 1; i++) {
      final distance = _calculateDistance(
        route[i].latitude,
        route[i].longitude,
        route[i + 1].latitude,
        route[i + 1].longitude,
      );
      final timeSeconds = route[i + 1].timestamp
          .difference(route[i].timestamp)
          .inSeconds;

      if (timeSeconds > 0) {
        final speedKmh = (distance / timeSeconds) * 3600;
        speeds.add(speedKmh);
      }
    }

    return speeds;
  }

  /// Calcule la distance entre deux points GPS (Haversine)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Rayon de la Terre en km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * 3.141592653589793 / 180;
  double _sin(double x) => _approximateSin(x);
  double _cos(double x) => _approximateCos(x);
  double _sqrt(double x) => x < 0 ? 0 : _approximateSqrt(x);
  double _atan2(double y, double x) => _approximateAtan2(y, x);

  // Approximations mathématiques simples
  double _approximateSin(double x) {
    // Taylor series approximation
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  double _approximateCos(double x) {
    // Taylor series approximation
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }

  double _approximateSqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _approximateAtan2(double y, double x) {
    if (x == 0) return y > 0 ? 1.5708 : -1.5708;
    double atan = y / x;
    // Simple approximation
    return atan / (1 + 0.28 * atan * atan);
  }
}
