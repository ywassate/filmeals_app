import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/user_model.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/presentation/screens/meals/add_meal_screen.dart';
import 'package:intl/intl.dart';

class HomeTab extends StatefulWidget {
  final UserRepository userRepository;
  final MealRepository mealRepository;

  const HomeTab({
    super.key,
    required this.userRepository,
    required this.mealRepository,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  UserModel? _user;
  List<MealModel> _todayMeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await widget.userRepository.getCurrentUser();
      if (user != null) {
        final todayMeals = await widget.mealRepository.getTodayMeals(user.id);

        setState(() {
          _user = user;
          _todayMeals = todayMeals;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int _calculateTotalCalories() {
    return _todayMeals.fold(0, (sum, meal) => sum + meal.calories);
  }

  int _calculateTotalProtein() {
    return _todayMeals.fold(0.0, (sum, meal) => sum + meal.protein).toInt();
  }

  int _calculateTotalCarbs() {
    return _todayMeals.fold(0.0, (sum, meal) => sum + meal.carbs).toInt();
  }

  int _calculateTotalFat() {
    return _todayMeals.fold(0.0, (sum, meal) => sum + meal.fat).toInt();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user data found'),
        ),
      );
    }

    final totalCalories = _calculateTotalCalories();
    final caloriesRemaining = _user!.dailyCalorieGoal - totalCalories;
    final progress = totalCalories / _user!.dailyCalorieGoal;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_user!.name}!',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM d').format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // Calories Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Calories',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$totalCalories',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayMedium
                                              ?.copyWith(
                                                color: AppTheme.primaryColor,
                                              ),
                                        ),
                                        TextSpan(
                                          text: ' / ${_user!.dailyCalorieGoal}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: AppTheme.textSecondaryColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    caloriesRemaining >= 0
                                        ? '$caloriesRemaining cal remaining'
                                        : '${caloriesRemaining.abs()} cal over',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: caloriesRemaining >= 0
                                              ? AppTheme.secondaryColor
                                              : AppTheme.accentColor,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: CircularProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        strokeWidth: 8,
                                        backgroundColor: AppTheme.borderColor,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          caloriesRemaining >= 0
                                              ? AppTheme.primaryColor
                                              : AppTheme.accentColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _MacroWidget(
                                label: 'Protein',
                                value: _calculateTotalProtein(),
                                unit: 'g',
                                color: AppTheme.secondaryColor,
                              ),
                              _MacroWidget(
                                label: 'Carbs',
                                value: _calculateTotalCarbs(),
                                unit: 'g',
                                color: AppTheme.primaryColor,
                              ),
                              _MacroWidget(
                                label: 'Fat',
                                value: _calculateTotalFat(),
                                unit: 'g',
                                color: AppTheme.gainWeightColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Quick Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.flag,
                              title: 'Goal',
                              value: _getGoalText(_user!.goal),
                              color: _getGoalColor(_user!.goal),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.monitor_weight,
                              title: 'Current Weight',
                              value: '${_user!.weight} kg',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_user!.targetWeight != null)
                        _StatCard(
                          icon: Icons.track_changes,
                          title: 'Target Weight',
                          value: '${_user!.targetWeight} kg',
                          color: AppTheme.maintainWeightColor,
                        ),
                    ],
                  ),
                ),
              ),

              // Today's Meals Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Meals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddMealScreen(
                                mealRepository: widget.mealRepository,
                                userRepository: widget.userRepository,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadData(); // Refresh data
                          }
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ),

              // Meals List
              _todayMeals.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.restaurant_outlined,
                                  size: 48,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No meals logged today',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start tracking your meals to see your progress',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final meal = _todayMeals[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                            child: _MealCard(meal: meal),
                          );
                        },
                        childCount: _todayMeals.length,
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  String _getGoalText(GoalType goal) {
    switch (goal) {
      case GoalType.loseWeight:
        return 'Lose Weight';
      case GoalType.maintainWeight:
        return 'Maintain';
      case GoalType.gainWeight:
        return 'Gain Weight';
    }
  }

  Color _getGoalColor(GoalType goal) {
    switch (goal) {
      case GoalType.loseWeight:
        return AppTheme.loseWeightColor;
      case GoalType.maintainWeight:
        return AppTheme.maintainWeightColor;
      case GoalType.gainWeight:
        return AppTheme.gainWeightColor;
    }
  }
}

class _MacroWidget extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;

  const _MacroWidget({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$value',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextSpan(
                text: unit,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealModel meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getMealTypeColor(meal.mealType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getMealTypeIcon(meal.mealType),
            color: _getMealTypeColor(meal.mealType),
          ),
        ),
        title: Text(
          meal.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${meal.calories} cal • P: ${meal.protein}g • C: ${meal.carbs}g • F: ${meal.fat}g',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Text(
          _getMealTypeText(meal.mealType),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getMealTypeColor(meal.mealType),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  IconData _getMealTypeIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.wb_cloudy;
      case MealType.dinner:
        return Icons.nights_stay;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  Color _getMealTypeColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return AppTheme.gainWeightColor;
      case MealType.lunch:
        return AppTheme.primaryColor;
      case MealType.dinner:
        return AppTheme.maintainWeightColor;
      case MealType.snack:
        return AppTheme.secondaryColor;
    }
  }

  String _getMealTypeText(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }
}
