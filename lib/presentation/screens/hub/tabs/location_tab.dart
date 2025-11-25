import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/repository/location_repository.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:filmeals_app/data/models/central_data_model.dart';
import 'package:filmeals_app/presentation/screens/tracking/live_tracking_screen.dart';
import 'package:filmeals_app/presentation/screens/tracking/activity_detail_screen.dart';
import 'package:intl/intl.dart';

class LocationTab extends StatefulWidget {
  const LocationTab({super.key});

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {
  final LocationRepository _locationRepository = LocationRepository();
  late final LocalStorageService _storage;

  List<LocationRecordModel> _recentActivities = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _initStorage();
    await _loadData();
  }

  Future<void> _initStorage() async {
    _storage = LocalStorageService();
    await _storage.init();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    var user = _storage.centralDataBox.get('currentUser');
    if (user == null) {
      // Créer un utilisateur par défaut si aucun n'existe
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

    if (user != null) {
      _userId = user.id;
      _recentActivities = await _locationRepository.getRecentActivities(user.id, 30);
      _stats = await _locationRepository.getUserActivityStats(user.id);
    }

    setState(() => _isLoading = false);
  }

  void _startTracking() {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Utilisateur non initialisé'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingScreen(userId: _userId!),
      ),
    ).then((_) => _loadData()); // Recharger après retour
  }

  void _viewActivityDetail(LocationRecordModel activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    ).then((_) => _loadData()); // Recharger après retour
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.locationGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Activité',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Suivez vos déplacements',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bouton démarrer
                        _buildStartButton(),
                        const SizedBox(height: 24),

                        // Statistiques globales
                        if ((_stats['total_activities'] ?? 0) > 0) ...[
                          _buildGlobalStats(),
                          const SizedBox(height: 32),
                        ],

                        // Activités récentes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Activités récentes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            if (_recentActivities.isNotEmpty)
                              Text(
                                '${_recentActivities.length} activités',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildActivities(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startTracking,
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: const Text(
          'Démarrer une activité',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.locationColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalStats() {
    final totalDistance = (_stats['total_distance_km'] as double).toStringAsFixed(1);
    final totalActivities = _stats['total_activities'];
    final byType = _stats['by_type'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.locationGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.locationColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ce mois-ci',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalDistance km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalActivities activités',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          if (byType.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            ...byType.entries.take(3).map((entry) {
              final type = _getActivityTypeFromString(entry.key);
              final data = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _getActivityIcon(type),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getActivityText(type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${data['count']} fois',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildActivities() {
    if (_recentActivities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.directions_run_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune activité enregistrée',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez à tracker vos déplacements',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
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

  ActivityType _getActivityTypeFromString(String typeString) {
    return ActivityType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => ActivityType.other,
    );
  }

  IconData _getActivityIcon(ActivityType type) {
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
        return Icons.chair_rounded;
      case ActivityType.other:
        return Icons.location_on_rounded;
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
        return 'Autre';
    }
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getActivityColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getActivityIcon(),
                    color: _getActivityColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActivityText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy • HH:mm', 'fr_FR')
                            .format(activity.startTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  Icons.straighten_rounded,
                  '${activity.distanceKm.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.timer_rounded,
                  '${activity.durationMinutes} min',
                ),
                if (activity.stepsCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.directions_walk_rounded,
                    '${activity.stepsCount} pas',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getActivityColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _getActivityColor()),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getActivityColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor() {
    switch (activity.activityType) {
      case ActivityType.walking:
        return Colors.green;
      case ActivityType.running:
        return Colors.red;
      case ActivityType.cycling:
        return Colors.blue;
      case ActivityType.driving:
        return Colors.orange;
      case ActivityType.stationary:
        return Colors.grey;
      case ActivityType.other:
        return AppTheme.locationColor;
    }
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
        return 'Autre';
    }
  }
}
