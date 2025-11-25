import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:filmeals_app/data/models/user_model.dart';

/// Extension pour l'export MCP des données de localisation
class MCPExportLocationExtension {
  /// Formate les activités physiques pour le MCP
  static List<Map<String, dynamic>> formatPhysicalActivities(
    List<LocationRecordModel> activities,
  ) {
    return activities.map((activity) {
      return {
        'activity_id': _generateAnonymousId(activity.id),
        'timestamp_start': activity.startTime.toIso8601String(),
        'timestamp_end': activity.endTime.toIso8601String(),
        'type': activity.activityType.toString().split('.').last,
        'duration_minutes': activity.durationMinutes,
        'distance_km': activity.distanceKm,
        'steps_count': activity.stepsCount,
        'average_speed_kmh':
            activity.durationMinutes > 0
                ? (activity.distanceKm / activity.durationMinutes) * 60
                : 0.0,
        'route_points_count': activity.route.length,
        'notes': activity.notes,
      };
    }).toList();
  }

  /// Analyse le profil d'activité physique de l'utilisateur
  static Map<String, dynamic> analyzeActivityProfile(
    List<LocationRecordModel> activities,
    Map<String, dynamic> stats,
    UserModel user,
  ) {
    if (activities.isEmpty) {
      return {
        'activity_level': 'sedentary',
        'total_activities': 0,
        'activity_patterns': {},
        'health_metrics': {},
      };
    }

    // Séparer activités physiques vs transport passif
    final physicalActivities = activities.where((a) =>
        a.activityType == ActivityType.walking ||
        a.activityType == ActivityType.running ||
        a.activityType == ActivityType.cycling).toList();

    final passiveTransport = activities.where((a) =>
        a.activityType == ActivityType.driving).toList();

    // Calculer les statistiques par type
    final byType = stats['by_type'] as Map<String, dynamic>;
    final activityPatterns = <String, Map<String, dynamic>>{};

    for (var entry in byType.entries) {
      final typeData = entry.value as Map<String, dynamic>;
      activityPatterns[entry.key] = {
        'frequency_per_week': _calculateWeeklyFrequency(
          typeData['count'] as int,
          activities,
        ),
        'avg_distance_km': typeData['avg_distance_km'],
        'avg_duration_min': typeData['avg_duration_min'],
        'total_distance_km': typeData['total_distance_km'],
        'total_sessions': typeData['count'],
      };
    }

    // Déterminer le niveau d'activité global
    final activityLevel = _determineActivityLevel(physicalActivities);

    // Calculer les métriques de santé
    final healthMetrics = _calculateHealthMetrics(
      physicalActivities,
      user,
    );

    return {
      'activity_level': activityLevel,
      'total_activities': activities.length,
      'physical_activities_count': physicalActivities.length,
      'passive_transport_count': passiveTransport.length,
      'sedentary_percentage': passiveTransport.length / activities.length * 100,
      'activity_patterns': activityPatterns,
      'health_metrics': healthMetrics,
      'preferred_activity': _findPreferredActivity(byType),
      'most_active_time': _findMostActiveTime(activities),
    };
  }

  /// Calcule la fréquence hebdomadaire
  static double _calculateWeeklyFrequency(
    int totalCount,
    List<LocationRecordModel> activities,
  ) {
    if (activities.isEmpty) return 0.0;

    final firstActivity = activities.last.startTime;
    final lastActivity = activities.first.startTime;
    final totalWeeks = lastActivity.difference(firstActivity).inDays / 7;

    return totalWeeks > 0 ? totalCount / totalWeeks : totalCount.toDouble();
  }

  /// Détermine le niveau d'activité général
  static String _determineActivityLevel(List<LocationRecordModel> activities) {
    if (activities.isEmpty) return 'sedentary';

    // Calculer le temps actif moyen par semaine
    final totalMinutes = activities.fold(
      0,
      (sum, a) => sum + a.durationMinutes,
    );
    final weeks = activities.isNotEmpty
        ? DateTime.now().difference(activities.last.startTime).inDays / 7
        : 1;
    final avgMinutesPerWeek = totalMinutes / (weeks > 0 ? weeks : 1);

    // Classification selon les recommandations OMS
    if (avgMinutesPerWeek >= 150) return 'very_active';
    if (avgMinutesPerWeek >= 75) return 'moderately_active';
    if (avgMinutesPerWeek >= 30) return 'lightly_active';
    return 'sedentary';
  }

  /// Calcule les métriques de santé
  static Map<String, dynamic> _calculateHealthMetrics(
    List<LocationRecordModel> activities,
    UserModel user,
  ) {
    final totalDistance = activities.fold(
      0.0,
      (sum, a) => sum + a.distanceKm,
    );
    final totalDuration = activities.fold(
      0,
      (sum, a) => sum + a.durationMinutes,
    );
    final totalSteps = activities.fold(
      0,
      (sum, a) => sum + a.stepsCount,
    );

    // Estimation calories brûlées (formule MET)
    double totalCalories = 0.0;
    for (var activity in activities) {
      final met = _getMetValue(activity.activityType);
      final durationHours = activity.durationMinutes / 60;
      final calories = met * user.weight * durationHours;
      totalCalories += calories;
    }

    return {
      'total_distance_km': totalDistance,
      'total_duration_min': totalDuration,
      'total_steps': totalSteps,
      'total_calories_burned': totalCalories.round(),
      'avg_distance_per_session': activities.isNotEmpty
          ? totalDistance / activities.length
          : 0.0,
      'avg_duration_per_session': activities.isNotEmpty
          ? totalDuration / activities.length
          : 0,
    };
  }

  /// Retourne la valeur MET pour un type d'activité
  static double _getMetValue(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return 3.5;
      case ActivityType.running:
        return 9.0;
      case ActivityType.cycling:
        return 7.0;
      case ActivityType.driving:
        return 1.0;
      case ActivityType.stationary:
        return 1.0;
      case ActivityType.other:
        return 2.0;
    }
  }

  /// Trouve l'activité préférée
  static String _findPreferredActivity(Map<String, dynamic> byType) {
    if (byType.isEmpty) return 'none';

    var maxCount = 0;
    var preferredType = 'none';

    for (var entry in byType.entries) {
      final data = entry.value as Map<String, dynamic>;
      final count = data['count'] as int;
      if (count > maxCount) {
        maxCount = count;
        preferredType = entry.key;
      }
    }

    return preferredType;
  }

  /// Trouve l'heure la plus active
  static String _findMostActiveTime(List<LocationRecordModel> activities) {
    if (activities.isEmpty) return 'unknown';

    final hourCounts = <int, int>{};
    for (var activity in activities) {
      final hour = activity.startTime.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    var maxCount = 0;
    var mostActiveHour = 0;

    for (var entry in hourCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostActiveHour = entry.key;
      }
    }

    // Catégoriser par période de la journée
    if (mostActiveHour >= 5 && mostActiveHour < 12) return 'morning_5-12';
    if (mostActiveHour >= 12 && mostActiveHour < 17) return 'afternoon_12-17';
    if (mostActiveHour >= 17 && mostActiveHour < 21) return 'evening_17-21';
    return 'night_21-5';
  }

  static String _generateAnonymousId(String originalId) {
    return originalId.hashCode.toRadixString(16).padLeft(16, '0');
  }
}
