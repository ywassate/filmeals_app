import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/models/central_data_model.dart';
import 'package:filmeals_app/data/models/meals_sensor_data_model.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/presentation/screens/hub/main_hub_screen.dart';

/// Système d'onboarding moderne en plusieurs étapes
class OnboardingScreenV2 extends StatefulWidget {
  const OnboardingScreenV2({super.key});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2> {
  final PageController _pageController = PageController();
  final LocalStorageService _storageService = LocalStorageService();

  int _currentPage = 0;
  final int _totalPages = 5;

  // Form data
  String _name = '';
  String _email = '';
  int _age = 25;
  String _gender = 'male';
  int _height = 170;
  double _weight = 70.0;
  int _calorieGoal = 2200;
  int _sleepGoal = 480; // minutes
  bool _enableGPS = true;
  bool _enableBluetooth = true;
  bool _enableNotifications = true;

  @override
  void initState() {
    super.initState();
    _storageService.init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validate current page before moving to next
    if (!_validateCurrentPage()) {
      return;
    }

    if (_currentPage < _totalPages - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  bool _validateCurrentPage() {
    String? errorMessage;

    switch (_currentPage) {
      case 0: // Welcome page - name required
        if (_name.trim().isEmpty) {
          errorMessage = 'Please enter your name';
        }
        break;
      case 1: // Personal info page - email required
        if (_email.trim().isEmpty) {
          errorMessage = 'Please enter your email';
        } else if (!_email.contains('@')) {
          errorMessage = 'Please enter a valid email';
        }
        break;
      // Pages 2, 3, 4 have default values, no validation needed
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }

    return true;
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticFeedback.selectionClick();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();

    try {
      // Créer le profil utilisateur
      final user = CentralDataModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        email: _email,
        age: _age,
        gender: _gender,
        height: _height,
        weight: _weight.round(),
        profilePictureUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        activeSensors: [
          if (_enableGPS) 'location',
          if (_enableBluetooth) 'bluetooth',
          'sleep',
          'meals',
        ],
      );

      await _storageService.centralDataBox.put('currentUser', user);

      // Create Meals Sensor Data with calorie goal
      final mealsSensorData = MealsSensorDataModel(
        id: 'meals_sensor_${user.id}',
        userId: user.id,
        goal: GoalType.maintainWeight, // Default to maintain
        activityLevel: ActivityLevel.moderatelyActive,
        dailyCalorieGoal: _calorieGoal,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _storageService.mealsSensorBox.put(user.id, mealsSensorData);

      // Create Sleep Sensor Data with sleep goal
      final sleepSensorData = SleepSensorDataModel(
        id: 'sleep_sensor_${user.id}',
        userId: user.id,
        targetSleepHours: (_sleepGoal / 60).round(), // Convert minutes to hours
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _storageService.sleepSensorBox.put(user.id, sleepSensorData);

      print('✅ User created: ${user.id}');
      print('🎯 Calorie goal: $_calorieGoal kcal');
      print('😴 Sleep goal: ${(_sleepGoal / 60).toStringAsFixed(1)}h');

      // Store onboarding completion flag in a separate settings box
      final settingsBox = await Hive.openBox('settings');
      await settingsBox.put('onboardingComplete', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainHubScreen(
              storageService: _storageService,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error finishing onboarding: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildPersonalInfoPage(),
                  _buildPhysicalDataPage(),
                  _buildGoalsPage(),
                  _buildPreferencesPage(),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: List.generate(_totalPages, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _totalPages - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? AppTheme.textPrimaryColor
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Welcome to\nHealthSync',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                    letterSpacing: -1.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Track your health, meals, sleep, and activities all in one place.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 60),
                _buildTextField(
                  label: 'What\'s your name?',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  onChanged: (value) => _name = value,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'About You',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Help us personalize your experience',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondaryColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),

          // Email field
          _buildTextField(
            label: 'Your email',
            hint: 'Enter your email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _email = value,
          ),
          const SizedBox(height: 32),

          // Age Slider
          _buildSliderSection(
            label: 'Age',
            value: _age.toDouble(),
            min: 10,
            max: 100,
            divisions: 90,
            suffix: 'years',
            onChanged: (value) => setState(() => _age = value.toInt()),
          ),
          const SizedBox(height: 32),

          // Gender Selection
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption('male', 'Male', Icons.male),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption('female', 'Female', Icons.female),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalDataPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Physical Data',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This helps us calculate accurate metrics',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondaryColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),

          // Height Slider
          _buildSliderSection(
            label: 'Height',
            value: _height.toDouble(),
            min: 100,
            max: 220,
            divisions: 120,
            suffix: 'cm',
            onChanged: (value) => setState(() => _height = value.toInt()),
          ),
          const SizedBox(height: 32),

          // Weight Slider
          _buildSliderSection(
            label: 'Weight',
            value: _weight,
            min: 30,
            max: 200,
            divisions: 170,
            suffix: 'kg',
            onChanged: (value) => setState(() => _weight = value),
          ),
          const SizedBox(height: 32),

          // BMI Display
          _buildBMICard(),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Your Goals',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Set your daily targets',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondaryColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),

          // Calorie Goal
          _buildSliderSection(
            label: 'Daily Calories',
            value: _calorieGoal.toDouble(),
            min: 1200,
            max: 4000,
            divisions: 56,
            suffix: 'kcal',
            onChanged: (value) => setState(() => _calorieGoal = value.toInt()),
          ),
          const SizedBox(height: 32),

          // Sleep Goal
          _buildSliderSection(
            label: 'Sleep Goal',
            value: _sleepGoal.toDouble(),
            min: 240,
            max: 600,
            divisions: 72,
            suffix: '${(_sleepGoal / 60).toStringAsFixed(1)}h',
            onChanged: (value) => setState(() => _sleepGoal = value.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose which features to enable',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondaryColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),

          _buildPreferenceToggle(
            icon: Icons.location_on_rounded,
            title: 'GPS Tracking',
            subtitle: 'Track your outdoor activities',
            value: _enableGPS,
            onChanged: (value) => setState(() => _enableGPS = value),
          ),
          const SizedBox(height: 16),
          _buildPreferenceToggle(
            icon: Icons.bluetooth_rounded,
            title: 'Bluetooth',
            subtitle: 'Enable social detection',
            value: _enableBluetooth,
            onChanged: (value) => setState(() => _enableBluetooth = value),
          ),
          const SizedBox(height: 16),
          _buildPreferenceToggle(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Receive health reminders',
            value: _enableNotifications,
            onChanged: (value) => setState(() => _enableNotifications = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (arrow only)
          if (_currentPage > 0)
            IconButton(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back_rounded),
              iconSize: 28,
              color: AppTheme.textPrimaryColor,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceColor,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            const SizedBox(width: 52), // Placeholder to maintain layout

          // Next button (arrow only or "Get Started" text on last page)
          if (_currentPage == _totalPages - 1)
            Expanded(
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.textPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _nextPage,
              icon: const Icon(Icons.arrow_forward_rounded),
              iconSize: 28,
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.textPrimaryColor,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
              prefixIcon: Icon(icon, color: AppTheme.textPrimaryColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.textPrimaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toInt().toString() + ' ' + suffix,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.textPrimaryColor,
            inactiveTrackColor: AppTheme.surfaceColor,
            thumbColor: AppTheme.textPrimaryColor,
            overlayColor: AppTheme.textPrimaryColor.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _gender == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _gender = value);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textPrimaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMICard() {
    final bmi = _weight / ((_height / 100) * (_height / 100));
    String category;
    Color color;

    if (bmi < 18.5) {
      category = 'Underweight';
      color = Colors.blue;
    } else if (bmi < 25) {
      category = 'Normal';
      color = Colors.green;
    } else if (bmi < 30) {
      category = 'Overweight';
      color = Colors.orange;
    } else {
      category = 'Obese';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your BMI',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bmi.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: value ? AppTheme.textPrimaryColor : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value ? Colors.white : AppTheme.textPrimaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.textPrimaryColor,
            activeTrackColor: AppTheme.textPrimaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
