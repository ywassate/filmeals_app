import 'package:flutter/material.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/presentation/screens/meals/edit_meal_screen.dart';
import 'package:intl/intl.dart';

/// Historique des repas avec design minimaliste
class MealsHistoryMinimal extends StatefulWidget {
  final MealRepository mealRepository;
  final UserRepository userRepository;
  final LocalStorageService storageService;

  const MealsHistoryMinimal({
    super.key,
    required this.mealRepository,
    required this.userRepository,
    required this.storageService,
  });

  @override
  State<MealsHistoryMinimal> createState() => _MealsHistoryMinimalState();
}

class _MealsHistoryMinimalState extends State<MealsHistoryMinimal> {
  List<MealModel> _allMeals = [];
  List<MealModel> _filteredMeals = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedMealType;
  bool _hasChanges = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);

    try {
      // Get user ID from centralDataBox (same as tabs)
      final centralData = widget.storageService.centralDataBox.get('currentUser');
      final userId = centralData?.id ?? 'default_user';

      print('👤 MealsHistoryMinimal using user ID: $userId');

      _allMeals = await widget.mealRepository.getUserMeals(userId);
      _applyFilters();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading meals: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMeals = _allMeals.where((meal) {
        if (_searchQuery.isNotEmpty &&
            !meal.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }

        if (_selectedMealType != null && meal.mealType.name != _selectedMealType) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedMealType = null;
      _searchController.clear();
      _applyFilters();
    });
  }

  Future<void> _deleteMeal(MealModel meal) async {
    try {
      await widget.mealRepository.deleteMeal(meal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Meal deleted'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.textPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      await _loadMeals();
      _hasChanges = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.textPrimaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                    onTap: () => Navigator.pop(context, _hasChanges),
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
                      'History',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  if (_selectedMealType != null)
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppTheme.textPrimaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search meals...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondaryColor.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppTheme.textSecondaryColor,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ),

            // Filtres par type
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Breakfast', 'breakfast'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Lunch', 'lunch'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Dinner', 'dinner'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Snack', 'snack'),
                  ],
                ),
              ),
            ),

            // Liste
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.textPrimaryColor,
                        strokeWidth: 2,
                      ),
                    )
                  : _filteredMeals.isEmpty
                      ? _buildEmptyState()
                      : _buildMealsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? type) {
    final isSelected = _selectedMealType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMealType = type;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textPrimaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No meals found',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    final groupedMeals = <String, List<MealModel>>{};
    for (final meal in _filteredMeals) {
      final dateKey = DateFormat('yyyy-MM-dd').format(meal.date);
      groupedMeals.putIfAbsent(dateKey, () => []).add(meal);
    }

    final sortedDates = groupedMeals.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final date = DateTime.parse(dateKey);
        final meals = groupedMeals[dateKey]!;
        final totalCalories = meals.fold(0, (sum, meal) => sum + meal.calories);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '$totalCalories kcal',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            ...meals.map((meal) => _buildMealCard(meal)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildMealCard(MealModel meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              _getMealIcon(meal.mealType.name),
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

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.wb_sunny_outlined;
      case 'lunch':
        return Icons.wb_twilight_outlined;
      case 'dinner':
        return Icons.nights_stay_outlined;
      case 'snack':
        return Icons.coffee_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE d MMM', 'fr_FR').format(date);
    }
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
                leading: const Icon(Icons.edit_outlined, color: AppTheme.textPrimaryColor),
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
                        mealRepository: widget.mealRepository,
                      ),
                    ),
                  );
                  if (result == true) {
                    await _loadMeals();
                    _hasChanges = true;
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.textPrimaryColor),
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
