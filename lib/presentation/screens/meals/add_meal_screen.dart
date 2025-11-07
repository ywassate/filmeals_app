import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/spoonacular_service.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/presentation/screens/meals/add_custom_meal_screen_v2.dart';
import 'package:uuid/uuid.dart';

class AddMealScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final UserRepository userRepository;
  final MealType? initialMealType;

  const AddMealScreen({
    super.key,
    required this.mealRepository,
    required this.userRepository,
    this.initialMealType,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final SpoonacularService _spoonacularService = SpoonacularService();
  final TextEditingController _searchController = TextEditingController();

  List<RecipeSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  MealType _selectedMealType = MealType.breakfast;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? MealType.breakfast;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMeals() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await _spoonacularService.searchRecipes(
        query: _searchController.text.trim(),
        number: 20,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching meals: $e'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    }
  }

  Future<void> _addMealToUser(RecipeSearchResult recipe) async {
    try {
      final user = await widget.userRepository.getCurrentUser();
      if (user == null) {
        throw Exception('No user found');
      }

      // Show serving selection dialog
      final servings = await _showServingDialog(recipe.servings ?? 1);
      if (servings == null) return;

      // Calculate nutrition based on servings
      final caloriesPerServing = (recipe.calories ?? 0) / (recipe.servings ?? 1);
      final proteinPerServing = (recipe.protein ?? 0) / (recipe.servings ?? 1);
      final carbsPerServing = (recipe.carbs ?? 0) / (recipe.servings ?? 1);
      final fatPerServing = (recipe.fat ?? 0) / (recipe.servings ?? 1);

      final meal = MealModel(
        id: const Uuid().v4(),
        name: recipe.title,
        description: 'Added from Spoonacular',
        calories: (caloriesPerServing * servings).toInt(),
        date: DateTime.now(),
        userId: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mealType: _selectedMealType,
        protein: proteinPerServing * servings,
        carbs: carbsPerServing * servings,
        fat: fatPerServing * servings,
      );

      await widget.mealRepository.addMeal(meal);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal added successfully!'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding meal: $e'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    }
  }

  Future<double?> _showServingDialog(int defaultServings) async {
    double servings = defaultServings.toDouble();

    return showDialog<double>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('How many servings?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${servings.toStringAsFixed(1)} serving(s)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: servings,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    label: servings.toStringAsFixed(1),
                    onChanged: (value) {
                      setDialogState(() {
                        servings = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, servings),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Search Recipes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCustomMealScreenV2(
                      mealRepository: widget.mealRepository,
                      userRepository: widget.userRepository,
                      initialMealType: _selectedMealType,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Custom'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Meal Type Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _MealTypePill(
                  label: 'Breakfast',
                  icon: Icons.wb_sunny,
                  isSelected: _selectedMealType == MealType.breakfast,
                  onTap: () {
                    setState(() {
                      _selectedMealType = MealType.breakfast;
                    });
                  },
                ),
                _MealTypePill(
                  label: 'Lunch',
                  icon: Icons.wb_cloudy,
                  isSelected: _selectedMealType == MealType.lunch,
                  onTap: () {
                    setState(() {
                      _selectedMealType = MealType.lunch;
                    });
                  },
                ),
                _MealTypePill(
                  label: 'Dinner',
                  icon: Icons.nights_stay,
                  isSelected: _selectedMealType == MealType.dinner,
                  onTap: () {
                    setState(() {
                      _selectedMealType = MealType.dinner;
                    });
                  },
                ),
                _MealTypePill(
                  label: 'Snack',
                  icon: Icons.cookie,
                  isSelected: _selectedMealType == MealType.snack,
                  onTap: () {
                    setState(() {
                      _selectedMealType = MealType.snack;
                    });
                  },
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for recipes...',
                  hintStyle: TextStyle(color: AppTheme.textSecondaryColor),
                  prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _hasSearched = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (_) => _searchMeals(),
                onChanged: (value) {
                  setState(() {}); // To show/hide clear button
                },
              ),
            ),
          ),

          // Search Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _searchMeals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
                ),
                child: _isSearching
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search),
                          const SizedBox(width: 8),
                          Text(
                            'Search Recipes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Search Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Find Your Perfect Meal',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                'Search for recipes and discover their nutritional information',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.textSecondaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No Results Found',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try a different search term',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final recipe = _searchResults[index];
                              return _RecipeCard(
                                recipe: recipe,
                                onTap: () => _addMealToUser(recipe),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _MealTypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealTypePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeSearchResult recipe;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: recipe.image != null
                    ? Image.network(
                        recipe.image!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.2),
                                  AppTheme.secondaryColor.withOpacity(0.2),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.2),
                              AppTheme.secondaryColor.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (recipe.calories != null)
                          _NutrientChip(
                            icon: Icons.local_fire_department,
                            label: '${recipe.calories} cal',
                            color: AppTheme.accentColor,
                          ),
                        if (recipe.protein != null)
                          _NutrientChip(
                            icon: Icons.fitness_center,
                            label: '${recipe.protein!.toInt()}g P',
                            color: AppTheme.secondaryColor,
                          ),
                        if (recipe.carbs != null)
                          _NutrientChip(
                            icon: Icons.grain,
                            label: '${recipe.carbs!.toInt()}g C',
                            color: AppTheme.primaryColor,
                          ),
                        if (recipe.fat != null)
                          _NutrientChip(
                            icon: Icons.water_drop,
                            label: '${recipe.fat!.toInt()}g F',
                            color: AppTheme.gainWeightColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NutrientChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
