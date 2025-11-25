import 'package:flutter/material.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';

/// Page de statistiques du sommeil
/// Affiche des statistiques et graphiques sur le sommeil
class SleepStatisticsScreen extends StatefulWidget {
  const SleepStatisticsScreen({super.key});

  @override
  State<SleepStatisticsScreen> createState() => _SleepStatisticsScreenState();
}

class _SleepStatisticsScreenState extends State<SleepStatisticsScreen> {
  // Données simulées - seront remplacées par le repository
  List<SleepRecordModel> _sleepRecords = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    // TODO: Charger depuis le repository
    setState(() {
      _sleepRecords = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sleepRecords.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Statistiques'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: _buildEmptyState(),
      );
    }

    final stats = _calculateStatistics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé global
            _buildSummaryCard(stats),

            const SizedBox(height: 24),

            // Moyennes
            const Text(
              'Moyennes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAveragesSection(stats),

            const SizedBox(height: 24),

            // Qualité du sommeil
            const Text(
              'Qualité du sommeil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQualityDistribution(stats),

            const SizedBox(height: 24),

            // Tendances
            const Text(
              'Tendances',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTrendsSection(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Pas encore de statistiques',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enregistrez au moins quelques nuits pour voir vos statistiques',
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

  Widget _buildSummaryCard(SleepStatistics stats) {
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
              Colors.orange,
              Colors.orange.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Résumé global',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  '${stats.totalNights}',
                  'Nuits',
                  Icons.nights_stay,
                ),
                _buildSummaryStat(
                  '${stats.averageHours.toStringAsFixed(1)}h',
                  'Moyenne',
                  Icons.access_time,
                ),
                _buildSummaryStat(
                  '${stats.goodNightsPercentage}%',
                  'Bonnes',
                  Icons.star,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildAveragesSection(SleepStatistics stats) {
    return Column(
      children: [
        _buildStatCard(
          'Durée moyenne',
          '${stats.averageHours.toStringAsFixed(1)} heures',
          Icons.bedtime,
          Colors.indigo,
          subtitle: 'Objectif recommandé: 7-9 heures',
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Réveils nocturnes',
          '${stats.averageInterruptions.toStringAsFixed(1)} par nuit',
          Icons.warning_amber_rounded,
          Colors.orange,
          subtitle: stats.averageInterruptions < 2
              ? 'Excellent !'
              : 'Essayez de réduire',
        ),
      ],
    );
  }

  Widget _buildQualityDistribution(SleepStatistics stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildQualityBar(
              'Excellent',
              stats.excellentCount,
              stats.totalNights,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildQualityBar(
              'Bon',
              stats.goodCount,
              stats.totalNights,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildQualityBar(
              'Passable',
              stats.fairCount,
              stats.totalNights,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildQualityBar(
              'Mauvais',
              stats.poorCount,
              stats.totalNights,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsSection(SleepStatistics stats) {
    return Column(
      children: [
        _buildTrendCard(
          'Meilleure nuit',
          '${stats.bestNightHours.toStringAsFixed(1)} heures',
          Icons.trending_up,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildTrendCard(
          'Nuit la plus courte',
          '${stats.worstNightHours.toStringAsFixed(1)} heures',
          Icons.trending_down,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SleepStatistics _calculateStatistics() {
    if (_sleepRecords.isEmpty) {
      return SleepStatistics(
        totalNights: 0,
        averageHours: 0,
        averageInterruptions: 0,
        goodNightsPercentage: 0,
        excellentCount: 0,
        goodCount: 0,
        fairCount: 0,
        poorCount: 0,
        bestNightHours: 0,
        worstNightHours: 0,
      );
    }

    final totalHours = _sleepRecords.fold<double>(
      0,
      (sum, record) => sum + record.durationHours,
    );
    final averageHours = totalHours / _sleepRecords.length;

    final totalInterruptions = _sleepRecords.fold<int>(
      0,
      (sum, record) => sum + record.interruptionsCount,
    );
    final averageInterruptions = totalInterruptions / _sleepRecords.length;

    final excellentCount = _sleepRecords
        .where((r) => r.quality == SleepQuality.excellent)
        .length;
    final goodCount =
        _sleepRecords.where((r) => r.quality == SleepQuality.good).length;
    final fairCount =
        _sleepRecords.where((r) => r.quality == SleepQuality.fair).length;
    final poorCount =
        _sleepRecords.where((r) => r.quality == SleepQuality.poor).length;

    final goodNightsCount = excellentCount + goodCount;
    final goodNightsPercentage =
        (goodNightsCount / _sleepRecords.length * 100).round();

    final sortedByDuration = List<SleepRecordModel>.from(_sleepRecords)
      ..sort((a, b) => a.durationHours.compareTo(b.durationHours));

    final bestNightHours = sortedByDuration.last.durationHours;
    final worstNightHours = sortedByDuration.first.durationHours;

    return SleepStatistics(
      totalNights: _sleepRecords.length,
      averageHours: averageHours,
      averageInterruptions: averageInterruptions,
      goodNightsPercentage: goodNightsPercentage,
      excellentCount: excellentCount,
      goodCount: goodCount,
      fairCount: fairCount,
      poorCount: poorCount,
      bestNightHours: bestNightHours,
      worstNightHours: worstNightHours,
    );
  }
}

/// Classe pour stocker les statistiques calculées
class SleepStatistics {
  final int totalNights;
  final double averageHours;
  final double averageInterruptions;
  final int goodNightsPercentage;
  final int excellentCount;
  final int goodCount;
  final int fairCount;
  final int poorCount;
  final double bestNightHours;
  final double worstNightHours;

  SleepStatistics({
    required this.totalNights,
    required this.averageHours,
    required this.averageInterruptions,
    required this.goodNightsPercentage,
    required this.excellentCount,
    required this.goodCount,
    required this.fairCount,
    required this.poorCount,
    required this.bestNightHours,
    required this.worstNightHours,
  });
}
