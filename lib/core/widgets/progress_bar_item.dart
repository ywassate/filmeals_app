import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';

/// Widget de barre de progression avec label et valeurs
class ProgressBarItem extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final double? percentage; // Si null, calculé automatiquement
  final Color? progressColor;
  final Color? backgroundColor;
  final String? unit; // Ex: "kcal", "h", "steps"

  const ProgressBarItem({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    this.percentage,
    this.progressColor,
    this.backgroundColor,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final actualPercentage = percentage ?? (goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0);
    final valueText = unit != null ? '$current$unit / $goal$unit' : '$current / $goal';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: backgroundColor ?? AppTheme.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: actualPercentage,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: progressColor ?? AppTheme.textPrimaryColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
