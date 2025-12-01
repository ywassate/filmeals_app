import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/gps_tracking_service.dart';
import 'package:filmeals_app/core/services/bluetooth_service.dart';
import 'package:filmeals_app/core/services/notification_service.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/core/services/test_data_service.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/presentation/screens/onboarding/onboarding_screen_v2.dart';

/// Page de paramètres centralisée pour gérer toutes les configurations
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GpsTrackingService _gpsService = GpsTrackingService();
  final BluetoothService _bluetoothService = BluetoothService.instance;
  final NotificationService _notificationService = NotificationService();
  late final LocalStorageService _storageService;

  bool _gpsEnabled = false;
  bool _bluetoothEnabled = false;
  bool _notificationsEnabled = false;
  bool _sleepNotificationsEnabled = false;
  bool _activityNotificationsEnabled = false;
  bool _isLoading = true;

  // Profile data
  int _age = 25;
  int _height = 170;
  int _weight = 70;
  int _dailyCalorieGoal = 2200;
  int _sleepGoal = 8;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    setState(() => _isLoading = true);

    try {
      _storageService = LocalStorageService();
      await _storageService.init();

      // Initialiser les services
      await _notificationService.init();

      // Charger l'état actuel des services
      await _loadServicesStatus();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing services: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadServicesStatus() async {
    // GPS status
    _gpsEnabled = _gpsService.isTracking;

    // Bluetooth status
    _bluetoothEnabled = _bluetoothService.isScanning;

    // Notifications status - check from local storage or service
    _notificationsEnabled = true; // TODO: Get actual status
    _sleepNotificationsEnabled = true; // TODO: Get from settings
    _activityNotificationsEnabled = true; // TODO: Get from settings

    // Load profile data
    await _loadProfileData();

    setState(() {});
  }

  Future<void> _loadProfileData() async {
    try {
      final currentUser = _storageService.centralDataBox.get('currentUser');
      if (currentUser != null) {
        setState(() {
          _age = currentUser.age ?? 25;
          _height = currentUser.height ?? 170;
          _weight = currentUser.weight ?? 70;
        });
      }

      // Load meal sensor data for calorie goal
      final userId = currentUser?.id;
      if (userId != null) {
        final mealsSensorData = _storageService.mealsSensorBox.get(userId);
        if (mealsSensorData != null) {
          setState(() {
            _dailyCalorieGoal = mealsSensorData.dailyCalorieGoal ?? 2200;
          });
        }

        // Load sleep sensor data for sleep goal
        final sleepSensorData = _storageService.sleepSensorBox.get(userId);
        if (sleepSensorData != null) {
          setState(() {
            _sleepGoal = sleepSensorData.targetSleepHours ?? 8;
          });
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  Future<void> _toggleGPS(bool value) async {
    HapticFeedback.selectionClick();

    if (value) {
      setState(() => _gpsEnabled = true);
      if (mounted) {
        MinimalSnackBar.showSuccess(
          context,
          title: 'GPS Enabled',
          message: 'Location tracking is now active',
        );
      }
    } else {
      if (_gpsService.isTracking) {
        // Don't disable if currently tracking
        if (mounted) {
          MinimalSnackBar.showWarning(
            context,
            title: 'Cannot Disable',
            message: 'GPS is currently tracking an activity',
          );
        }
        return;
      }
      setState(() => _gpsEnabled = false);
      if (mounted) {
        MinimalSnackBar.showInfo(
          context,
          title: 'GPS Disabled',
          message: 'Location tracking is now inactive',
        );
      }
    }
  }

  Future<void> _toggleBluetooth(bool value) async {
    HapticFeedback.selectionClick();

    if (value) {
      _bluetoothService.init(_storageService);
      await _bluetoothService.startContinuousScan();
      setState(() => _bluetoothEnabled = true);
      if (mounted) {
        MinimalSnackBar.showSuccess(
          context,
          title: 'Bluetooth Enabled',
          message: 'Social detection is now active',
        );
      }
    } else {
      _bluetoothService.stopScan();
      setState(() => _bluetoothEnabled = false);
      if (mounted) {
        MinimalSnackBar.showInfo(
          context,
          title: 'Bluetooth Disabled',
          message: 'Social detection is now inactive',
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _notificationsEnabled = value);

    if (mounted) {
      MinimalSnackBar.showSuccess(
        context,
        title: value ? 'Notifications Enabled' : 'Notifications Disabled',
        message: value ? 'You will receive app notifications' : 'Notifications are turned off',
      );
    }
  }

  Future<void> _toggleSleepNotifications(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _sleepNotificationsEnabled = value);

    if (mounted) {
      MinimalSnackBar.showSuccess(
        context,
        title: value ? 'Sleep Reminders On' : 'Sleep Reminders Off',
        message: value ? 'You will receive bedtime reminders' : 'Sleep reminders disabled',
      );
    }
  }

  Future<void> _toggleActivityNotifications(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _activityNotificationsEnabled = value);

    if (mounted) {
      MinimalSnackBar.showSuccess(
        context,
        title: value ? 'Activity Alerts On' : 'Activity Alerts Off',
        message: value ? 'You will receive activity reminders' : 'Activity alerts disabled',
      );
    }
  }

  Future<void> _generateTestData() async {
    HapticFeedback.mediumImpact();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.textPrimaryColor,
          strokeWidth: 2,
        ),
      ),
    );

    try {
      final testDataService = TestDataService(_storageService);
      await testDataService.generateAllTestData();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        MinimalSnackBar.showSuccess(
          context,
          title: 'Test Data Generated',
          message: 'Sample data for 7 days has been created',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        MinimalSnackBar.showError(
          context,
          title: 'Error',
          message: 'Failed to generate test data: $e',
        );
      }
    }
  }

  Future<void> _clearTestData() async {
    HapticFeedback.mediumImpact();

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Test Data'),
        content: const Text('This will remove all test data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.textPrimaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    try {
      final testDataService = TestDataService(_storageService);
      await testDataService.clearAllTestData();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        MinimalSnackBar.showSuccess(
          context,
          title: 'Data Cleared',
          message: 'All test data has been removed',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        MinimalSnackBar.showError(
          context,
          title: 'Error',
          message: 'Failed to clear test data: $e',
        );
      }
    }
  }

  Future<void> _updateProfileData() async {
    try {
      final currentUser = _storageService.centralDataBox.get('currentUser');
      if (currentUser != null) {
        // Update central data
        final updatedUser = currentUser.copyWith(
          age: _age,
          height: _height,
          weight: _weight,
          updatedAt: DateTime.now(),
        );
        await _storageService.centralDataBox.put('currentUser', updatedUser);

        // Update meals sensor data
        final userId = currentUser.id;
        final mealsSensorData = _storageService.mealsSensorBox.get(userId);
        if (mealsSensorData != null) {
          final updatedMealsSensor = mealsSensorData.copyWith(
            dailyCalorieGoal: _dailyCalorieGoal,
            updatedAt: DateTime.now(),
          );
          await _storageService.mealsSensorBox.put(userId, updatedMealsSensor);
        }

        // Update sleep sensor data
        final sleepSensorData = _storageService.sleepSensorBox.get(userId);
        if (sleepSensorData != null) {
          final updatedSleepSensor = sleepSensorData.copyWith(
            targetSleepHours: _sleepGoal,
            updatedAt: DateTime.now(),
          );
          await _storageService.sleepSensorBox.put(userId, updatedSleepSensor);
        }

        if (mounted) {
          MinimalSnackBar.showSuccess(
            context,
            title: 'Profile Updated',
            message: 'Your settings have been saved',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MinimalSnackBar.showError(
          context,
          title: 'Error',
          message: 'Failed to update profile: $e',
        );
      }
    }
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Logout',
          style: TextStyle(color: AppTheme.textPrimaryColor),
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to complete onboarding again.',
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.textPrimaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    try {
      // Clear onboarding flag
      final settingsBox = await Hive.openBox('settings');
      await settingsBox.put('onboardingComplete', false);

      // Clear current user from centralDataBox
      await _storageService.centralDataBox.delete('currentUser');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Navigate to onboarding screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const OnboardingScreenV2(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        MinimalSnackBar.showError(
          context,
          title: 'Error',
          message: 'Failed to logout: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.textPrimaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.textPrimaryColor,
                        strokeWidth: 2,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Services'),
                          const SizedBox(height: 16),
                          _buildServiceCard(
                            icon: Icons.location_on_rounded,
                            title: 'GPS Tracking',
                            subtitle: 'Enable location tracking for activities',
                            value: _gpsEnabled,
                            onChanged: _toggleGPS,
                          ),
                          const SizedBox(height: 12),
                          _buildServiceCard(
                            icon: Icons.bluetooth_rounded,
                            title: 'Bluetooth',
                            subtitle: 'Enable social detection',
                            value: _bluetoothEnabled,
                            onChanged: _toggleBluetooth,
                          ),
                          const SizedBox(height: 12),
                          _buildServiceCard(
                            icon: Icons.notifications_rounded,
                            title: 'Notifications',
                            subtitle: 'Enable app notifications',
                            value: _notificationsEnabled,
                            onChanged: _toggleNotifications,
                          ),

                          const SizedBox(height: 40),

                          _buildSectionTitle('Notification Preferences'),
                          const SizedBox(height: 16),
                          _buildServiceCard(
                            icon: Icons.bedtime_rounded,
                            title: 'Sleep Reminders',
                            subtitle: 'Get bedtime and wake up reminders',
                            value: _sleepNotificationsEnabled,
                            onChanged: _toggleSleepNotifications,
                            enabled: _notificationsEnabled,
                          ),
                          const SizedBox(height: 12),
                          _buildServiceCard(
                            icon: Icons.directions_run_rounded,
                            title: 'Activity Alerts',
                            subtitle: 'Get reminders to stay active',
                            value: _activityNotificationsEnabled,
                            onChanged: _toggleActivityNotifications,
                            enabled: _notificationsEnabled,
                          ),

                          const SizedBox(height: 40),

                          _buildSectionTitle('Profile Settings'),
                          const SizedBox(height: 16),
                          _buildProfileSettings(),

                          const SizedBox(height: 40),

                          _buildSectionTitle('Account'),
                          const SizedBox(height: 16),
                          _buildActionCard(
                            icon: Icons.logout,
                            title: 'Logout',
                            subtitle: 'Sign out and return to onboarding',
                            color: Colors.red,
                            onTap: _logout,
                          ),

                          const SizedBox(height: 40),

                          _buildSectionTitle('About'),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            icon: Icons.info_outline,
                            title: 'App Version',
                            subtitle: '1.0.0',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'View our privacy policy',
                            onTap: () {
                              // TODO: Navigate to privacy policy
                              MinimalSnackBar.showInfo(
                                context,
                                title: 'Coming Soon',
                                message: 'Privacy policy will be available soon',
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          _buildSectionTitle('Developer'),
                          const SizedBox(height: 16),
                          _buildActionCard(
                            icon: Icons.data_usage,
                            title: 'Generate Test Data',
                            subtitle: 'Fill app with sample data (7 days)',
                            color: AppTheme.textPrimaryColor,
                            onTap: _generateTestData,
                          ),
                          const SizedBox(height: 12),
                          _buildActionCard(
                            icon: Icons.delete_outline,
                            title: 'Clear Test Data',
                            subtitle: 'Remove all test data',
                            color: Colors.red,
                            onTap: _clearTestData,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildProfileSlider(
            label: 'Age',
            value: _age.toDouble(),
            min: 10,
            max: 100,
            suffix: 'years',
            onChanged: (value) => setState(() => _age = value.toInt()),
          ),
          const SizedBox(height: 24),
          _buildProfileSlider(
            label: 'Height',
            value: _height.toDouble(),
            min: 120,
            max: 220,
            suffix: 'cm',
            onChanged: (value) => setState(() => _height = value.toInt()),
          ),
          const SizedBox(height: 24),
          _buildProfileSlider(
            label: 'Weight',
            value: _weight.toDouble(),
            min: 30,
            max: 200,
            suffix: 'kg',
            onChanged: (value) => setState(() => _weight = value.toInt()),
          ),
          const SizedBox(height: 24),
          _buildProfileSlider(
            label: 'Daily Calorie Goal',
            value: _dailyCalorieGoal.toDouble(),
            min: 1200,
            max: 4000,
            suffix: 'kcal',
            onChanged: (value) => setState(() => _dailyCalorieGoal = value.toInt()),
          ),
          const SizedBox(height: 24),
          _buildProfileSlider(
            label: 'Sleep Goal',
            value: _sleepGoal.toDouble(),
            min: 4,
            max: 12,
            suffix: 'hours',
            onChanged: (value) => setState(() => _sleepGoal = value.toInt()),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _updateProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSlider({
    required String label,
    required double value,
    required double min,
    required double max,
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
                fontSize: 14,
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
                '${value.toInt()} $suffix',
                style: const TextStyle(
                  fontSize: 13,
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
            inactiveTrackColor: AppTheme.backgroundColor,
            thumbColor: AppTheme.textPrimaryColor,
            overlayColor: AppTheme.textPrimaryColor.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryColor,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: enabled ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor.withOpacity(enabled ? 1.0 : 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppTheme.textPrimaryColor,
            activeTrackColor: AppTheme.textPrimaryColor.withOpacity(0.3),
            inactiveThumbColor: AppTheme.textSecondaryColor,
            inactiveTrackColor: AppTheme.textSecondaryColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap != null ? () {
        HapticFeedback.selectionClick();
        onTap();
      } : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.textPrimaryColor,
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
            if (onTap != null) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
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
            Icon(
              Icons.play_arrow,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
