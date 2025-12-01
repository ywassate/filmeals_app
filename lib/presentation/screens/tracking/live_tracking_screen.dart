import 'dart:async';
import 'package:flutter/material.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
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
  bool _isLoadingLocation = true;
  double _distance = 0.0;
  double _speed = 0.0;
  int _duration = 0;
  int _steps = 0;
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    _notificationService.initialize();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _gpsService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition!, 16);
      } else if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
      debugPrint('Erreur lors de la récupération de la position: $e');
    }
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
        MinimalSnackBar.showInfo(
        context,
        title: 'Info',
        message: 'Activité trop courte, non enregistrée.',
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
    if (_isLoadingLocation) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimaryColor),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header minimaliste
                _buildHeader(),
                const SizedBox(height: 40),

                // Statut
                Text(
                  _isTracking ? 'TRACKING' : 'READY',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),

                // Stats principales
                _buildMinimalStats(),
                const SizedBox(height: 40),

                // Map
                const Text(
                  'Route',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildMapCard(),
                const SizedBox(height: 40),

                // Détails
                const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildProgressBars(),
                const SizedBox(height: 40),

                // Bouton
                _buildButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Live Tracking',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
            letterSpacing: -1.5,
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.close,
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalStats() {
    return Row(
      children: [
        Expanded(
          child: _MinimalStatCard(
            value: _distance.toStringAsFixed(2),
            label: 'KM',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MinimalStatCard(
            value: '$_duration',
            label: 'MIN',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MinimalStatCard(
            value: _speed.toStringAsFixed(1),
            label: 'KM/H',
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: _currentPosition == null
          ? Center(
              child: Text(
                'Map will appear when tracking starts',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor.withOpacity(0.6),
                ),
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 16.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.filmeals.app',
                ),
                if (_routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: AppTheme.textPrimaryColor,
                        strokeWidth: 3.0,
                      ),
                    ],
                  ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 12,
                        height: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.textPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _buildProgressBars() {
    return Column(
      children: [
        _ProgressItem(
          label: 'Steps',
          value: '$_steps',
          total: '10,000',
          percentage: _steps / 10000,
        ),
        const SizedBox(height: 20),
        _ProgressItem(
          label: 'Calories',
          value: '${(_distance * 60).toInt()}',
          total: '500',
          percentage: (_distance * 60) / 500,
        ),
        const SizedBox(height: 20),
        _ProgressItem(
          label: 'Pace',
          value: _speed > 0 ? '${(60 / _speed).toStringAsFixed(1)}' : '0.0',
          total: 'min/km',
          percentage: 0.0,
        ),
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: _isTracking ? _stopTracking : _startTracking,
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.textPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isTracking ? 'Stop Tracking' : 'Start Tracking',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _MinimalStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _MinimalStatCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String label;
  final String value;
  final String total;
  final double percentage;

  const _ProgressItem({
    required this.label,
    required this.value,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            Text(
              '$value / $total',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.textPrimaryColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
