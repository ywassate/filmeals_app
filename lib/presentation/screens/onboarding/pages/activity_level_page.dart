import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/user_model.dart';

class ActivityLevelPage extends StatelessWidget {
  final ActivityLevel? selectedActivityLevel;
  final Function(ActivityLevel) onActivityLevelSelected;

  const ActivityLevelPage({
    super.key,
    required this.selectedActivityLevel,
    required this.onActivityLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveau d\'activité',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Sélectionnez votre niveau d\'activité physique',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),
        _buildActivityCard(
          context,
          title: 'Sédentaire',
          description: 'Peu ou pas d\'exercice',
          activityLevel: ActivityLevel.sedentary,
          isSelected: selectedActivityLevel == ActivityLevel.sedentary,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          context,
          title: 'Légèrement actif',
          description: 'Exercice léger 1-3 jours/semaine',
          activityLevel: ActivityLevel.lightlyActive,
          isSelected: selectedActivityLevel == ActivityLevel.lightlyActive,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          context,
          title: 'Modérément actif',
          description: 'Exercice modéré 3-5 jours/semaine',
          activityLevel: ActivityLevel.moderatelyActive,
          isSelected: selectedActivityLevel == ActivityLevel.moderatelyActive,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          context,
          title: 'Très actif',
          description: 'Exercice intense 6-7 jours/semaine',
          activityLevel: ActivityLevel.veryActive,
          isSelected: selectedActivityLevel == ActivityLevel.veryActive,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          context,
          title: 'Extrêmement actif',
          description: 'Exercice très intense ou travail physique',
          activityLevel: ActivityLevel.extraActive,
          isSelected: selectedActivityLevel == ActivityLevel.extraActive,
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required String title,
    required String description,
    required ActivityLevel activityLevel,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onActivityLevelSelected(activityLevel),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
