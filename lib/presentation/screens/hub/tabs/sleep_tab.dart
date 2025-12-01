import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/notification_service.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/widgets/page_banner.dart';
import 'package:filmeals_app/presentation/screens/sleep/sleep_input_dialog.dart';
import 'package:filmeals_app/presentation/screens/sleep/sleep_history_screen.dart';
import 'package:filmeals_app/presentation/screens/sleep/sleep_weekly_stats_screen.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:intl/intl.dart';

class SleepTab extends StatefulWidget {
  final LocalStorageService? storageService;

  const SleepTab({super.key, this.storageService});

  @override
  State<SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends State<SleepTab> {
  final NotificationService _notificationService = NotificationService();
  late LocalStorageService _storageService;
  late UserRepository _userRepository;

  bool _notificationsEnabled = false;
  bool _isLoading = true;
  String? _userId;

  // Sleep data
  SleepRecordModel? _lastSleep;
  List<SleepRecordModel> _last7Days = [];
  double _averageSleep = 0;
  int _consistency = 0;

  // Sleep phases (estimated from total duration)
  Map<String, dynamic> _sleepPhases = {
    'light': {'duration': 0, 'percentage': 0.0},
    'deep': {'duration': 0, 'percentage': 0.0},
    'rem': {'duration': 0, 'percentage': 0.0},
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initNotifications();
    _loadData();
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
    _userRepository = UserRepository(_storageService);
  }

  Future<void> _initNotifications() async {
    try {
      await _notificationService.init();
    } catch (e) {
      print("Erreur d'initialisation des notifications: $e");
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get user ID from centralDataBox (same as TestDataService)
      final centralData = _storageService.centralDataBox.get('currentUser');
      _userId = centralData?.id ?? 'default_user';

      print('👤 SleepTab using user ID: $_userId');

      // Load sleep records
      await _loadSleepRecords();

      // Calculate statistics
      _calculateStatistics();

      // Force rebuild with new data
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading sleep data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSleepRecords() async {
    try {
      final sleepBox = _storageService.sleepRecordsBox;
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      print('📊 Loading sleep records for user: $_userId');
      print('📊 Total records in box: ${sleepBox.length}');

      // Get all sleep records for this user
      final allRecords = sleepBox.values
          .where((record) {
            if (record is! SleepRecordModel) return false;
            final sleepRecord = record as SleepRecordModel;
            return sleepRecord.userId == _userId;
          })
          .cast<SleepRecordModel>()
          .toList();

      print('📊 User records found: ${allRecords.length}');

      // Sort by bedtime (most recent first)
      allRecords.sort((a, b) => b.bedTime.compareTo(a.bedTime));

      // Get last night's sleep (most recent within last 48 hours)
      final recentRecords = allRecords.where((record) {
        return record.bedTime
            .isAfter(yesterday.subtract(const Duration(days: 1)));
      }).toList();

      print('📊 Recent records (last 48h): ${recentRecords.length}');

      if (recentRecords.isNotEmpty) {
        _lastSleep = recentRecords.first;
        print(
            '📊 Last sleep: ${_lastSleep!.bedTime} -> ${_lastSleep!.wakeTime}');
        _calculateSleepPhases(_lastSleep!);
      } else {
        _lastSleep = null;
        print('📊 No recent sleep found');
      }

      // Get last 7 days
      _last7Days = allRecords
          .where((record) {
            return record.bedTime.isAfter(sevenDaysAgo);
          })
          .take(7)
          .toList();

      print('📊 Last 7 days records: ${_last7Days.length}');
    } catch (e) {
      print('Error loading sleep records: $e');
    }
  }

  void _calculateSleepPhases(SleepRecordModel sleep) {
    // Estimate sleep phases based on total duration
    // These are typical distributions from sleep research:
    // Light sleep: 50-60%
    // Deep sleep: 20-25%
    // REM sleep: 20-25%

    final totalMinutes = sleep.durationMinutes;

    // Adjust percentages based on total sleep duration
    double lightPercentage = 0.55;
    double deepPercentage = 0.23;
    double remPercentage = 0.22;

    // If sleep is < 6 hours, reduce deep and REM
    if (sleep.durationHours < 6) {
      lightPercentage = 0.60;
      deepPercentage = 0.20;
      remPercentage = 0.20;
    }
    // If sleep > 8 hours, increase REM
    else if (sleep.durationHours > 8) {
      lightPercentage = 0.50;
      deepPercentage = 0.25;
      remPercentage = 0.25;
    }

    _sleepPhases = {
      'light': {
        'duration': (totalMinutes * lightPercentage).round(),
        'percentage': lightPercentage,
      },
      'deep': {
        'duration': (totalMinutes * deepPercentage).round(),
        'percentage': deepPercentage,
      },
      'rem': {
        'duration': (totalMinutes * remPercentage).round(),
        'percentage': remPercentage,
      },
    };
  }

  void _calculateStatistics() {
    if (_last7Days.isEmpty) {
      _averageSleep = 0;
      _consistency = 0;
      return;
    }

    // Calculate average sleep hours
    final totalMinutes = _last7Days.fold<int>(
      0,
      (sum, record) => sum + record.durationMinutes,
    );
    _averageSleep = (totalMinutes / _last7Days.length) / 60;

    // Calculate consistency (how close to target)
    // Target is 8 hours = 480 minutes
    const targetMinutes = 480;
    final deviations = _last7Days.map((record) {
      return (record.durationMinutes - targetMinutes).abs();
    }).toList();

    final avgDeviation =
        deviations.fold<int>(0, (sum, dev) => sum + dev) / deviations.length;

    // Convert to percentage (100% = perfect, 0% = >3 hours deviation)
    // Max deviation considered: 180 minutes (3 hours)
    _consistency = ((1 - (avgDeviation / 180)) * 100).clamp(0, 100).round();
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) {
      return '${mins}min';
    }
    return '${hours}h ${mins}min';
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

                        // Bannière
                        PageBanner(
                          title: 'Sleep Well',
                          subtitle: 'Rest is essential for your health',
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                          ),
                          imagePath: 'assets/images/carousel/sleep.png',
                        ),
                        const SizedBox(height: 32),

                        // Résumé sommeil - Design minimal
                        _buildSleepSummary(),
                        const SizedBox(height: 40),

                        // Phases de sommeil
                        const Text(
                          'Sleep Phases',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSleepPhases(),
                        const SizedBox(height: 40),

                        // Stats
                        const Text(
                          'Statistics',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildStats(),
                        const SizedBox(height: 40),

                        // Historique
                        const Text(
                          'Last 7 days',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildHistory(),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Sleep',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
            letterSpacing: -1.5,
          ),
        ),
        Row(
          children: [
            // History button
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SleepHistoryScreen(),
                  ),
                );
                // Recharger les données si des modifications ont été faites
                if (result == true && mounted) {
                  await _loadData();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Weekly Stats button
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SleepWeeklyStatsScreen(
                      storageService: _storageService,
                      userId: _userId ?? 'default_user',
                    ),
                  ),
                );
                // Recharger les données si des modifications ont été faites
                if (result == true && mounted) {
                  await _loadData();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Add button (FAB replacement)
            GestureDetector(
              onTap: () async {
                if (_userId == null) {
                  MinimalSnackBar.showError(
                    context,
                    title: 'Erreur',
                    message: 'Impossible de charger l\'utilisateur',
                  );
                  return;
                }

                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => SleepInputDialog(
                    userId: _userId!,
                    initialDate: DateTime.now(),
                  ),
                );
                if (result == true && mounted) {
                  await Future.delayed(const Duration(milliseconds: 100));
                  await _loadData();
                  if (mounted) {
                    MinimalSnackBar.showSuccess(
                      context,
                      title: 'Succès',
                      message: 'Nuit enregistrée avec succès',
                    );
                  }
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
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

  Widget _buildSleepSummary() {
    if (_lastSleep == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.bedtime_outlined,
                size: 48,
                color: AppTheme.textSecondaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'No sleep recorded yet',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap + to add your first sleep entry',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hours = _lastSleep!.durationMinutes ~/ 60;
    final minutes = _lastSleep!.durationMinutes % 60;
    final bedtimeFormatted = DateFormat('HH:mm').format(_lastSleep!.bedTime);
    final wakeTimeFormatted = DateFormat('HH:mm').format(_lastSleep!.wakeTime);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hours.toString(),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              const Text(
                'h',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                minutes.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              const Text(
                'min',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Last night',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSleepTimeInfo('Bedtime', bedtimeFormatted),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.borderColor,
              ),
              _buildSleepTimeInfo('Wake up', wakeTimeFormatted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimeInfo(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepPhases() {
    if (_lastSleep == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'Sleep phases will appear once you record sleep',
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
        _PhaseItem(
          label: 'Light',
          duration: _formatDuration(_sleepPhases['light']['duration']),
          percentage: _sleepPhases['light']['percentage'],
        ),
        const SizedBox(height: 20),
        _PhaseItem(
          label: 'Deep',
          duration: _formatDuration(_sleepPhases['deep']['duration']),
          percentage: _sleepPhases['deep']['percentage'],
        ),
        const SizedBox(height: 20),
        _PhaseItem(
          label: 'REM',
          duration: _formatDuration(_sleepPhases['rem']['duration']),
          percentage: _sleepPhases['rem']['percentage'],
        ),
      ],
    );
  }

  Widget _buildStats() {
    final avgHours = _averageSleep.floor();
    final avgMinutes = ((_averageSleep - avgHours) * 60).round();
    final avgFormatted =
        avgHours > 0 ? '${avgHours}h ${avgMinutes}min' : '${avgMinutes}min';

    return Row(
      children: [
        Expanded(
          child: _MinimalStatCard(
            value: _last7Days.isEmpty ? '--' : avgFormatted,
            label: 'AVERAGE',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MinimalStatCard(
            value: _last7Days.isEmpty ? '--' : '$_consistency%',
            label: 'CONSISTENCY',
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    if (_last7Days.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: Text(
            'No sleep history yet',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final items = <Widget>[];

    for (int i = 0; i < _last7Days.length; i++) {
      final record = _last7Days[i];
      final daysDiff = now.difference(record.bedTime).inDays;

      String dayLabel;
      if (daysDiff == 0) {
        dayLabel = 'Today';
      } else if (daysDiff == 1) {
        dayLabel = 'Yesterday';
      } else if (daysDiff < 7) {
        dayLabel = '$daysDiff days ago';
      } else {
        dayLabel = DateFormat('MMM d').format(record.bedTime);
      }

      if (i > 0) {
        items.add(const Divider(height: 32, color: AppTheme.borderColor));
      }

      items.add(_HistoryItem(
        day: dayLabel,
        hours: record.durationHours,
      ));
    }

    // Fill remaining days if less than 7
    if (_last7Days.length < 7) {
      for (int i = _last7Days.length; i < 7; i++) {
        items.add(const Divider(height: 32, color: AppTheme.borderColor));
        items.add(_HistoryItem(
          day: '${i} days ago',
          hours: 0,
        ));
      }
    }

    return Column(children: items);
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Recevez des rappels quotidiens pour enregistrer votre sommeil',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text(
                  'Enable notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Rappels à 22h et 7h',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                value: _notificationsEnabled,
                activeColor: Colors.black87,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) async {
                  // Demander confirmation avant d'activer/désactiver
                  final confirm = await MinimalConfirmDialog.show(
                    context: context,
                    title: value
                        ? 'Activer les notifications'
                        : 'Désactiver les notifications',
                    message: value
                        ? 'Vous recevrez des rappels quotidiens à 22h et 7h'
                        : 'Les rappels quotidiens seront désactivés',
                    icon: value
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    confirmText: value ? 'Activer' : 'Désactiver',
                    onConfirm: () async {
                      if (value) {
                        await _notificationService.enableNotifications();
                        if (context.mounted) {
                          MinimalSnackBar.showSuccess(
                            context,
                            title: 'Activé',
                            message: 'Notifications activées avec succès',
                          );
                        }
                      } else {
                        await _notificationService.cancelAllNotifications();
                        if (context.mounted) {
                          MinimalSnackBar.showInfo(
                            context,
                            title: 'Désactivé',
                            message: 'Notifications désactivées',
                          );
                        }
                      }
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      setModalState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  );

                  // Si l'utilisateur annule, ne rien faire
                  if (!confirm) {
                    return;
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Demander confirmation avant d'envoyer la notification de test
                    final confirm = await MinimalConfirmDialog.show(
                      context: context,
                      title: 'Test de notification',
                      message: 'Envoyer une notification de test maintenant ?',
                      icon: Icons.notifications_outlined,
                      confirmText: 'Envoyer',
                      onConfirm: () async {
                        try {
                          await _notificationService.testNotification();
                          if (context.mounted) {
                            MinimalSnackBar.showSuccess(
                              context,
                              title: 'Envoyé',
                              message: 'Notification de test envoyée',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            MinimalSnackBar.showError(
                              context,
                              title: 'Erreur',
                              message:
                                  'Les notifications ne sont pas disponibles',
                            );
                          }
                        }
                      },
                    );

                    if (!confirm) {
                      return;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Test notification',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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

class _PhaseItem extends StatelessWidget {
  final String label;
  final String duration;
  final double percentage;

  const _PhaseItem({
    required this.label,
    required this.duration,
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
              duration,
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

class _HistoryItem extends StatelessWidget {
  final String day;
  final double hours;

  const _HistoryItem({
    required this.day,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = hours > 0 ? '${hours.toStringAsFixed(1)}h' : '--';

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: hours > 0
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: hours > 0
                  ? AppTheme.textPrimaryColor
                  : AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Text(
          displayText,
          style: TextStyle(
            fontSize: 13,
            color: hours > 0
                ? AppTheme.textSecondaryColor
                : AppTheme.textSecondaryColor.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
