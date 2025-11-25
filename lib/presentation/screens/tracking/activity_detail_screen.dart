import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:filmeals_app/data/repository/location_repository.dart';

class ActivityDetailScreen extends StatefulWidget {
  final LocationRecordModel activity;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final LocationRepository _repository = LocationRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec carte
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMap(),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildActivityInfo(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (widget.activity.route.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Text('Aucune carte disponible'),
        ),
      );
    }

    final routePoints = widget.activity.route
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    final center = LatLng(
      widget.activity.route.first.latitude,
      widget.activity.route.first.longitude,
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.filmeals.app',
        ),
        // Trajectoire
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints,
              color: _getActivityColor(widget.activity.activityType),
              strokeWidth: 4.0,
            ),
          ],
        ),
        // Marqueurs début et fin
        MarkerLayer(
          markers: [
            // Début (vert)
            Marker(
              point: routePoints.first,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Fin (rouge)
            Marker(
              point: routePoints.last,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.stop,
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getActivityColor(widget.activity.activityType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getActivityIcon(widget.activity.activityType),
            color: _getActivityColor(widget.activity.activityType),
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getActivityText(widget.activity.activityType),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy • HH:mm', 'fr_FR')
                    .format(widget.activity.startTime),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getActivityColor(widget.activity.activityType),
            _getActivityColor(widget.activity.activityType).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getActivityColor(widget.activity.activityType).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.straighten_rounded,
            '${widget.activity.distanceKm.toStringAsFixed(2)}',
            'km',
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            Icons.timer_rounded,
            '${widget.activity.durationMinutes}',
            'min',
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            Icons.speed_rounded,
            _getAverageSpeed().toStringAsFixed(1),
            'km/h',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                unit,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          Icons.directions_walk_rounded,
          'Pas',
          widget.activity.stepsCount > 0
              ? '${widget.activity.stepsCount} pas'
              : 'Non disponible',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          Icons.access_time_rounded,
          'Heure de début',
          DateFormat('HH:mm', 'fr_FR').format(widget.activity.startTime),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          Icons.flag_rounded,
          'Heure de fin',
          DateFormat('HH:mm', 'fr_FR').format(widget.activity.endTime),
        ),
        if (widget.activity.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            Icons.note_rounded,
            'Notes',
            widget.activity.notes,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.locationColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.locationColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
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
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _changeActivityType,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Modifier le type'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.locationColor,
              side: const BorderSide(color: AppTheme.locationColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _deleteActivity,
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _changeActivityType() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modifier le type d\'activité',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...ActivityType.values.map((type) {
              return ListTile(
                leading: Icon(
                  _getActivityIcon(type),
                  color: _getActivityColor(type),
                ),
                title: Text(_getActivityText(type)),
                trailing: widget.activity.activityType == type
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _updateActivityType(type);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _updateActivityType(ActivityType newType) async {
    await _repository.updateActivityType(widget.activity.id, newType);
    setState(() {
      // L'activité sera mise à jour automatiquement
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Type modifié en ${_getActivityText(newType)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteActivity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'activité'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette activité ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _repository.deleteLocationRecord(widget.activity.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activité supprimée'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getAverageSpeed() {
    if (widget.activity.durationMinutes == 0) return 0.0;
    return (widget.activity.distanceKm / widget.activity.durationMinutes) * 60;
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
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
