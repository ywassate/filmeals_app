import 'package:flutter/material.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/widgets/page_banner.dart';
import 'package:filmeals_app/core/widgets/minimal_stat_card.dart';
import 'package:filmeals_app/core/utils/date_formatter.dart';
import 'package:filmeals_app/core/utils/meal_formatter.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/presentation/screens/meals/custom_meal_screen.dart';
import 'package:filmeals_app/presentation/screens/meals/edit_meal_screen.dart';
import 'package:filmeals_app/presentation/screens/meals/meals_history_minimal.dart';
import 'package:filmeals_app/presentation/screens/meals/weekly_stats_screen.dart';
import 'package:intl/intl.dart';

/// Version minimaliste et monochrome de l'onglet Repas
class MealsTab extends StatefulWidget {
  final LocalStorageService storageService;

  const MealsTab({super.key, required this.storageService});

  @override
  State<MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends State<MealsTab> {
  late MealRepository _mealRepository;
  late UserRepository _userRepository;

  List<MealModel> _todayMeals = [];
  int _todayCalories = 0;
  int _goalCalories = 2200;
  double _todayProtein = 0;
  double _todayCarbs = 0;
  double _todayFat = 0;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _mealRepository = MealRepository(widget.storageService);
    _userRepository = UserRepository(widget.storageService);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les données quand on revient sur cette page
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get user ID from centralDataBox (same as TestDataService)
      final centralData =
          widget.storageService.centralDataBox.get('currentUser');
      final userId = centralData?.id ?? 'default_user';

      print('👤 MealsTab using user ID: $userId');

      final mealsSensorData = widget.storageService.mealsSensorBox.values
          .where((data) => data.userId == userId)
          .firstOrNull;
      if (mealsSensorData != null) {
        _goalCalories = mealsSensorData.dailyCalorieGoal;
      }

      _todayMeals = await _mealRepository.getMealsByDate(userId, _selectedDate);
      _todayCalories = _todayMeals.fold(0, (sum, meal) => sum + meal.calories);
      _todayProtein = _todayMeals.fold(0.0, (sum, meal) => sum + meal.protein);
      _todayCarbs = _todayMeals.fold(0.0, (sum, meal) => sum + meal.carbs);
      _todayFat = _todayMeals.fold(0.0, (sum, meal) => sum + meal.fat);

      setState(() => _isLoading = false);
    } catch (e) {
      print('ERROR loading meals data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToAddMeal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomMealScreen(
          mealRepository: _mealRepository,
          userRepository: _userRepository,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteMeal(MealModel meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le repas'),
        content: Text('Voulez-vous vraiment supprimer "${meal.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textPrimaryColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _mealRepository.deleteMeal(meal.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Repas supprimé'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.textPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.textPrimaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header fixe
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildHeader(),
            ),
            const SizedBox(height: 16),

            // Contenu scrollable
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: AppTheme.textPrimaryColor,
                      strokeWidth: 2,
                    ))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date
                            Text(
                              DateFormatter.getFormattedDate(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Bannière
                            PageBanner(
                              title: 'Eat Healthy',
                              subtitle: 'Nutrition is the key to wellness',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFf093fb), Color(0xFFF5576c)],
                              ),
                              imagePath: 'assets/images/carousel/nutrition.png',
                            ),
                            const SizedBox(height: 32),
                            // Stats principales
                            _buildMinimalStats(),
                            const SizedBox(height: 40),

                            // Macros
                            const Text(
                              'Macros',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildMacros(),
                            const SizedBox(height: 40),

                            // Repas
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Meals',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  '$_todayCalories / $_goalCalories',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildMealsList(),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Nutrition',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
            letterSpacing: -1.5,
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealsHistoryMinimal(
                      mealRepository: _mealRepository,
                      userRepository: _userRepository,
                      storageService: widget.storageService,
                    ),
                  ),
                );
                // Recharger les données si des modifications ont été faites
                if (result == true && mounted) {
                  await _loadData();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyStatsScreen(
                      mealRepository: _mealRepository,
                      userRepository: _userRepository,
                      storageService: widget.storageService,
                    ),
                  ),
                );
                // Recharger les données si des modifications ont été faites
                if (result == true && mounted) {
                  await _loadData();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _navigateToAddMeal,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppTheme.textPrimaryColor,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalStats() {
    final progress = _goalCalories > 0
        ? (_todayCalories / _goalCalories).clamp(0.0, 1.0)
        : 0.0;
    final remaining = _goalCalories - _todayCalories;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calories',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _todayCalories.toString(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '/ $_goalCalories',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.backgroundColor,
              valueColor:
                  const AlwaysStoppedAnimation(AppTheme.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            remaining > 0
                ? '$remaining kcal remaining'
                : '${-remaining} kcal over',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacros() {
    final proteinGoal = (_goalCalories * 0.25 / 4).round();
    final carbsGoal = (_goalCalories * 0.50 / 4).round();
    final fatGoal = (_goalCalories * 0.25 / 9).round();

    return Row(
      children: [
        Expanded(
          child: _buildCircularMacro(
            label: 'Protein',
            value: _todayProtein.toInt(),
            goal: proteinGoal,
            unit: 'g',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCircularMacro(
            label: 'Carbs',
            value: _todayCarbs.toInt(),
            goal: carbsGoal,
            unit: 'g',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCircularMacro(
            label: 'Fats',
            value: _todayFat.toInt(),
            goal: fatGoal,
            unit: 'g',
          ),
        ),
      ],
    );
  }

  Widget _buildCircularMacro({
    required String label,
    required int value,
    required int goal,
    required String unit,
  }) {
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercle de fond
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.backgroundColor,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.backgroundColor),
                  ),
                ),
                // Cercle de progression
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.textPrimaryColor),
                  ),
                ),
                // Valeur au centre
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$goal$unit',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    if (_todayMeals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.restaurant_outlined,
                size: 48,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No meals today',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondaryColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _todayMeals.map((meal) => _buildMealItem(meal)).toList(),
    );
  }

  Widget _buildMealItem(MealModel meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              MealFormatter.getMealIcon(meal.mealType),
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'P ${meal.protein.toInt()}g • C ${meal.carbs.toInt()}g • F ${meal.fat.toInt()}g',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${meal.calories}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showMealOptions(meal),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.more_horiz,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showMealOptions(MealModel meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: AppTheme.textPrimaryColor),
                title: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditMealScreen(
                        meal: meal,
                        mealRepository: _mealRepository,
                      ),
                    ),
                  );
                  if (result == true) _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.textPrimaryColor),
                title: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMeal(meal);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
