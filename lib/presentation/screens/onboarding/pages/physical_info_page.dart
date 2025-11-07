import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/user_model.dart';

class PhysicalInfoPage extends StatefulWidget {
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController targetWeightController;
  final GoalType? selectedGoal;

  const PhysicalInfoPage({
    super.key,
    required this.heightController,
    required this.weightController,
    required this.targetWeightController,
    this.selectedGoal,
  });

  @override
  State<PhysicalInfoPage> createState() => _PhysicalInfoPageState();
}

class _PhysicalInfoPageState extends State<PhysicalInfoPage> {
  @override
  void initState() {
    super.initState();
    widget.weightController.addListener(_onWeightChanged);
    widget.targetWeightController.addListener(_onWeightChanged);
  }

  @override
  void dispose() {
    widget.weightController.removeListener(_onWeightChanged);
    widget.targetWeightController.removeListener(_onWeightChanged);
    super.dispose();
  }

  void _onWeightChanged() {
    setState(() {});
  }

  int? _calculateTargetWeight() {
    if (widget.weightController.text.isEmpty ||
        widget.targetWeightController.text.isEmpty) {
      return null;
    }

    final currentWeight = int.tryParse(widget.weightController.text);
    final kgToChange = int.tryParse(widget.targetWeightController.text);

    if (currentWeight == null || kgToChange == null) return null;

    if (widget.selectedGoal == GoalType.loseWeight) {
      return currentWeight - kgToChange;
    } else if (widget.selectedGoal == GoalType.gainWeight) {
      return currentWeight + kgToChange;
    }

    return currentWeight;
  }

  String? _getTargetWeightMessage() {
    final targetWeight = _calculateTargetWeight();
    if (targetWeight == null) return null;

    return '🎯 Poids cible: $targetWeight kg';
  }

  Color _getGoalColor() {
    switch (widget.selectedGoal) {
      case GoalType.loseWeight:
        return AppTheme.loseWeightColor;
      case GoalType.gainWeight:
        return AppTheme.gainWeightColor;
      case GoalType.maintainWeight:
        return AppTheme.maintainWeightColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations physiques',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Aidez-nous à calculer vos besoins caloriques',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Taille',
                  hintText: '170',
                  suffixText: 'cm',
                  prefixIcon: Icon(Icons.height),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: widget.weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Poids actuel',
                  hintText: '70',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (widget.selectedGoal != GoalType.maintainWeight) ...[
          TextField(
            controller: widget.targetWeightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: widget.selectedGoal == GoalType.loseWeight
                  ? 'Combien de kg voulez-vous perdre ?'
                  : 'Combien de kg voulez-vous gagner ?',
              hintText: '5',
              suffixText: 'kg',
              prefixIcon: Icon(
                widget.selectedGoal == GoalType.loseWeight
                    ? Icons.trending_down
                    : Icons.trending_up,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Afficher le poids cible calculé
        if (_getTargetWeightMessage() != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getGoalColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getGoalColor().withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag_circle,
                  color: _getGoalColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTargetWeightMessage()!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getGoalColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ces informations nous permettent de calculer votre métabolisme de base et vos besoins caloriques quotidiens',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
