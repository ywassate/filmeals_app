import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/user_model.dart';

class GoalPage extends StatelessWidget {
  final GoalType? selectedGoal;
  final Function(GoalType) onGoalSelected;

  const GoalPage({
    super.key,
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quel est votre objectif ?',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Choisissez votre objectif principal',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),
        _buildGoalCard(
          context,
          title: 'Perdre du poids',
          description: 'Créer un déficit calorique pour perdre du poids progressivement',
          icon: Icons.trending_down,
          color: AppTheme.loseWeightColor,
          goalType: GoalType.loseWeight,
          isSelected: selectedGoal == GoalType.loseWeight,
        ),
        const SizedBox(height: 16),
        _buildGoalCard(
          context,
          title: 'Maintenir mon poids',
          description: 'Équilibrer les calories pour maintenir votre poids actuel',
          icon: Icons.remove_circle_outline,
          color: AppTheme.maintainWeightColor,
          goalType: GoalType.maintainWeight,
          isSelected: selectedGoal == GoalType.maintainWeight,
        ),
        const SizedBox(height: 16),
        _buildGoalCard(
          context,
          title: 'Prendre du poids',
          description: 'Créer un surplus calorique pour gagner de la masse',
          icon: Icons.trending_up,
          color: AppTheme.gainWeightColor,
          goalType: GoalType.gainWeight,
          isSelected: selectedGoal == GoalType.gainWeight,
        ),
      ],
    );
  }

  Widget _buildGoalCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required GoalType goalType,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onGoalSelected(goalType),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
