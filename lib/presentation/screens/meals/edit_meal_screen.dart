import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';

class EditMealScreen extends StatefulWidget {
  final MealModel meal;
  final MealRepository mealRepository;

  const EditMealScreen({
    super.key,
    required this.meal,
    required this.mealRepository,
  });

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late MealType _selectedMealType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.name);
    _descriptionController = TextEditingController(text: widget.meal.description);
    _caloriesController = TextEditingController(text: widget.meal.calories.toString());
    _proteinController = TextEditingController(text: widget.meal.protein.toString());
    _carbsController = TextEditingController(text: widget.meal.carbs.toString());
    _fatController = TextEditingController(text: widget.meal.fat.toString());
    _selectedMealType = widget.meal.mealType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (_nameController.text.trim().isEmpty) {
      MinimalSnackBar.showWarning(
        context,
        title: 'Attention',
        message: 'Le nom du repas est requis',
      );
      return;
    }

    final calories = int.tryParse(_caloriesController.text) ?? 0;
    if (calories <= 0) {
      MinimalSnackBar.showWarning(
        context,
        title: 'Attention',
        message: 'Les calories doivent être supérieures à 0',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedMeal = widget.meal.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        calories: calories,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        mealType: _selectedMealType,
        updatedAt: DateTime.now(),
      );

      await widget.mealRepository.updateMeal(updatedMeal);

      if (mounted) {
        Navigator.pop(context, true);
        MinimalSnackBar.showSuccess(
          context,
          title: 'Succès',
          message: 'Repas mis à jour avec succès',
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        MinimalSnackBar.showError(
          context,
          title: 'Erreur',
          message: 'Impossible de mettre à jour le repas',
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
                      'Edit Meal',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Meal Type Selector
            const Text(
              'Type de repas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _MealTypePill(
                    label: 'Breakfast',
                    icon: Icons.wb_sunny,
                    isSelected: _selectedMealType == MealType.breakfast,
                    onTap: () => setState(() => _selectedMealType = MealType.breakfast),
                  ),
                  _MealTypePill(
                    label: 'Lunch',
                    icon: Icons.wb_cloudy,
                    isSelected: _selectedMealType == MealType.lunch,
                    onTap: () => setState(() => _selectedMealType = MealType.lunch),
                  ),
                  _MealTypePill(
                    label: 'Dinner',
                    icon: Icons.nights_stay,
                    isSelected: _selectedMealType == MealType.dinner,
                    onTap: () => setState(() => _selectedMealType = MealType.dinner),
                  ),
                  _MealTypePill(
                    label: 'Snack',
                    icon: Icons.cookie,
                    isSelected: _selectedMealType == MealType.snack,
                    onTap: () => setState(() => _selectedMealType = MealType.snack),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            const Text(
              'Nom du repas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Ex: Salade César',
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'Description (optionnel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ex: Salade avec poulet grillé',
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nutrition
            const Text(
              'Informations nutritionnelles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Calories
            _NutritionField(
              label: 'Calories',
              controller: _caloriesController,
              unit: 'kcal',
              icon: Icons.local_fire_department,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 12),

            // Protein
            _NutritionField(
              label: 'Protéines',
              controller: _proteinController,
              unit: 'g',
              icon: Icons.fitness_center,
              color: Colors.red,
            ),
            const SizedBox(height: 12),

            // Carbs
            _NutritionField(
              label: 'Glucides',
              controller: _carbsController,
              unit: 'g',
              icon: Icons.grain,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),

            // Fat
            _NutritionField(
              label: 'Lipides',
              controller: _fatController,
              unit: 'g',
              icon: Icons.water_drop,
              color: Colors.green,
            ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
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

class _NutritionField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final IconData icon;
  final Color color;

  const _NutritionField({
    required this.label,
    required this.controller,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixText: unit,
                    suffixStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
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
