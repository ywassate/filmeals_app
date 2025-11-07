import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/user_model.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';

class ProfileTab extends StatefulWidget {
  final UserRepository userRepository;

  const ProfileTab({
    super.key,
    required this.userRepository,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await widget.userRepository.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user data found'),
        ),
      );
    }

    final bmi = calculateBMI(_user!.weight, _user!.height);
    final bmiCategory = determineBMICategory(bmi);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with Profile Picture
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        _user!.name[0].toUpperCase(),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user!.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user!.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // Personal Information Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.cake,
                            label: 'Age',
                            value: '${_user!.age} years',
                          ),
                          const Divider(height: 1),
                          _InfoTile(
                            icon: _user!.gender.toLowerCase() == 'male'
                                ? Icons.male
                                : Icons.female,
                            label: 'Gender',
                            value: _user!.gender,
                          ),
                          const Divider(height: 1),
                          _InfoTile(
                            icon: Icons.height,
                            label: 'Height',
                            value: '${_user!.height} cm',
                          ),
                          const Divider(height: 1),
                          _InfoTile(
                            icon: Icons.monitor_weight,
                            label: 'Weight',
                            value: '${_user!.weight} kg',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Health Metrics Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Metrics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'BMI',
                            value: bmi.toStringAsFixed(1),
                            subtitle: bmiCategory,
                            color: _getBMIColor(bmi),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Daily Calories',
                            value: '${_user!.dailyCalorieGoal}',
                            subtitle: 'kcal/day',
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Goals Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goals',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.flag,
                            label: 'Goal',
                            value: _getGoalText(_user!.goal),
                            valueColor: _getGoalColor(_user!.goal),
                          ),
                          if (_user!.targetWeight != null) ...[
                            const Divider(height: 1),
                            _InfoTile(
                              icon: Icons.track_changes,
                              label: 'Target Weight',
                              value: '${_user!.targetWeight} kg',
                            ),
                          ],
                          const Divider(height: 1),
                          _InfoTile(
                            icon: Icons.directions_run,
                            label: 'Activity Level',
                            value: _getActivityLevelText(_user!.activityLevel),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Settings Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            title: const Text('Edit Profile'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to edit profile
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.logout,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            title: const Text('Logout'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Implement logout
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  String _getGoalText(GoalType goal) {
    switch (goal) {
      case GoalType.loseWeight:
        return 'Lose Weight';
      case GoalType.maintainWeight:
        return 'Maintain Weight';
      case GoalType.gainWeight:
        return 'Gain Weight';
    }
  }

  Color _getGoalColor(GoalType goal) {
    switch (goal) {
      case GoalType.loseWeight:
        return AppTheme.loseWeightColor;
      case GoalType.maintainWeight:
        return AppTheme.maintainWeightColor;
      case GoalType.gainWeight:
        return AppTheme.gainWeightColor;
    }
  }

  String _getActivityLevelText(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extraActive:
        return 'Extra Active';
    }
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) {
      return AppTheme.gainWeightColor;
    } else if (bmi >= 18.5 && bmi < 24.9) {
      return AppTheme.secondaryColor;
    } else if (bmi >= 25 && bmi < 29.9) {
      return AppTheme.gainWeightColor;
    } else {
      return AppTheme.accentColor;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
