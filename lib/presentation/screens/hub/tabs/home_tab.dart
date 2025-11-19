import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header ultra-minimaliste
                _buildHeader(),
                const SizedBox(height: 40),

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
        Container(
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
      ],
    );
  }

  Widget _buildMinimalStats() {
    return Row(
      children: [
        Expanded(
          child: _MinimalStatCard(
            value: '8,247',
            label: 'STEPS',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MinimalStatCard(
            value: '1,840',
            label: 'KCAL',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MinimalStatCard(
            value: '7.5h',
            label: 'SLEEP',
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBars() {
    return Column(
      children: [
        _ProgressItem(label: 'Calories', current: 1840, goal: 2200, percentage: 0.84),
        const SizedBox(height: 20),
        _ProgressItem(label: 'Steps', current: 8247, goal: 10000, percentage: 0.82),
        const SizedBox(height: 20),
        _ProgressItem(label: 'Water', current: 1800, goal: 2500, percentage: 0.72),
        const SizedBox(height: 20),
        _ProgressItem(label: 'Sleep', current: 450, goal: 480, percentage: 0.94),
      ],
    );
  }

  Widget _buildMinimalActivity() {
    return Column(
      children: [
        _ActivityItem(
          title: 'Morning Run',
          time: '07:30 AM',
          detail: '5.2 km • 32 min',
        ),
        const Divider(height: 32, color: AppTheme.borderColor),
        _ActivityItem(
          title: 'Lunch',
          time: '12:45 PM',
          detail: '650 kcal',
        ),
        const Divider(height: 32, color: AppTheme.borderColor),
        _ActivityItem(
          title: 'Evening Walk',
          time: '06:15 PM',
          detail: '3.1 km • 28 min',
        ),
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

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
