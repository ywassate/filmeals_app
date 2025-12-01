import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/presentation/screens/hub/main_hub_screen.dart';
import 'package:filmeals_app/presentation/screens/onboarding/onboarding_screen_v2.dart';
import 'package:filmeals_app/presentation/screens/onboarding/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les données de locale pour intl
  await initializeDateFormatting('fr_FR', null);

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
    storageService: storageService,
  ));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  final MealRepository mealRepository;
  final LocalStorageService storageService;

  const MyApp({
    super.key,
    required this.userRepository,
    required this.mealRepository,
    required this.storageService,
  });

  Future<bool> _checkOnboardingStatus() async {
    final settingsBox = await Hive.openBox('settings');
    final completed = settingsBox.get('onboardingComplete', defaultValue: false) as bool;

    // Also check if user exists in centralDataBox
    final currentUser = storageService.centralDataBox.get('currentUser');

    // Only consider onboarding complete if both flag is true AND user exists
    return completed && currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder<bool>(
        future: _checkOnboardingStatus(),
        builder: (context, snapshot) {
          // Show loading screen while checking
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.textPrimaryColor,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          // Show MainHubScreen if onboarding is complete, otherwise show SplashScreen
          return snapshot.data!
              ? MainHubScreen(storageService: storageService)
              : const SplashScreen();
        },
      ),
    );
  }
}
