import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:intl/intl.dart';

/// Écran de statistiques hebdomadaires des activités physiques
class ActivityWeeklyStatsScreen extends StatefulWidget {
  final LocalStorageService storageService;
  final String userId;

  const ActivityWeeklyStatsScreen({
    super.key,
    required this.storageService,
    required this.userId,
  });

  @override
  State<ActivityWeeklyStatsScreen> createState() => _ActivityWeeklyStatsScreenState();
}

class _ActivityWeeklyStatsScreenState extends State<ActivityWeeklyStatsScreen> {
  DateTime _selectedWeek = DateTime.now();
  Map<int, double> _weeklyDistance = {}; // weekday -> km
  Map<int, int> _weeklyDuration = {}; // weekday -> minutes
  bool _isLoading = true;
  final double _goalDistance = 5.0; // 5 km per day

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);

    try {
      _weeklyDistance.clear();
      _weeklyDuration.clear();

      // Obtenir le début de la semaine (lundi)
      final weekStart = _getWeekStart(_selectedWeek);

      // Charger les activités pour chaque jour de la semaine
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final activities = await _getActivitiesForDate(date);

        // Calculer distance et durée totales
        double totalDistance = 0.0;
        int totalDuration = 0;

        for (var activity in activities) {
          totalDistance += activity.distanceKm;
          totalDuration += activity.durationMinutes;
        }

        _weeklyDistance[date.weekday] = totalDistance; // Already in km
        _weeklyDuration[date.weekday] = totalDuration; // Already in minutes
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading week data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<LocationRecordModel>> _getActivitiesForDate(DateTime date) async {
    try {
      final locationBox = widget.storageService.locationRecordsBox;
      final records = locationBox.values
          .whereType<LocationRecordModel>()
          .where((record) {
            return record.userId == widget.userId &&
                record.startTime.year == date.year &&
                record.startTime.month == date.month &&
                record.startTime.day == date.day;
          })
          .toList();

      return records;
    } catch (e) {
      print('Error getting activities for date: $e');
      return [];
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: weekday - 1));
  }

  void _changeWeek(int weeks) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedWeek = _selectedWeek.add(Duration(days: weeks * 7));
    });
    _loadWeekData();
  }

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    final selectedWeekStart = _getWeekStart(_selectedWeek);
    return currentWeekStart.year == selectedWeekStart.year &&
        currentWeekStart.month == selectedWeekStart.month &&
        currentWeekStart.day == selectedWeekStart.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.textPrimaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Weekly Stats',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.textPrimaryColor,
                        strokeWidth: 2,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWeekSelector(),
                          const SizedBox(height: 40),
                          _buildBarChart(),
                          const SizedBox(height: 40),
                          _buildWeekSummary(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSelector() {
    final weekStart = _getWeekStart(_selectedWeek);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final format = DateFormat('d MMM');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _changeWeek(-1),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chevron_left,
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
          ),
        ),
        Text(
          '${format.format(weekStart)} - ${format.format(weekEnd)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        GestureDetector(
          onTap: _isCurrentWeek ? null : () => _changeWeek(1),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isCurrentWeek ? AppTheme.backgroundColor : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.chevron_right,
              color: _isCurrentWeek ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Distance (km)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Goal ${_goalDistance.toStringAsFixed(0)}km',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Graphique à barres verticales
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final weekday = index + 1; // 1 = Lundi
                return _buildVerticalBar(weekday);
              }),
            ),
          ),

          const SizedBox(height: 12),

          // Jours de la semaine
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return SizedBox(
                width: 36,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalBar(int weekday) {
    final distance = _weeklyDistance[weekday] ?? 0.0;
    final maxDistance = _weeklyDistance.values.fold(
      _goalDistance,
      (max, d) => d > max ? d : max,
    );

    // Calculer la hauteur de la barre (max 180px)
    final barHeight = maxDistance > 0
        ? (distance / maxDistance * 180).clamp(4.0, 180.0)
        : 4.0;

    // Calculer la hauteur de la ligne d'objectif
    final goalLineHeight = maxDistance > 0
        ? (_goalDistance / maxDistance * 180).clamp(0.0, 180.0)
        : 0.0;

    final isToday = DateTime.now().weekday == weekday && _isCurrentWeek;
    final reachedGoal = distance >= _goalDistance * 0.9;

    return Expanded(
      child: GestureDetector(
        onTap: distance > 0 ? () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getDayName(weekday)}: ${distance.toStringAsFixed(1)} km'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.textPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } : null,
        child: SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Ligne de l'objectif
              if (goalLineHeight > 0)
                Positioned(
                  bottom: goalLineHeight,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: AppTheme.textSecondaryColor.withOpacity(0.5),
                  ),
                ),

              // Barre verticale
              Positioned(
                bottom: 0,
                child: Container(
                  width: isToday ? 32 : 28,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: reachedGoal
                        ? AppTheme.textPrimaryColor
                        : AppTheme.textPrimaryColor.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),

              // Indicateur aujourd'hui
              if (isToday)
                Positioned(
                  bottom: barHeight + 3,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppTheme.textPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              // Afficher la valeur si > 0
              if (distance > 0)
                Positioned(
                  bottom: barHeight + (isToday ? 12 : 7),
                  child: Text(
                    distance.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  Widget _buildWeekSummary() {
    final totalDistance = _weeklyDistance.values.fold(0.0, (sum, d) => sum + d);
    final totalDuration = _weeklyDuration.values.fold(0, (sum, d) => sum + d);
    final daysWithActivity = _weeklyDistance.values.where((d) => d > 0).length;
    final avgDistance = daysWithActivity > 0 ? totalDistance / daysWithActivity : 0.0;
    final bestDay = _weeklyDistance.entries
        .fold<MapEntry<int, double>?>(null, (best, entry) {
          if (best == null || entry.value > best.value) return entry;
          return best;
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total',
                '${totalDistance.toStringAsFixed(1)} km',
                'distance',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Duration',
                '${totalDuration} min',
                'total time',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Average',
                '${avgDistance.toStringAsFixed(1)} km',
                'per day',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Best day',
                bestDay != null ? _getDayName(bestDay.key) : '-',
                bestDay != null ? '${bestDay.value.toStringAsFixed(1)} km' : '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
              height: 1,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
