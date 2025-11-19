import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/presentation/screens/hub/main_hub_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
      title: 'HealthSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainHubScreen(),
    );
  }
}
