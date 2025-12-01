import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';
import 'package:filmeals_app/data/repository/location_repository.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:filmeals_app/data/models/meal_model.dart';
import 'package:filmeals_app/presentation/screens/settings/settings_screen.dart';
import 'package:filmeals_app/presentation/screens/profile/profile_screen.dart';
import 'package:intl/intl.dart';

class HomeTab extends StatefulWidget {
  final LocalStorageService? storageService;

  const HomeTab({super.key, this.storageService});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late LocalStorageService _storageService;
  late MealRepository _mealRepository;
  late LocationRepository _locationRepository;
  late UserRepository _userRepository;

  // Data variables
  int _currentCalories = 0;
  int _calorieGoal = 2200;
  double _sleepHours = 0;
  int _sleepGoal = 480; // minutes (8h)
  int _steps = 0;
  int _stepsGoal = 10000;
  int _waterMl = 0;
  int _waterGoal = 2500;

  String? _userId;
  List<_ActivityData> _recentActivities = [];
  bool _isLoading = true;

  // Carousel variables
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentCarouselPage = 0;
  final List<_CarouselItem> _carouselItems = [
    _CarouselItem(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ),
      title: 'Stay Active',
      subtitle: 'Keep moving every day',
      imagePath: 'assets/images/carousel/active.png',
    ),
    _CarouselItem(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFf093fb), Color(0xFFF5576c)],
      ),
      title: 'Eat Healthy',
      subtitle: 'Nutrition is key',
      imagePath: 'assets/images/carousel/nutrition.png',
    ),
    _CarouselItem(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      ),
      title: 'Sleep Well',
      subtitle: 'Rest is essential',
      imagePath: 'assets/images/carousel/sleep.png',
    ),
    _CarouselItem(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
      ),
      title: 'Track Progress',
      subtitle: 'Monitor your goals',
      imagePath: 'assets/images/carousel/progress.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadData();
    _initializeCarousel();
  }

  void _initializeCarousel() {
    _pageController = PageController(initialPage: 0, viewportFraction: 0.9);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentCarouselPage =
            (_currentCarouselPage + 1) % _carouselItems.length;
        _pageController.animateToPage(
          _currentCarouselPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les données quand on revient sur cette page
    if (mounted) {
      _loadData();
    }
  }

  void _initializeServices() {
    _storageService = widget.storageService ?? LocalStorageService();
    _mealRepository = MealRepository(_storageService);
    _locationRepository = LocationRepository();
    _userRepository = UserRepository(_storageService);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get user ID from centralDataBox (same as TestDataService)
      final centralData = _storageService.centralDataBox.get('currentUser');
      _userId = centralData?.id ?? 'default_user';

      print('👤 HomeTab using user ID: $_userId');

      // Get calorie goal from meals sensor data
      final mealsSensorData = _storageService.mealsSensorBox.values
          .where((data) => data.userId == _userId)
          .firstOrNull;
      if (mealsSensorData != null) {
        _calorieGoal = mealsSensorData.dailyCalorieGoal;
      }

      // Load today's calories from meals
      _currentCalories = await _mealRepository.getTodayCalories(_userId!);

      // Load sleep data (last night)
      await _loadSleepData();

      // Load steps from location activities
      await _loadActivityData();

      // Load recent activities (meals + location)
      await _loadRecentActivities();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading home data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSleepData() async {
    try {
      final sleepBox = _storageService.sleepRecordsBox;
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // Get last night's sleep
      final sleepRecords = sleepBox.values.where((record) {
        if (record is! SleepRecordModel) return false;
        final sleepRecord = record as SleepRecordModel;
        return sleepRecord.userId == _userId &&
            sleepRecord.bedTime.isAfter(yesterday) &&
            sleepRecord.bedTime.isBefore(now);
      }).toList();

      if (sleepRecords.isNotEmpty) {
        final lastSleep = sleepRecords.last as SleepRecordModel;
        _sleepHours = lastSleep.durationHours;
      }
    } catch (e) {
      print('Error loading sleep data: $e');
    }
  }

  Future<void> _loadActivityData() async {
    try {
      await _locationRepository.initialize();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final activities =
          await _locationRepository.getUserLocationRecordsInPeriod(
        _userId!,
        startOfDay,
        today,
      );

      // Calculate total steps from walking/running activities
      _steps = 0;
      for (var activity in activities) {
        if (activity.activityType == ActivityType.walking ||
            activity.activityType == ActivityType.running) {
          // Estimate steps: ~1300 steps per km for walking, ~1500 for running
          final stepsPerKm =
              activity.activityType == ActivityType.running ? 1500 : 1300;
          _steps += (activity.distanceKm * stepsPerKm).round();
        }
      }
    } catch (e) {
      print('Error loading activity data: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final activities = <_ActivityData>[];
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get today's meals
      final meals = await _mealRepository.getMealsByDate(_userId!, today);

      // Get today's location activities
      await _locationRepository.initialize();
      final locationActivities =
          await _locationRepository.getUserLocationRecordsInPeriod(
        _userId!,
        startOfDay,
        today,
      );

      // Add meals as activities
      for (var meal in meals) {
        activities.add(_ActivityData(
          title: _getMealTypeLabel(meal.mealType),
          time: DateFormat('HH:mm').format(meal.date),
          detail: '${meal.calories} kcal',
          timestamp: meal.date,
        ));
      }

      // Add location activities
      for (var activity in locationActivities) {
        if (activity.distanceKm > 0.1) {
          // Only show significant activities
          activities.add(_ActivityData(
            title: _getActivityTypeLabel(activity.activityType),
            time: DateFormat('HH:mm').format(activity.startTime),
            detail:
                '${activity.distanceKm.toStringAsFixed(1)} km • ${activity.durationMinutes} min',
            timestamp: activity.startTime,
          ));
        }
      }

      // Sort by time (most recent first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Take only the 5 most recent
      _recentActivities = activities.take(5).toList();
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }

  String _getMealTypeLabel(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Petit-déjeuner';
      case MealType.lunch:
        return 'Déjeuner';
      case MealType.dinner:
        return 'Dîner';
      case MealType.snack:
        return 'Collation';
    }
  }

  String _getActivityTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return 'Marche';
      case ActivityType.running:
        return 'Course';
      case ActivityType.cycling:
        return 'Vélo';
      case ActivityType.driving:
        return 'Conduite';
      case ActivityType.stationary:
        return 'Stationnaire';
      default:
        return 'Activité';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.textPrimaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header fixe
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildHeader(),
            ),
            const SizedBox(height: 16),

            // Contenu scrollable
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.textPrimaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        Text(
                          _getFormattedDate(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Image Carousel
                        _buildImageCarousel(),
                        const SizedBox(height: 32),

                        // Stats principales - Design minimal
                        _buildMinimalStats(),
                        const SizedBox(height: 40),

                        // Objectifs - Barres de progression simples
                        const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildProgressBars(),
                        const SizedBox(height: 40),

                        // Activités
                        const Text(
                          'Activity',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildMinimalActivity(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _carouselItems.length,
        onPageChanged: (index) {
          setState(() {
            _currentCarouselPage = index;
          });
        },
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
              }
              return Center(
                child: SizedBox(
                  height: Curves.easeInOut.transform(value) * 180,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: _carouselItems[index].imagePath == null
                    ? _carouselItems[index].gradient
                    : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background image if available
                  if (_carouselItems[index].imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        _carouselItems[index].imagePath!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _carouselItems[index].title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _carouselItems[index].subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Health',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
            letterSpacing: -1.5,
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalStats() {
    return Row(
      children: [
        Expanded(
          child: _MinimalStatCard(
            value: _formatNumber(_steps),
            label: 'STEPS',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MinimalStatCard(
            value: _formatNumber(_currentCalories),
            label: 'KCAL',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MinimalStatCard(
            value: '${_sleepHours.toStringAsFixed(1)}h',
            label: 'SLEEP',
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return NumberFormat('#,###', 'en_US').format(number);
    }
    return number.toString();
  }

  Widget _buildProgressBars() {
    final caloriePercentage =
        _calorieGoal > 0 ? _currentCalories / _calorieGoal : 0.0;
    final stepsPercentage = _stepsGoal > 0 ? _steps / _stepsGoal : 0.0;
    final waterPercentage = _waterGoal > 0 ? _waterMl / _waterGoal : 0.0;
    final sleepMinutes = (_sleepHours * 60).round();
    final sleepPercentage = _sleepGoal > 0 ? sleepMinutes / _sleepGoal : 0.0;

    return Column(
      children: [
        _ProgressItem(
          label: 'Calories',
          current: _currentCalories,
          goal: _calorieGoal,
          percentage: caloriePercentage.clamp(0.0, 1.0),
        ),
        const SizedBox(height: 20),
        _ProgressItem(
          label: 'Steps',
          current: _steps,
          goal: _stepsGoal,
          percentage: stepsPercentage.clamp(0.0, 1.0),
        ),
        const SizedBox(height: 20),
        _ProgressItem(
          label: 'Water',
          current: _waterMl,
          goal: _waterGoal,
          percentage: waterPercentage.clamp(0.0, 1.0),
        ),
        const SizedBox(height: 20),
        _ProgressItem(
          label: 'Sleep',
          current: sleepMinutes,
          goal: _sleepGoal,
          percentage: sleepPercentage.clamp(0.0, 1.0),
        ),
      ],
    );
  }

  Widget _buildMinimalActivity() {
    if (_recentActivities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: Text(
            'No activities yet today',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _recentActivities.length; i++) ...[
          if (i > 0) const Divider(height: 32, color: AppTheme.borderColor),
          _ActivityItem(
            title: _recentActivities[i].title,
            time: _recentActivities[i].time,
            detail: _recentActivities[i].detail,
          ),
        ],
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];

    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _MinimalStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _MinimalStatCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final double percentage;

  const _ProgressItem({
    required this.label,
    required this.current,
    required this.goal,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
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
              '$current / $goal',
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
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.textPrimaryColor,
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

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final String detail;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.textPrimaryColor,
            shape: BoxShape.circle,
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
                detail,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Data class to hold activity information
class _ActivityData {
  final String title;
  final String time;
  final String detail;
  final DateTime timestamp;

  _ActivityData({
    required this.title,
    required this.time,
    required this.detail,
    required this.timestamp,
  });
}

/// Data class to hold carousel item information
class _CarouselItem {
  final Gradient gradient;
  final String title;
  final String subtitle;
  final String? imagePath; // Optionnel: chemin vers l'image

  _CarouselItem({
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.imagePath,
  });
}
