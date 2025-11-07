import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/user_model.dart';

class SummaryPage extends StatelessWidget {
  final String name;
  final int age;
  final String gender;
  final int height;
  final int weight;
  final int? targetWeight;
  final GoalType goal;
  final ActivityLevel activityLevel;
  final int dailyCalories;

  const SummaryPage({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    this.targetWeight,
    required this.goal,
    required this.activityLevel,
    required this.dailyCalories,
  });

  @override
  Widget build(BuildContext context) {
    final bmi = calculateBMI(weight, height);
    final bmiCategory = determineBMICategory(bmi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre profil est prêt !',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Voici un résumé de vos informations',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),

        // Objectif calorique principal
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'Objectif calorique quotidien',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dailyCalories.toString(),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      'kcal',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getGoalDescription(goal),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Informations personnelles
        _buildInfoCard(
          context,
          title: 'Informations personnelles',
          items: [
            _InfoItem(label: 'Nom', value: name),
            _InfoItem(label: 'Âge', value: '$age ans'),
            _InfoItem(label: 'Genre', value: gender == 'male' ? 'Homme' : 'Femme'),
          ],
        ),

        const SizedBox(height: 16),

        // Informations physiques
        _buildInfoCard(
          context,
          title: 'Informations physiques',
          items: [
            _InfoItem(label: 'Taille', value: '$height cm'),
            _InfoItem(label: 'Poids actuel', value: '$weight kg'),
            if (targetWeight != null)
              _InfoItem(label: 'Poids cible', value: '$targetWeight kg'),
            _InfoItem(label: 'IMC', value: '${bmi.toStringAsFixed(1)} ($bmiCategory)'),
          ],
        ),

        const SizedBox(height: 16),

        // Niveau d'activité
        _buildInfoCard(
          context,
          title: 'Niveau d\'activité',
          items: [
            _InfoItem(
              label: 'Activité',
              value: _getActivityLevelText(activityLevel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<_InfoItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _getGoalDescription(GoalType goal) {
    switch (goal) {
      case GoalType.loseWeight:
        return 'Déficit calorique pour perdre du poids';
      case GoalType.maintainWeight:
        return 'Équilibre calorique pour maintenir votre poids';
      case GoalType.gainWeight:
        return 'Surplus calorique pour prendre du poids';
    }
  }

  String _getActivityLevelText(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sédentaire';
      case ActivityLevel.lightlyActive:
        return 'Légèrement actif';
      case ActivityLevel.moderatelyActive:
        return 'Modérément actif';
      case ActivityLevel.veryActive:
        return 'Très actif';
      case ActivityLevel.extraActive:
        return 'Extrêmement actif';
    }
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem({required this.label, required this.value});
}
