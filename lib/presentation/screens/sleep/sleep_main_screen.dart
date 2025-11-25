import 'package:flutter/material.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/core/services/notification_service.dart';
import 'sleep_input_dialog.dart';
import 'sleep_history_screen.dart';
import 'sleep_statistics_screen.dart';

/// Page principale du suivi du sommeil
/// Affiche un résumé et permet d'accéder aux différentes fonctionnalités
class SleepMainScreen extends StatefulWidget {
  const SleepMainScreen({super.key});

  @override
  State<SleepMainScreen> createState() => _SleepMainScreenState();
}

class _SleepMainScreenState extends State<SleepMainScreen> {
  // Données simulées pour l'instant - seront remplacées par le repository
  List<SleepRecordModel> _sleepRecords = [];
  SleepRecordModel? _lastSleep;
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSleepData();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
  }

  Future<void> _loadSleepData() async {
    // TODO: Charger les données depuis le repository
    // Pour l'instant, données vides
    setState(() {
      _sleepRecords = [];
      _lastSleep = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi du Sommeil'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icône et message de bienvenue
              _buildWelcomeSection(),

              const SizedBox(height: 24),

              // Carte de la dernière nuit
              if (_lastSleep != null)
                _buildLastSleepCard()
              else
                _buildNoDataCard(),

              const SizedBox(height: 24),

              // Bouton principal : Enregistrer une nuit
              _buildMainActionButton(),

              const SizedBox(height: 16),

              // Boutons secondaires : Historique et Statistiques
              Row(
                children: [
                  Expanded(
                    child: _buildSecondaryButton(
                      icon: Icons.history,
                      label: 'Historique',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SleepHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryButton(
                      icon: Icons.bar_chart,
                      label: 'Statistiques',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SleepStatisticsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section notifications
              _buildNotificationSection(),

              const SizedBox(height: 24),

              // Informations et conseils
              _buildTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo,
                Colors.indigo.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.bedtime,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'Suivi de votre Sommeil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${_sleepRecords.length} nuits enregistrées',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLastSleepCard() {
    final hours = _lastSleep!.durationHours.toStringAsFixed(1);
    final quality = _getQualityText(_lastSleep!.quality);
    final qualityColor = _getQualityColor(_lastSleep!.quality);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              qualityColor.withOpacity(0.1),
              qualityColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Dernière nuit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bedtime,
                  color: qualityColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  '$hours h',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: qualityColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: qualityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                quality,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: qualityColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.nights_stay_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune nuit enregistrée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez à suivre votre sommeil !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => const SleepInputDialog(),
        );

        if (result == true) {
          _loadSleepData();
        }
      },
      icon: const Icon(Icons.add_circle_outline, size: 28),
      label: const Text(
        'Enregistrer une nuit',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.purple[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await _notificationService.enableNotifications();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications activées ! Vous recevrez des rappels à 22h et 7h'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      await _notificationService.cancelAllNotifications();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications désactivées'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Activez les rappels quotidiens pour ne pas oublier d\'enregistrer votre sommeil',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await _notificationService.testNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification de test envoyée !'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Tester les notifications'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Conseils pour mieux dormir',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Couchez-vous à heure régulière'),
            _buildTipItem('Évitez les écrans 1h avant le coucher'),
            _buildTipItem('Gardez votre chambre fraîche (18-20°C)'),
            _buildTipItem('Évitez la caféine après 16h'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[400],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityText(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return 'Mauvais';
      case SleepQuality.fair:
        return 'Passable';
      case SleepQuality.good:
        return 'Bon';
      case SleepQuality.excellent:
        return 'Excellent';
    }
  }

  Color _getQualityColor(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return Colors.red;
      case SleepQuality.fair:
        return Colors.orange;
      case SleepQuality.good:
        return Colors.blue;
      case SleepQuality.excellent:
        return Colors.green;
    }
  }
}
