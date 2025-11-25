import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/gps_tracking_service.dart';
import 'package:filmeals_app/core/services/activity_detection_service.dart';
import 'package:filmeals_app/core/services/activity_notification_service.dart';
import 'package:filmeals_app/data/repository/location_repository.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String userId;

  const LiveTrackingScreen({
    super.key,
    required this.userId,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final GpsTrackingService _gpsService = GpsTrackingService();
  final ActivityDetectionService _detectionService = ActivityDetectionService();
  final ActivityNotificationService _notificationService =
      ActivityNotificationService();
  final LocationRepository _repository = LocationRepository();
  final MapController _mapController = MapController();

  bool _isTracking = false;
  double _distance = 0.0;
  double _speed = 0.0;
  int _duration = 0;
  int _steps = 0;
  ActivityType _currentActivityType = ActivityType.other;
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    _notificationService.initialize();
  }

  void _setupCallbacks() {
    _gpsService.onLocationUpdate = (locationPoint) {
      setState(() {
        _currentPosition = LatLng(
          locationPoint.latitude,
          locationPoint.longitude,
        );
        _routePoints.add(_currentPosition!);
      });
      _mapController.move(_currentPosition!, 16);
    };

    _gpsService.onStatsUpdate = (distance, speed) {
      setState(() {
        _distance = distance;
        _speed = speed;
      });
    };

    _gpsService.onStepUpdate = (steps) {
      setState(() {
        _steps = steps;
      });
    };
  }

  Future<void> _startTracking() async {
    final started = await _gpsService.startTracking();
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'accéder au GPS. Vérifiez les permissions.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isTracking = true;
      _distance = 0.0;
      _speed = 0.0;
      _duration = 0;
      _steps = 0;
      _routePoints.clear();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = _gpsService.getDuration();
        _speed = _gpsService.getAverageSpeed();
      });
    });
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();

    final record = await _gpsService.stopTracking(widget.userId);
    if (record == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activité trop courte, non enregistrée.'),
          ),
        );
      }
      setState(() {
        _isTracking = false;
      });
      return;
    }

    // Détecter le type d'activité
    final analysis = _detectionService.analyzeActivity(record);
    final detectedType = analysis['activityType'] as ActivityType;
    final confidence = analysis['confidence'] as double;

    // Sauvegarder avec le type détecté
    final updatedRecord = record.copyWith(activityType: detectedType);
    await _repository.saveLocationRecord(updatedRecord);

    // Envoyer notification de confirmation
    await _notificationService.sendActivityConfirmation(
      activityId: record.id,
      activity: updatedRecord,
      detectedType: detectedType,
      confidence: confidence,
    );

    setState(() {
      _isTracking = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Activité enregistrée ! ${_getActivityText(detectedType)} détecté.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  String _getActivityText(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return '🚶 Marche';
      case ActivityType.running:
        return '🏃 Course';
      case ActivityType.cycling:
        return '🚴 Vélo';
      case ActivityType.driving:
        return '🚌 Transport';
      case ActivityType.stationary:
        return '🪑 Immobile';
      case ActivityType.other:
        return 'Activité';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte
          _buildMap(),

          // Stats overlay
          _buildStatsOverlay(),

          // Boutons de contrôle
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? const LatLng(48.8566, 2.3522), // Paris par défaut
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.filmeals.app',
        ),
        // Ligne de la trajectoire
        if (_routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: AppTheme.locationColor,
                strokeWidth: 4.0,
              ),
            ],
          ),
        // Marqueur position actuelle
        if (_currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentPosition!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.locationColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatsOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.straighten_rounded,
                    '${_distance.toStringAsFixed(2)} km',
                    'Distance',
                  ),
                  Container(width: 1, height: 40, color: AppTheme.borderColor),
                  _buildStatItem(
                    Icons.timer_rounded,
                    _formatDuration(_duration),
                    'Durée',
                  ),
                  Container(width: 1, height: 40, color: AppTheme.borderColor),
                  _buildStatItem(
                    Icons.speed_rounded,
                    '${_speed.toStringAsFixed(1)} km/h',
                    'Vitesse',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Compteur de pas
            if (_steps > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      color: AppTheme.locationColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_steps pas',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.locationColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: _isTracking
            ? ElevatedButton(
                onPressed: _stopTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Arrêter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: _startTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.locationColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Démarrer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}min';
    }
    return '${mins}min';
  }
}
