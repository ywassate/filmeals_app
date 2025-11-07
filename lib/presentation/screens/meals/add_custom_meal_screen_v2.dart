import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/spoonacular_service.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:uuid/uuid.dart';

class AddCustomMealScreenV2 extends StatefulWidget {
  final MealRepository mealRepository;
  final UserRepository userRepository;
  final MealType? initialMealType;

  const AddCustomMealScreenV2({
    super.key,
    required this.mealRepository,
    required this.userRepository,
    this.initialMealType,
  });

  @override
  State<AddCustomMealScreenV2> createState() => _AddCustomMealScreenV2State();
}

class _AddCustomMealScreenV2State extends State<AddCustomMealScreenV2> {
  final SpoonacularService _spoonacularService = SpoonacularService();
  final TextEditingController _mealNameController = TextEditingController();
  final List<IngredientItem> _ingredients = [];

  MealType _selectedMealType = MealType.breakfast;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? MealType.breakfast;
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    super.dispose();
  }

  int get _totalCalories => _ingredients.fold(
      0, (sum, item) => sum + (item.nutrition?.calories ?? 0));

  double get _totalProtein => _ingredients.fold(
      0.0, (sum, item) => sum + (item.nutrition?.protein ?? 0));

  double get _totalCarbs => _ingredients.fold(
      0.0, (sum, item) => sum + (item.nutrition?.carbs ?? 0));

  double get _totalFat => _ingredients.fold(
      0.0, (sum, item) => sum + (item.nutrition?.fat ?? 0));

  Future<void> _addIngredient() async {
    final result = await Navigator.push<IngredientItem>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _AddIngredientScreen(
          spoonacularService: _spoonacularService,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _ingredients.add(result);
      });
    }
  }

  Future<void> _saveMeal() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one ingredient'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await widget.userRepository.getCurrentUser();
      if (user == null) throw Exception('No user found');

      final mealName = _mealNameController.text.trim().isEmpty
          ? 'Custom ${_getMealTypeName(_selectedMealType)}'
          : _mealNameController.text.trim();

      final description = _ingredients
          .map((ing) => '${ing.amount} ${ing.unit} ${ing.name}')
          .join(', ');

      final meal = MealModel(
        id: const Uuid().v4(),
        name: mealName,
        description: description,
        calories: _totalCalories,
        date: DateTime.now(),
        userId: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mealType: _selectedMealType,
        protein: _totalProtein,
        carbs: _totalCarbs,
        fat: _totalFat,
      );

      await widget.mealRepository.addMeal(meal);

      if (mounted) {
        Navigator.pop(context, true);
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
            content: Text('Error: $e'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getMealTypeName(MealType type) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Custom Meal'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal Type Pills
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meal Type',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMealTypePill(
                                'Breakfast', Icons.wb_sunny, MealType.breakfast),
                            _buildMealTypePill(
                                'Lunch', Icons.wb_cloudy, MealType.lunch),
                            _buildMealTypePill(
                                'Dinner', Icons.nights_stay, MealType.dinner),
                            _buildMealTypePill(
                                'Snack', Icons.cookie, MealType.snack),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Meal Name
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _mealNameController,
                      decoration: InputDecoration(
                        labelText: 'Meal Name (Optional)',
                        hintText: 'e.g., Morning Protein Boost',
                        prefixIcon: const Icon(Icons.restaurant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Nutrition Summary
                  if (_ingredients.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.analytics, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Total Nutrition',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildNutrientCard(
                                  'Calories',
                                  '$_totalCalories',
                                  'kcal',
                                  Icons.local_fire_department,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNutrientCard(
                                  'Protein',
                                  _totalProtein.toStringAsFixed(1),
                                  'g',
                                  Icons.fitness_center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildNutrientCard(
                                  'Carbs',
                                  _totalCarbs.toStringAsFixed(1),
                                  'g',
                                  Icons.grain,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNutrientCard(
                                  'Fat',
                                  _totalFat.toStringAsFixed(1),
                                  'g',
                                  Icons.water_drop,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Ingredients Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ingredients (${_ingredients.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: _addIngredient,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),

                  // Ingredients List or Empty State
                  if (_ingredients.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_shopping_cart,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ingredients yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add" to start building your meal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ing = _ingredients[index];
                        return _buildIngredientCard(ing, index);
                      },
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Meal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypePill(String label, IconData icon, MealType type) {
    final isSelected = _selectedMealType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedMealType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(IngredientItem ing, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ing.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ing.amount} ${ing.unit}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                if (ing.nutrition != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${ing.nutrition!.calories} cal • P:${ing.nutrition!.protein.toStringAsFixed(1)}g C:${ing.nutrition!.carbs.toStringAsFixed(1)}g F:${ing.nutrition!.fat.toStringAsFixed(1)}g',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey[400],
            onPressed: () {
              setState(() {
                _ingredients.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }
}

// Helper class
class IngredientItem {
  final int id;
  final String name;
  final double amount;
  final String unit;
  final IngredientNutrition? nutrition;

  IngredientItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    this.nutrition,
  });
}

// New Full Screen Add Ingredient
class _AddIngredientScreen extends StatefulWidget {
  final SpoonacularService spoonacularService;

  const _AddIngredientScreen({
    required this.spoonacularService,
  });

  @override
  State<_AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<_AddIngredientScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '1');

  List<IngredientSearchResult> _searchResults = [];
  IngredientSearchResult? _selectedIngredient;
  IngredientNutrition? _nutrition;
  String _selectedUnit = 'unit';
  List<String> _availableUnits = ['unit', 'g', 'ml', 'cup', 'oz', 'piece'];
  bool _isSearching = false;
  bool _isLoadingNutrition = false;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _searchIngredients() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final results = await widget.spoonacularService.searchIngredients(
        query: _searchController.text.trim(),
        number: 10,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _selectIngredient(IngredientSearchResult ingredient) async {
    setState(() {
      _selectedIngredient = ingredient;
      _searchResults = [];
      _searchController.text = ingredient.name;
      _isLoadingNutrition = true;
    });

    try {
      final nutrition = await widget.spoonacularService.getIngredientNutrition(
        ingredientId: ingredient.id,
        amount: double.tryParse(_amountController.text) ?? 1,
        unit: _selectedUnit,
      );

      setState(() {
        _nutrition = nutrition;
        if (nutrition.possibleUnits.isNotEmpty) {
          _availableUnits = nutrition.possibleUnits;
          if (!_availableUnits.contains(_selectedUnit)) {
            _selectedUnit = _availableUnits.first;
          }
        }
        _isLoadingNutrition = false;
      });
    } catch (e) {
      setState(() => _isLoadingNutrition = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading nutrition: $e')),
        );
      }
    }
  }

  Future<void> _updateNutrition() async {
    if (_selectedIngredient == null) return;

    setState(() => _isLoadingNutrition = true);
    try {
      final nutrition = await widget.spoonacularService.getIngredientNutrition(
        ingredientId: _selectedIngredient!.id,
        amount: double.tryParse(_amountController.text) ?? 1,
        unit: _selectedUnit,
      );

      setState(() {
        _nutrition = nutrition;
        _isLoadingNutrition = false;
      });
    } catch (e) {
      setState(() => _isLoadingNutrition = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Ingredient'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedIngredient != null && _nutrition != null
                ? () {
                    Navigator.pop(
                      context,
                      IngredientItem(
                        id: _selectedIngredient!.id,
                        name: _selectedIngredient!.name,
                        amount: double.tryParse(_amountController.text) ?? 1,
                        unit: _selectedUnit,
                        nutrition: _nutrition,
                      ),
                    );
                  }
                : null,
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              autofocus: _selectedIngredient == null,
              decoration: InputDecoration(
                hintText: 'Search ingredient (e.g., eggs, milk)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _searchIngredients(),
            ),
          ),

          // Search Results
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final ingredient = _searchResults[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.food_bank),
                      title: Text(ingredient.name),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectIngredient(ingredient),
                    ),
                  );
                },
              ),
            ),

          // Amount & Unit Section
          if (_selectedIngredient != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount & Unit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => _updateNutrition(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _availableUnits
                                .map((unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedUnit = value);
                                _updateNutrition();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nutrition Preview
                    if (_nutrition != null && !_isLoadingNutrition)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.analytics,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Nutrition Information',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNutrientBox(
                                    'Calories',
                                    '${_nutrition!.calories}',
                                    'kcal',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNutrientBox(
                                    'Protein',
                                    _nutrition!.protein.toStringAsFixed(1),
                                    'g',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNutrientBox(
                                    'Carbs',
                                    _nutrition!.carbs.toStringAsFixed(1),
                                    'g',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNutrientBox(
                                    'Fat',
                                    _nutrition!.fat.toStringAsFixed(1),
                                    'g',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    if (_isLoadingNutrition)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Empty State
          if (_searchResults.isEmpty && _selectedIngredient == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Search for an ingredient',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutrientBox(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
