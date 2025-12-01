import 'package:flutter/material.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/spoonacular_service.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:uuid/uuid.dart';

/// Écran d'ajout de repas personnalisé avec calcul automatique des macros
class CustomMealScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final UserRepository userRepository;
  final MealType? initialMealType;

  const CustomMealScreen({
    super.key,
    required this.mealRepository,
    required this.userRepository,
    this.initialMealType,
  });

  @override
  State<CustomMealScreen> createState() => _CustomMealScreenState();
}

class _CustomMealScreenState extends State<CustomMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();

  MealType _selectedMealType = MealType.breakfast;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isCalculating = false;

  // Nutritional values (will be calculated from ingredients)
  int _calories = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;

  final SpoonacularService _apiService = SpoonacularService();

  @override
  void initState() {
    super.initState();
    if (widget.initialMealType != null) {
      _selectedMealType = widget.initialMealType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _calculateNutrition() async {
    if (_ingredientsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter ingredients first'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.textPrimaryColor,
        ),
      );
      return;
    }

    setState(() => _isCalculating = true);

    try {
      // Parse ingredients and calculate nutrition
      final ingredientsText = _ingredientsController.text.trim();
      final ingredientLines = ingredientsText.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      int totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final line in ingredientLines) {
        try {
          // Search for the ingredient
          final results = await _apiService.searchIngredients(
            query: line,
            number: 1,
          );

          if (results.isNotEmpty) {
            // Get nutrition for default amount (100g)
            final nutrition = await _apiService.getIngredientNutrition(
              ingredientId: results.first.id,
              amount: 100,
              unit: 'g',
            );

            totalCalories += nutrition.calories;
            totalProtein += nutrition.protein;
            totalCarbs += nutrition.carbs;
            totalFat += nutrition.fat;
          }
        } catch (e) {
          print('Error calculating nutrition for ingredient: $line - $e');
        }
      }

      setState(() {
        _calories = totalCalories;
        _protein = totalProtein;
        _carbs = totalCarbs;
        _fat = totalFat;
        _isCalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nutrition calculated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.textPrimaryColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCalculating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating nutrition: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.textPrimaryColor,
          ),
        );
      }
    }
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_calories == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate nutrition first'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.textPrimaryColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await widget.userRepository.getCurrentUser();
      String? userId;

      if (user == null) {
        final centralData = widget.userRepository.getCentralDataDirect();
        if (centralData != null) {
          userId = centralData.id;
        }
      } else {
        userId = user.id;
      }

      if (userId == null) {
        throw Exception('No user found');
      }

      final now = DateTime.now();
      final meal = MealModel(
        id: const Uuid().v4(),
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        mealType: _selectedMealType,
        calories: _calories,
        protein: _protein,
        carbs: _carbs,
        fat: _fat,
        date: _selectedDate,
        createdAt: now,
        updatedAt: now,
      );

      await widget.mealRepository.addMeal(meal);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.textPrimaryColor,
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
                      'Add Meal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  if (_isSaving)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textPrimaryColor,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _saveMeal,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppTheme.textPrimaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal Type Selector
                      const Text(
                        'Meal Type',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMealTypeSelector(),
                      const SizedBox(height: 24),

                      // Name Field
                      _buildTextField(
                        controller: _nameController,
                        label: 'Name',
                        hint: 'e.g., Chicken Salad',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Description Field
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description (optional)',
                        hint: 'Add notes about your meal...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Ingredients Field
                      _buildTextField(
                        controller: _ingredientsController,
                        label: 'Ingredients',
                        hint: 'e.g.,\n100g chicken breast\n50g lettuce\n1 tbsp olive oil',
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter ingredients';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Calculate Nutrition Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isCalculating ? null : _calculateNutrition,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceColor,
                            foregroundColor: AppTheme.textPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isCalculating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                )
                              : const Text(
                                  'Calculate Nutrition',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nutrition Results
                      if (_calories > 0) ...[
                        const Text(
                          'Nutrition',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildNutritionRow('Calories', '$_calories kcal'),
                              const SizedBox(height: 12),
                              _buildNutritionRow('Protein', '${_protein.toStringAsFixed(1)}g'),
                              const SizedBox(height: 12),
                              _buildNutritionRow('Carbs', '${_carbs.toStringAsFixed(1)}g'),
                              const SizedBox(height: 12),
                              _buildNutritionRow('Fat', '${_fat.toStringAsFixed(1)}g'),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
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

  Widget _buildMealTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MealType.values.map((type) {
          final isSelected = _selectedMealType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMealType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.textPrimaryColor : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type.name[0].toUpperCase() + type.name.substring(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}
