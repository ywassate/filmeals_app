// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/presentation/screens/onboarding/onboarding_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final UserRepository userRepository;
  final MealRepository mealRepository;

  const WelcomeScreen({
    super.key,
    required this.userRepository,
    required this.mealRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo / Icône
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 40),

              // Titre
              Text(
                'FitMeals',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 16),

              // Sous-titre
              Text(
                'Suivez vos repas, atteignez vos objectifs',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Points clés
              _buildFeatureItem(
                context,
                Icons.track_changes,
                'Suivez vos calories quotidiennes',
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                context,
                Icons.trending_up,
                'Atteignez vos objectifs de poids',
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                context,
                Icons.insights,
                'Visualisez vos progrès',
              ),

              const Spacer(),

              // Bouton de démarrage
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => OnboardingScreen(
                          userRepository: userRepository,
                          mealRepository: mealRepository,
                        ),
                      ),
                    );
                  },
                  child: const Text('Commencer'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.secondaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimaryColor),
          ),
        ),
      ],
    );
  }
}
