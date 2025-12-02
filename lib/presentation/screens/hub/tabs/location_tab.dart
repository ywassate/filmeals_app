import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/widgets/page_banner.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/gps_tracking_service.dart';
import 'package:filmeals_app/core/services/activity_detection_service.dart';
import 'package:filmeals_app/core/services/activity_notification_service.dart';
import 'package:filmeals_app/data/repository/location_repository.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/models/central_data_model.dart';
import 'package:filmeals_app/presentation/screens/tracking/activity_detail_screen.dart';
import 'package:filmeals_app/presentation/screens/tracking/activity_history_screen.dart';
import 'package:filmeals_app/presentation/screens/tracking/activity_weekly_stats_screen.dart';
import 'package:intl/intl.dart';

class LocationTab extends StatefulWidget {
  const LocationTab({super.key});

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> with AutomaticKeepAliveClientMixin {
  final GpsTrackingService _gpsService = GpsTrackingService();
  final ActivityDetectionService _detectionService = ActivityDetectionService();
  final ActivityNotificationService _notificationService = ActivityNotificationService();
  final LocationRepository _repository = LocationRepository();
  final MapController _mapController = MapController();
  late final LocalStorageService _storage;

  bool _isTracking = false;
  bool _isPaused = false;
  bool _isLoadingLocation = false;
  bool _isInitialized = false;
  double _distance = 0.0;
  double _speed = 0.0;
  int _duration = 0;
  int _steps = 0;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];

