import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/spoonacular_service.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:uuid/uuid.dart';

class AddCustomMealScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final UserRepository userRepository;
  final MealType? initialMealType;

  const AddCustomMealScreen({
    super.key,
    required this.mealRepository,
    required this.userRepository,
    this.initialMealType,
  });

  @override
  State<AddCustomMealScreen> createState() => _AddCustomMealScreenState();
}

class _AddCustomMealScreenState extends State<AddCustomMealScreen> {
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
    final result = await showDialog<IngredientItem>(
      context: context,
      builder: (context) => _AddIngredientDialog(
        spoonacularService: _spoonacularService,
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
          .map((ing) =>
              '${ing.amount} ${ing.unit} ${ing.name}')
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
            content: Text('Error adding meal: $e'),
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
        title: const Text('Add Custom Meal'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                // Meal Type Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _MealTypeChip(
                        label: 'Breakfast',
                        icon: Icons.wb_sunny,
                        isSelected: _selectedMealType == MealType.breakfast,
                        onTap: () {
                          setState(() => _selectedMealType = MealType.breakfast);
                        },
                      ),
                      _MealTypeChip(
                        label: 'Lunch',
                        icon: Icons.wb_cloudy,
                        isSelected: _selectedMealType == MealType.lunch,
                        onTap: () {
                          setState(() => _selectedMealType = MealType.lunch);
                        },
                      ),
                      _MealTypeChip(
                        label: 'Dinner',
                        icon: Icons.nights_stay,
                        isSelected: _selectedMealType == MealType.dinner,
                        onTap: () {
                          setState(() => _selectedMealType = MealType.dinner);
                        },
                      ),
                      _MealTypeChip(
                        label: 'Snack',
                        icon: Icons.cookie,
                        isSelected: _selectedMealType == MealType.snack,
                        onTap: () {
                          setState(() => _selectedMealType = MealType.snack);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Meal Name
                TextField(
                  controller: _mealNameController,
                  decoration: const InputDecoration(
                    hintText: 'Meal name (optional)',
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
              ],
            ),
          ),

          // Nutrition Summary
          if (_ingredients.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
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
              child: Column(
                children: [
                  Text(
                    'Total Nutrition',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NutrientSummary(
                        label: 'Cal',
                        value: _totalCalories.toString(),
                      ),
                      _NutrientSummary(
                        label: 'Protein',
                        value: '${_totalProtein.toStringAsFixed(1)}g',
                      ),
                      _NutrientSummary(
                        label: 'Carbs',
                        value: '${_totalCarbs.toStringAsFixed(1)}g',
                      ),
                      _NutrientSummary(
                        label: 'Fat',
                        value: '${_totalFat.toStringAsFixed(1)}g',
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Ingredients List
          Expanded(
            child: _ingredients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 64,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ingredients added',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add ingredients',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _ingredients[index];
                      return _IngredientCard(
                        ingredient: ingredient,
                        onDelete: () {
                          setState(() {
                            _ingredients.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Ingredient'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveMeal,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Saving...' : 'Save Meal'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Classes
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

class _MealTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealTypeChip({
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
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

class _NutrientSummary extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientSummary({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final IngredientItem ingredient;
  final VoidCallback onDelete;

  const _IngredientCard({
    required this.ingredient,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fastfood,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ingredient.amount} ${ingredient.unit}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (ingredient.nutrition != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${ingredient.nutrition!.calories} cal • P:${ingredient.nutrition!.protein.toStringAsFixed(1)}g C:${ingredient.nutrition!.carbs.toStringAsFixed(1)}g F:${ingredient.nutrition!.fat.toStringAsFixed(1)}g',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.accentColor,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddIngredientDialog extends StatefulWidget {
  final SpoonacularService spoonacularService;

  const _AddIngredientDialog({
    required this.spoonacularService,
  });

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '1');

  List<IngredientSearchResult> _searchResults = [];
  IngredientSearchResult? _selectedIngredient;
  IngredientNutrition? _nutrition;
  String _selectedUnit = 'unit';
  List<String> _availableUnits = ['unit', 'g', 'ml', 'cup', 'oz'];
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
        _availableUnits = nutrition.possibleUnits.isNotEmpty
            ? nutrition.possibleUnits
            : _availableUnits;
        _isLoadingNutrition = false;
      });
    } catch (e) {
      setState(() => _isLoadingNutrition = false);
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Ingredient',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Search Field
            TextField(
              controller: _searchController,
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
              ),
              onSubmitted: (_) => _searchIngredients(),
            ),
            const SizedBox(height: 12),

            // Search Results
            if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final ingredient = _searchResults[index];
                    return ListTile(
                      title: Text(ingredient.name),
                      onTap: () => _selectIngredient(ingredient),
                    );
                  },
                ),
              ),

            // Amount & Unit
            if (_selectedIngredient != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                      ),
                      onChanged: (_) => _updateNutrition(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
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
            ],

            // Nutrition Preview
            if (_nutrition != null && !_isLoadingNutrition) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Nutrition',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_nutrition!.calories} cal • P:${_nutrition!.protein.toStringAsFixed(1)}g C:${_nutrition!.carbs.toStringAsFixed(1)}g F:${_nutrition!.fat.toStringAsFixed(1)}g',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],

            if (_isLoadingNutrition)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),

            const SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
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
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
