import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/user_model.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/presentation/screens/onboarding/pages/goal_page.dart';
import 'package:filmeals_app/presentation/screens/onboarding/pages/personal_info_page.dart';
import 'package:filmeals_app/presentation/screens/onboarding/pages/physical_info_page.dart';
import 'package:filmeals_app/presentation/screens/onboarding/pages/activity_level_page.dart';
import 'package:filmeals_app/presentation/screens/onboarding/pages/summary_page.dart';
import 'package:filmeals_app/presentation/screens/home/main_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:uuid/uuid.dart';

class OnboardingScreen extends StatefulWidget {
  final UserRepository userRepository;
  final MealRepository mealRepository;

  const OnboardingScreen({
    super.key,
    required this.userRepository,
    required this.mealRepository,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers pour les champs de texte
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();

  // Variables d'état
  GoalType? _selectedGoal;
  String? _selectedGender;
  ActivityLevel? _selectedActivityLevel;

  @override
  void initState() {
    super.initState();
    // Ajouter des listeners pour mettre à jour l'état quand l'utilisateur tape
    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _ageController.addListener(() => setState(() {}));
    _heightController.addListener(() => setState(() {}));
    _weightController.addListener(() => setState(() {}));
    _targetWeightController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: // Goal page
        return _selectedGoal != null;
      case 1: // Personal info page
        return _nameController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _ageController.text.isNotEmpty &&
            _selectedGender != null;
      case 2: // Physical info page
        final hasBasicInfo = _heightController.text.isNotEmpty &&
            _weightController.text.isNotEmpty;
        if (_selectedGoal == GoalType.maintainWeight) {
          return hasBasicInfo;
        }
        return hasBasicInfo && _targetWeightController.text.isNotEmpty;
      case 3: // Activity level page
        return _selectedActivityLevel != null;
      case 4: // Summary page
        return true;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Calculer le poids cible à partir du nombre de kg à perdre/gagner
  int? _calculateTargetWeight() {
    if (_targetWeightController.text.isEmpty || _weightController.text.isEmpty) {
      return null;
    }

    final currentWeight = int.parse(_weightController.text);
    final kgToChange = int.parse(_targetWeightController.text);

    if (_selectedGoal == GoalType.loseWeight) {
      return currentWeight - kgToChange;
    } else if (_selectedGoal == GoalType.gainWeight) {
      return currentWeight + kgToChange;
    }

    return null;
  }

  Future<void> _finish() async {
    // Calculer le poids cible
    final targetWeight = _calculateTargetWeight();

    // Calculer les calories quotidiennes
    final dailyCalories = suggestDailyCalorie(
      int.parse(_ageController.text),
      _selectedGender!,
      int.parse(_weightController.text),
      int.parse(_heightController.text),
      _selectedGoal!,
      _selectedActivityLevel!,
    );

    try {
      // Créer l'utilisateur
      final user = UserModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        email: _emailController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        height: int.parse(_heightController.text),
        weight: int.parse(_weightController.text),
        profilePictureUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        goal: _selectedGoal!,
        targetWeight: targetWeight,
        activityLevel: _selectedActivityLevel!,
        dailyCalorieGoal: dailyCalories,
      );

      // Sauvegarder via le repository
      await widget.userRepository.saveUser(user);

      // Naviguer vers l'écran principal
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(
              userRepository: widget.userRepository,
              mealRepository: widget.mealRepository,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculer le poids cible et les calories pour l'affichage du résumé
    final targetWeight = _canProceed() && _currentPage == 4 ? _calculateTargetWeight() : null;
    final dailyCalories = _canProceed() && _currentPage == 4
        ? suggestDailyCalorie(
            int.parse(_ageController.text),
            _selectedGender!,
            int.parse(_weightController.text),
            int.parse(_heightController.text),
            _selectedGoal!,
            _selectedActivityLevel!,
          )
        : 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bouton retour et indicateur de progression
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: 5,
                        effect: ExpandingDotsEffect(
                          activeDotColor: AppTheme.primaryColor,
                          dotColor: AppTheme.borderColor,
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Contenu des pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Page 1: Objectif
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: GoalPage(
                      selectedGoal: _selectedGoal,
                      onGoalSelected: (goal) {
                        setState(() {
                          _selectedGoal = goal;
                        });
                      },
                    ),
                  ),

                  // Page 2: Informations personnelles
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: PersonalInfoPage(
                      nameController: _nameController,
                      emailController: _emailController,
                      ageController: _ageController,
                      selectedGender: _selectedGender,
                      onGenderSelected: (gender) {
                        setState(() {
                          _selectedGender = gender;
                        });
                      },
                    ),
                  ),

                  // Page 3: Informations physiques
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: PhysicalInfoPage(
                      heightController: _heightController,
                      weightController: _weightController,
                      targetWeightController: _targetWeightController,
                      selectedGoal: _selectedGoal,
                    ),
                  ),

                  // Page 4: Niveau d'activité
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ActivityLevelPage(
                      selectedActivityLevel: _selectedActivityLevel,
                      onActivityLevelSelected: (level) {
                        setState(() {
                          _selectedActivityLevel = level;
                        });
                      },
                    ),
                  ),

                  // Page 5: Résumé
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: SummaryPage(
                      name: _nameController.text,
                      age: int.tryParse(_ageController.text) ?? 0,
                      gender: _selectedGender ?? '',
                      height: int.tryParse(_heightController.text) ?? 0,
                      weight: int.tryParse(_weightController.text) ?? 0,
                      targetWeight: targetWeight,
                      goal: _selectedGoal ?? GoalType.maintainWeight,
                      activityLevel: _selectedActivityLevel ?? ActivityLevel.sedentary,
                      dailyCalories: dailyCalories,
                    ),
                  ),
                ],
              ),
            ),

            // Bouton suivant/terminer
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed()
                      ? () {
                          if (_currentPage == 4) {
                            _finish();
                          } else {
                            _nextPage();
                          }
                        }
                      : null,
                  child: Text(_currentPage == 4 ? 'Terminer' : 'Suivant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