  // Stats globales et historique
  List<LocationRecordModel> _recentActivities = [];
  Map<String, dynamic> _stats = {};
  String? _userId;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      _init();
      _isInitialized = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les données quand on revient sur cette page
    if (mounted && _isInitialized) {
      _loadData();
    }
  }

  Future<void> _init() async {
    // Position par défaut immédiate (Paris)
    _currentPosition = const LatLng(48.8566, 2.3522);

    await _initStorage();
    await _loadData();
    _setupCallbacks();
    _notificationService.initialize();

    // Charger la vraie position en arrière-plan sans bloquer l'UI
    _getCurrentLocation();
  }

  Future<void> _initStorage() async {
    _storage = LocalStorageService();
    await _storage.init();
  }

  Future<void> _loadData() async {
    // Get user ID from centralDataBox (same as TestDataService)
    var user = _storage.centralDataBox.get('currentUser');
    if (user == null) {
      final now = DateTime.now();
      final defaultUser = CentralDataModel(
        id: 'user_${now.millisecondsSinceEpoch}',
        name: 'Utilisateur',
        email: 'user@example.com',
        age: 25,
        gender: 'male',
        height: 170,
        weight: 70,
        profilePictureUrl: '',
        createdAt: now,
        updatedAt: now,
        activeSensors: ['location'],
      );
      await _storage.centralDataBox.put('currentUser', defaultUser);
      user = defaultUser;
    }

    _userId = user.id;
    print('👤 LocationTab using user ID: $_userId');

    _recentActivities = await _repository.getRecentActivities(user.id, 10);
    _stats = await _repository.getUserActivityStats(user.id);

    if (mounted) setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _gpsService.getCurrentPosition().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('GPS timeout - using default location');
          return null;
        },
      );

      if (position != null && mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        // Wait for the map to be ready before moving
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentPosition != null) {
            try {
              _mapController.move(_currentPosition!, 16);
            } catch (e) {
              debugPrint('MapController not ready yet: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position: $e');
      // La position par défaut est déjà définie dans _init(), pas besoin de la redéfinir
    }
  }

  void _setupCallbacks() {
    _gpsService.onLocationUpdate = (locationPoint) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(
            locationPoint.latitude,
            locationPoint.longitude,
          );
          _routePoints.add(_currentPosition!);
        });
        try {
          _mapController.move(_currentPosition!, 16);
        } catch (e) {
          debugPrint('MapController not ready during tracking: $e');
        }
      }
    };

    _gpsService.onStatsUpdate = (distance, speed) {
      if (mounted) {
        setState(() {
          _distance = distance;
          _speed = speed;
        });
      }
    };

    _gpsService.onStepUpdate = (steps) {
      if (mounted) {
        setState(() {
          _steps = steps;
        });
      }
    };
  }

  Future<void> _startTracking() async {
    if (_userId == null) {
      MinimalSnackBar.showError(
        context,
        title: 'Erreur',
        message: 'Erreur: Utilisateur non initialisé',
      );
      return;
    }

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
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
      _routePoints.clear();
    });

    // Timer ultra fluide - se met à jour toutes les 30ms pour un affichage très smooth
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted && _startTime != null && !_isPaused) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!) - _pausedDuration;
          // Mettre à jour les stats GPS moins souvent (toutes les secondes via le service)
          _duration = _gpsService.getDuration();
          _speed = _gpsService.getAverageSpeed();
          _distance = _gpsService.getTotalDistance();
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        // Mettre en pause
        _pauseStartTime = DateTime.now();
      } else {
        // Reprendre
        if (_pauseStartTime != null) {
          _pausedDuration += DateTime.now().difference(_pauseStartTime!);
          _pauseStartTime = null;
        }
      }
    });
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();
    _startTime = null;

    final record = await _gpsService.stopTracking(_userId!);
    if (record == null) {
      // Pas de données GPS collectées, arrêt silencieux
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

    // Recharger les données
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Activité enregistrée ! ${_getActivityText(detectedType)} détecté.',
          ),
        ),
      );
    }
  }

  String _getActivityText(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return 'Marche';
      case ActivityType.running:
        return 'Course';
      case ActivityType.cycling:
        return 'Vélo';
      case ActivityType.driving:
        return 'Transport';
      case ActivityType.stationary:
        return 'Immobile';
      case ActivityType.other:
        return 'Activité';
    }
  }

  void _viewActivityDetail(LocationRecordModel activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    ).then((_) => _loadData());
  }

  String _formatElapsedTime() {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes % 60;
    final seconds = _elapsed.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
    super.build(context); // Important pour AutomaticKeepAliveClientMixin

    // Mode Tracking : Carte plein écran
    if (_isTracking) {
      return _buildTrackingMode();
    }

    // Mode Normal : Vue avec historique
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header fixe avec icônes
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Row(
                    children: [
                      // Bouton Historique
                      IconButton(
                        onPressed: () {
                          if (_userId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActivityHistoryScreen(userId: _userId!),
                              ),
                            ).then((_) => _loadData());
                          }
                        },
                        icon: const Icon(
                          Icons.history_rounded,
                          color: AppTheme.textPrimaryColor,
                          size: 24,
                        ),
                      ),
                      // Bouton Stats
                      IconButton(
                        onPressed: () {
                          if (_userId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActivityWeeklyStatsScreen(
                                  storageService: _storage,
                                  userId: _userId!,
                                ),
                              ),
                            ).then((_) => _loadData());
                          }
                        },
                        icon: const Icon(
                          Icons.bar_chart_rounded,
                          color: AppTheme.textPrimaryColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      Text(
                        _getFormattedDate(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bannière
                      PageBanner(
                        title: 'Stay Active',
                        subtitle: 'Keep moving every day',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        imagePath: 'assets/images/carousel/active.png',
                      ),
                      const SizedBox(height: 32),

                      // Stats globales (historique)
                      if ((_stats['total_activities'] ?? 0) > 0) ...[
                        _buildGlobalStats(),
                        const SizedBox(height: 40),
                      ],

                      // Bouton Start
                      _buildButton(),
                      const SizedBox(height: 40),

                      // Historique des activités
                      const Text(
                        'Recent Activities',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildActivities(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingMode() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Carte plein écran
          _buildFullScreenMap(),

          // Overlay avec timer, stats et boutons en haut
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Timer avec boutons sur la même ligne
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bouton Pause/Play
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppTheme.textPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _togglePause,
                            icon: Icon(
                              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        // Timer au centre
                        Expanded(
                          child: Center(
                            child: _buildTimer(),
                          ),
                        ),
                        // Bouton Stop
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _stopTracking,
                            icon: const Icon(
                              Icons.stop_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Divider
                    Container(
                      height: 1,
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 24),
                    // Stats en ligne
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCompactStat(
                          value: _distance.toStringAsFixed(2),
                          label: 'KM',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.borderColor,
                        ),
                        _buildCompactStat(
                          value: _speed.toStringAsFixed(1),
                          label: 'KM/H',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.borderColor,
                        ),
                        _buildCompactStat(
                          value: '$_steps',
                          label: 'STEPS',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes % 60;
    final seconds = _elapsed.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing dot indicator avec animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, child) {
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5 * value),
                    blurRadius: 8 + (4 * value),
                    spreadRadius: 2 * value,
                  ),
                ],
              ),
            );
          },
          onEnd: () {
            if (_isTracking && mounted) {
              setState(() {}); // Relance l'animation
            }
          },
        ),
        const SizedBox(width: 16),
        // Timer digits avec animation
        if (hours > 0) ...[
          _buildAnimatedTimerDigit(hours.toString().padLeft(2, '0'), isLarge: true),
          const Text(
            ':',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
        _buildAnimatedTimerDigit(minutes.toString().padLeft(2, '0'), isLarge: true),
        const Text(
          ':',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        _buildAnimatedTimerDigit(seconds.toString().padLeft(2, '0'), isLarge: true),
      ],
    );
  }

  Widget _buildAnimatedTimerDigit(String digit, {required bool isLarge}) {
    final fontSize = isLarge ? 40.0 : 32.0;
    final padding = isLarge
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 6);

    // Séparer les deux chiffres pour animer seulement celui qui change
    final digit1 = digit.length > 1 ? digit[0] : '0';
    final digit2 = digit.length > 1 ? digit[1] : digit[0];

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.textPrimaryColor.withOpacity(isLarge ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premier chiffre
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Text(
              digit1,
              key: ValueKey('digit1_$digit1'),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: isLarge ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                letterSpacing: -2,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          // Deuxième chiffre
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Text(
              digit2,
              key: ValueKey('digit2_$digit2'),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: isLarge ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                letterSpacing: -2,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat({required String value, required String label}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey(value),
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
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

  Widget _buildFullScreenMap() {
    return _currentPosition == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimaryColor),
                  strokeWidth: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  'Getting GPS location...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor.withOpacity(0.6),
                  ),
                ),
              ],
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.filmeals.app',
                maxNativeZoom: 19,
              ),
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppTheme.textPrimaryColor,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 16,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
  }

  Widget _buildCurrentStats() {
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

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildGlobalStats() {
    final totalDistance = (_stats['total_distance_km'] as double).toStringAsFixed(1);
    final totalActivities = _stats['total_activities'];

    return Row(
      children: [
        Expanded(
          child: _MinimalStatCard(
            value: totalDistance,
            label: 'TOTAL KM',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MinimalStatCard(
            value: '$totalActivities',
            label: 'ACTIVITIES',
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: _currentPosition == null
          ? Center(
              child: Text(
                'Map will appear when GPS is ready',
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

  Widget _buildButton() {
    if (!_isTracking) {
      // Bouton Start quand pas en tracking
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: TextButton(
          onPressed: _startTracking,
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.textPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Start Tracking',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    // Boutons Pause et Stop quand en tracking
    return Row(
      children: [
        // Bouton Pause/Resume
        Expanded(
          child: SizedBox(
            height: 52,
            child: TextButton(
              onPressed: _togglePause,
              style: TextButton.styleFrom(
                backgroundColor: _isPaused
                    ? AppTheme.textPrimaryColor
                    : AppTheme.surfaceColor,
                foregroundColor: _isPaused
                    ? Colors.white
                    : AppTheme.textPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPaused ? 'Resume' : 'Pause',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bouton Stop
        Expanded(
          child: SizedBox(
            height: 52,
            child: TextButton(
              onPressed: _stopTracking,
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Stop',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivities() {
    if (_recentActivities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.directions_run_rounded,
              size: 48,
              color: AppTheme.textSecondaryColor.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondaryColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your movements',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentActivities.map((activity) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ActivityCard(
            activity: activity,
            onTap: () => _viewActivityDetail(activity),
          ),
        );
      }).toList(),
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

class _ActivityCard extends StatelessWidget {
  final LocationRecordModel activity;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getActivityIcon(),
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActivityText(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy • HH:mm', 'fr_FR')
                            .format(activity.startTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '${activity.distanceKm.toStringAsFixed(1)} km',
                    'Distance',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '${activity.durationMinutes} min',
                    'Duration',
                  ),
                ),
                if (activity.stepsCount > 0)
                  Expanded(
                    child: _buildStatItem(
                      '${activity.stepsCount}',
                      'Steps',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon() {
    switch (activity.activityType) {
      case ActivityType.walking:
        return Icons.directions_walk_rounded;
      case ActivityType.running:
        return Icons.directions_run_rounded;
      case ActivityType.cycling:
        return Icons.directions_bike_rounded;
      case ActivityType.driving:
        return Icons.directions_car_rounded;
      case ActivityType.stationary:
        return Icons.chair_rounded;
      case ActivityType.other:
        return Icons.location_on_rounded;
    }
  }

  String _getActivityText() {
    switch (activity.activityType) {
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.running:
        return 'Running';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.driving:
        return 'Transport';
      case ActivityType.stationary:
        return 'Stationary';
      case ActivityType.other:
        return 'Other';
    }
  }
}
