import 'package:flutter/material.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:intl/intl.dart';

/// Écran de statistiques hebdomadaires avec barres verticales
class WeeklyStatsScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final UserRepository userRepository;
  final LocalStorageService storageService;

  const WeeklyStatsScreen({
    super.key,
    required this.mealRepository,
    required this.userRepository,
    required this.storageService,
  });

  @override
  State<WeeklyStatsScreen> createState() => _WeeklyStatsScreenState();
}

class _WeeklyStatsScreenState extends State<WeeklyStatsScreen> {
  DateTime _selectedWeek = DateTime.now();
  Map<int, int> _weeklyCalories = {}; // weekday -> calories
  bool _isLoading = true;
  int _goalCalories = 2200;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);

    try {
      // Get user ID from centralDataBox (same as tabs)
      final centralData = widget.storageService.centralDataBox.get('currentUser');
      _userId = centralData?.id ?? 'default_user';

      print('👤 WeeklyStatsScreen using user ID: $_userId');

      // Get goal from mealsSensorBox
      final mealsSensorData = widget.storageService.mealsSensorBox.values
          .where((data) => data.userId == _userId)
          .firstOrNull;
      if (mealsSensorData != null) {
        _goalCalories = mealsSensorData.dailyCalorieGoal;
      }

      if (_userId != null) {
        _weeklyCalories.clear();

        // Obtenir le début de la semaine (lundi)
        final weekStart = _getWeekStart(_selectedWeek);

        // Charger les calories pour chaque jour de la semaine
        for (int i = 0; i < 7; i++) {
          final date = weekStart.add(Duration(days: i));
          final calories = await widget.mealRepository.getCaloriesForDate(_userId!, date);
          _weeklyCalories[date.weekday] = calories;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading week data: $e');
      setState(() => _isLoading = false);
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  void _changeWeek(int weeks) {
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
                    onTap: () => Navigator.pop(context),
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
    final format = DateFormat('d MMM', 'fr_FR');

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
                'Weekly Stats',
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
                  'Goal $_goalCalories',
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
    final calories = _weeklyCalories[weekday] ?? 0;
    final maxCalories = _weeklyCalories.values.fold(
      _goalCalories,
      (max, cal) => cal > max ? cal : max,
    );

    // Calculer la hauteur de la barre (max 180px)
    final barHeight = maxCalories > 0
        ? (calories / maxCalories * 180).clamp(4.0, 180.0)
        : 4.0;

    // Calculer la hauteur de la ligne d'objectif
    final goalLineHeight = maxCalories > 0
        ? (_goalCalories / maxCalories * 180).clamp(0.0, 180.0)
        : 0.0;

    final isToday = DateTime.now().weekday == weekday && _isCurrentWeek;
    final reachedGoal = calories >= _goalCalories;

    return Expanded(
      child: GestureDetector(
        onTap: calories > 0 ? () {
          // Afficher les détails au tap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getDayName(weekday)}: $calories kcal'),
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
              if (calories > 0)
                Positioned(
                  bottom: barHeight + (isToday ? 12 : 7),
                  child: Text(
                    calories >= 1000
                        ? '${(calories / 1000).toStringAsFixed(1)}k'
                        : calories.toString(),
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
    final totalCalories = _weeklyCalories.values.fold(0, (sum, cal) => sum + cal);
    final daysWithData = _weeklyCalories.values.where((cal) => cal > 0).length;
    final avgCalories = daysWithData > 0 ? totalCalories ~/ daysWithData : 0;
    final daysOnTrack = _weeklyCalories.values
        .where((cal) => cal >= _goalCalories * 0.8 && cal <= _goalCalories * 1.2)
        .length;
    final bestDay = _weeklyCalories.entries
        .fold<MapEntry<int, int>?>(null, (best, entry) {
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
                '${(totalCalories / 1000).toStringAsFixed(1)}k',
                'calories',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Average',
                avgCalories.toString(),
                'kcal/day',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'On track',
                daysOnTrack.toString(),
                'days',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Best day',
                bestDay != null ? _getDayName(bestDay.key) : '-',
                bestDay != null ? '${bestDay.value} kcal' : '',
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
