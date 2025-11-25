import 'package:flutter/material.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:intl/intl.dart';

/// Page d'historique du sommeil
/// Affiche toutes les nuits enregistrées sous forme de liste
class SleepHistoryScreen extends StatefulWidget {
  const SleepHistoryScreen({super.key});

  @override
  State<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends State<SleepHistoryScreen> {
  List<SleepRecordModel> _sleepRecords = [];
  final LocalStorageService _storageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      // Charger tous les enregistrements depuis Hive
      final records = _storageService.sleepRecordsBox.values.toList();

      setState(() {
        _sleepRecords = records;
      });

      print('✅ ${records.length} nuits chargées');
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _sleepRecords.isEmpty
          ? _buildEmptyState()
          : _buildHistoryList(),
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
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun historique',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enregistrez votre première nuit pour voir l\'historique',
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

  Widget _buildHistoryList() {
    // Grouper par mois
    final groupedRecords = _groupByMonth(_sleepRecords);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final entry = groupedRecords.entries.elementAt(index);
        final monthYear = entry.key;
        final records = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de mois
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(
                monthYear,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            // Liste des nuits du mois
            ...records.map((record) => _buildHistoryCard(record)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard(SleepRecordModel record) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    final quality = _getQualityText(record.quality);
    final qualityColor = _getQualityColor(record.quality);
    final hours = record.durationHours.toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(record.bedTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Durée et qualité
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.bedtime,
                      label: '$hours h',
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.star,
                      label: quality,
                      color: qualityColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Heures
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeFormat.format(record.bedTime),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeFormat.format(record.wakeTime),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Interruptions
              if (record.interruptionsCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${record.interruptionsCount} réveil(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordDetails(SleepRecordModel record) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bedtime,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Détails de la nuit',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildDetailRow(
                'Date',
                dateFormat.format(record.bedTime),
                Icons.calendar_today,
              ),
              _buildDetailRow(
                'Coucher',
                timeFormat.format(record.bedTime),
                Icons.nightlight_round,
              ),
              _buildDetailRow(
                'Réveil',
                timeFormat.format(record.wakeTime),
                Icons.wb_sunny,
              ),
              _buildDetailRow(
                'Durée',
                '${record.durationHours.toStringAsFixed(1)} heures',
                Icons.access_time,
              ),
              _buildDetailRow(
                'Qualité',
                _getQualityText(record.quality),
                Icons.star,
                valueColor: _getQualityColor(record.quality),
              ),
              _buildDetailRow(
                'Réveils',
                '${record.interruptionsCount}',
                Icons.warning_amber_rounded,
              ),

              if (record.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.notes,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<SleepRecordModel>> _groupByMonth(
    List<SleepRecordModel> records,
  ) {
    final grouped = <String, List<SleepRecordModel>>{};
    final format = DateFormat('MM/yyyy');

    for (final record in records) {
      final key = format.format(record.bedTime);
      grouped.putIfAbsent(key, () => []).add(record);
    }

    // Trier les enregistrements de chaque mois par date décroissante
    grouped.forEach((key, value) {
      value.sort((a, b) => b.bedTime.compareTo(a.bedTime));
    });

    return grouped;
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
