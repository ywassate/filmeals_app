import 'package:flutter/material.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';

/// Utilitaires de formatage pour les activités
class ActivityFormatter {
  /// Retourne le label en français pour un type d'activité
  static String getActivityTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.running:
        return 'Running';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.driving:
        return 'Driving';
      case ActivityType.stationary:
        return 'Stationary';
      default:
        return 'Activity';
    }
  }

  /// Retourne l'icône pour un type d'activité
  static IconData getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return Icons.directions_walk_rounded;
      case ActivityType.running:
        return Icons.directions_run_rounded;
      case ActivityType.cycling:
        return Icons.directions_bike_rounded;
      case ActivityType.driving:
        return Icons.directions_car_rounded;
      case ActivityType.stationary:
        return Icons.pin_drop_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  /// Formate la distance en km
  static String formatDistance(double distanceInMeters) {
    final km = distanceInMeters / 1000;
    if (km < 1) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    }
    return '${km.toStringAsFixed(2)}km';
  }

  /// Formate la vitesse en km/h
  static String formatSpeed(double speedInMps) {
    final kmh = speedInMps * 3.6;
    return '${kmh.toStringAsFixed(1)}km/h';
  }

  /// Formate le rythme en min/km
  static String formatPace(double speedInMps) {
    if (speedInMps == 0) return '--:--/km';
    final kmh = speedInMps * 3.6;
    final minPerKm = 60 / kmh;
    final minutes = minPerKm.floor();
    final seconds = ((minPerKm - minutes) * 60).round();
    return '${minutes}:${seconds.toString().padLeft(2, '0')}/km';
  }
}
