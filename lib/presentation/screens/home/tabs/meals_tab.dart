// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/presentation/screens/meals/add_meal_screen.dart';
import 'package:intl/intl.dart';

class MealsTab extends StatefulWidget {
  final MealRepository mealRepository;
  final UserRepository userRepository;

  const MealsTab({
    super.key,
    required this.mealRepository,
    required this.userRepository,
  });

  @override
  State<MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends State<MealsTab> {
  List<MealModel> _meals = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    try {
      // Get user first to get userId
      final user = await widget.userRepository.getCurrentUser();
      if (user != null) {
        // Get meals for the selected date
        final filteredMeals = await widget.mealRepository.getMealsByDate(
          user.id,
          _selectedDate,
        );

        // Sort by meal type and time
        filteredMeals.sort((a, b) {
          final typeOrder = {
            MealType.breakfast: 1,
            MealType.lunch: 2,
            MealType.snack: 3,
            MealType.dinner: 4,
          };
          return typeOrder[a.mealType]!.compareTo(typeOrder[b.mealType]!);
        });

        setState(() {
          _meals = filteredMeals;
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
    return _meals.fold(0, (sum, meal) => sum + meal.calories);
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday =
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Date Selector
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Meals',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isToday
                                            ? 'Today'
                                            : DateFormat(
                                                'EEEE',
                                              ).format(_selectedDate),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        DateFormat(
                                          'MMM d, yyyy',
                                        ).format(_selectedDate),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Total Calories Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Calories',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_calculateTotalCalories()} kcal',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Meals List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _meals.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_outlined,
                              size: 64,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              isToday
                                  ? 'No meals logged today'
                                  : 'No meals logged for this date',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Start tracking your meals by tapping the + button',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
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
                                  _loadMeals(); // Refresh data
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Meal'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMeals,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _meals.length,
                        itemBuilder: (context, index) {
                          return _MealCard(
                            meal: _meals[index],
                            onDelete: () async {
                              await widget.mealRepository.deleteMeal(
                                _meals[index].id,
                              );
                              _loadMeals();
                            },
                          );
                        },
                      ),
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
  final VoidCallback onDelete;

  const _MealCard({required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            // TODO: View meal details
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getMealTypeColor(
                          meal.mealType,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getMealTypeIcon(meal.mealType),
                        color: _getMealTypeColor(meal.mealType),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMealTypeText(meal.mealType),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _getMealTypeColor(meal.mealType),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meal.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.accentColor,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Meal'),
                            content: const Text(
                              'Are you sure you want to delete this meal?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete();
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NutrientInfo(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: '${meal.calories}',
                        color: AppTheme.accentColor,
                      ),
                      _NutrientInfo(
                        icon: Icons.fitness_center,
                        label: 'Protein',
                        value: '${meal.protein}g',
                        color: AppTheme.secondaryColor,
                      ),
                      _NutrientInfo(
                        icon: Icons.grain,
                        label: 'Carbs',
                        value: '${meal.carbs}g',
                        color: AppTheme.primaryColor,
                      ),
                      _NutrientInfo(
                        icon: Icons.water_drop,
                        label: 'Fat',
                        value: '${meal.fat}g',
                        color: AppTheme.gainWeightColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

class _NutrientInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _NutrientInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
