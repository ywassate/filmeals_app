import 'package:flutter/material.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';

/// Dialog pour enregistrer une nouvelle nuit de sommeil
/// Permet de saisir l'heure de coucher, l'heure de réveil et la qualité
class SleepInputDialog extends StatefulWidget {
  const SleepInputDialog({super.key});

  @override
  State<SleepInputDialog> createState() => _SleepInputDialogState();
}

class _SleepInputDialogState extends State<SleepInputDialog> {
  DateTime? _bedTime;
  DateTime? _wakeTime;
  SleepQuality _quality = SleepQuality.good;
  int _interruptionsCount = 0;
  final TextEditingController _notesController = TextEditingController();
  final LocalStorageService _storageService = LocalStorageService();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectBedTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: 'À quelle heure vous êtes-vous couché(e) ?',
    );

    if (time != null) {
      setState(() {
        final now = DateTime.now();
        // Si on a déjà une heure de réveil, on ajuste la date de coucher en conséquence
        if (_wakeTime != null) {
          _bedTime = DateTime(
            _wakeTime!.year,
            _wakeTime!.month,
            _wakeTime!.day,
            time.hour,
            time.minute,
          );
          // Si l'heure de coucher est après l'heure de réveil, c'est la veille
          if (_bedTime!.isAfter(_wakeTime!)) {
            _bedTime = _bedTime!.subtract(const Duration(days: 1));
          }
        } else {
          // Sinon, on suppose que c'est hier soir
          _bedTime = DateTime(
            now.year,
            now.month,
            now.day - 1,
            time.hour,
            time.minute,
          );
        }
      });
    }
  }

  Future<void> _selectWakeTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      helpText: 'À quelle heure vous êtes-vous réveillé(e) ?',
    );

    if (time != null) {
      setState(() {
        final now = DateTime.now();
        _wakeTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // Si on a déjà une heure de coucher, on réajuste les dates
        if (_bedTime != null) {
          _bedTime = DateTime(
            _wakeTime!.year,
            _wakeTime!.month,
            _wakeTime!.day,
            _bedTime!.hour,
            _bedTime!.minute,
          );
          // Si l'heure de coucher est après l'heure de réveil, c'est la veille
          if (_bedTime!.isAfter(_wakeTime!)) {
            _bedTime = _bedTime!.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _save() async {
    if (_bedTime == null || _wakeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir les heures de coucher et de réveil'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_wakeTime!.isBefore(_bedTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'heure de réveil doit être après l\'heure de coucher'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final durationMinutes = _wakeTime!.difference(_bedTime!).inMinutes;

    final record = SleepRecordModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user',
      bedTime: _bedTime!,
      wakeTime: _wakeTime!,
      durationMinutes: durationMinutes,
      quality: _quality,
      interruptionsCount: _interruptionsCount,
      notes: _notesController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // Sauvegarder dans Hive
      await _storageService.sleepRecordsBox.put(record.id, record);
      print('✅ Nuit sauvegardée: ${record.toJson()}');

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nuit enregistrée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationText = _bedTime != null && _wakeTime != null
        ? _calculateDurationText(_bedTime!, _wakeTime!)
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bedtime,
                      color: Colors.indigo,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Enregistrer une nuit',
                      style: TextStyle(
                        fontSize: 22,
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

              // Heure de coucher
              _buildTimeSelector(
                label: 'Heure de coucher',
                icon: Icons.nightlight_round,
                time: _bedTime,
                onTap: _selectBedTime,
              ),

              const SizedBox(height: 16),

              // Heure de réveil
              _buildTimeSelector(
                label: 'Heure de réveil',
                icon: Icons.wb_sunny,
                time: _wakeTime,
                onTap: _selectWakeTime,
              ),

              const SizedBox(height: 16),

              // Durée calculée
              if (durationText != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Durée: $durationText',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Qualité du sommeil
              const Text(
                'Qualité du sommeil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildQualitySelector(),

              const SizedBox(height: 24),

              // Nombre d'interruptions
              const Text(
                'Nombre de réveils nocturnes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _interruptionsCount > 0
                        ? () => setState(() => _interruptionsCount--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$_interruptionsCount',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => setState(() => _interruptionsCount++),
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 32,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notes (optionnel)
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Ajoutez des observations sur votre sommeil...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
              ),

              const SizedBox(height: 24),

              // Bouton enregistrer
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'Enregistrer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required IconData icon,
    required DateTime? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time != null
                        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                        : 'Sélectionner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: time != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SleepQuality.values.map((quality) {
        final isSelected = _quality == quality;
        final color = _getQualityColor(quality);
        final label = _getQualityLabel(quality);

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _quality = quality;
            });
          },
          selectedColor: color.withOpacity(0.3),
          backgroundColor: Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected ? color : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        );
      }).toList(),
    );
  }

  String _calculateDurationText(DateTime bedTime, DateTime wakeTime) {
    final duration = wakeTime.difference(bedTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  String _getQualityLabel(SleepQuality quality) {
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
