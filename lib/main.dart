import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/presentation/screens/onboarding/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de stockage local
  final storageService = LocalStorageService();
  await storageService.init();

  // Créer les repositories
  final userRepository = UserRepository(storageService);
  final mealRepository = MealRepository(storageService);

  runApp(MyApp(
    userRepository: userRepository,
    mealRepository: mealRepository,
  ));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  final MealRepository mealRepository;

  const MyApp({
    super.key,
    required this.userRepository,
    required this.mealRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitMeals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: WelcomeScreen(
        userRepository: userRepository,
        mealRepository: mealRepository,
      ),
    );
  }
}
