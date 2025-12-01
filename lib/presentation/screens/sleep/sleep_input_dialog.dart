import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';

/// Dialog pour enregistrer une nouvelle nuit de sommeil avec UX améliorée
class SleepInputDialog extends StatefulWidget {
  final String userId;
  final DateTime? initialDate;
  final SleepRecordModel? existingRecord; // Pour l'édition

  const SleepInputDialog({
    super.key,
    required this.userId,
    this.initialDate,
    this.existingRecord,
  });

  @override
  State<SleepInputDialog> createState() => _SleepInputDialogState();
}

class _SleepInputDialogState extends State<SleepInputDialog> {
  DateTime? _bedTime;
  DateTime? _wakeTime;
  DateTime _selectedDate = DateTime.now();
  SleepQuality _quality = SleepQuality.good;
  int _interruptionsCount = 0;
  final TextEditingController _notesController = TextEditingController();
  final LocalStorageService _storageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();

    // Si c'est une édition, pré-remplir les champs
    if (widget.existingRecord != null) {
      _bedTime = widget.existingRecord!.bedTime;
      _wakeTime = widget.existingRecord!.wakeTime;
      _quality = widget.existingRecord!.quality;
      _interruptionsCount = widget.existingRecord!.interruptionsCount;
      _notesController.text = widget.existingRecord!.notes;
      _selectedDate = widget.existingRecord!.bedTime;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectBedTime() async {
    HapticFeedback.selectionClick();
    final time = await _showModernTimePicker(
      context: context,
      initialHour: 22,
      initialMinute: 0,
      title: 'Heure de coucher',
    );

    if (time != null) {
      setState(() {
        final now = DateTime.now();
        if (_wakeTime != null) {
          _bedTime = DateTime(
            _wakeTime!.year,
            _wakeTime!.month,
            _wakeTime!.day,
            time['hour']!,
            time['minute']!,
          );
          if (_bedTime!.isAfter(_wakeTime!)) {
            _bedTime = _bedTime!.subtract(const Duration(days: 1));
          }
        } else {
          _bedTime = DateTime(
            now.year,
            now.month,
            now.day - 1,
            time['hour']!,
            time['minute']!,
          );
        }
      });
    }
  }

  Future<void> _selectWakeTime() async {
    HapticFeedback.selectionClick();
    final time = await _showModernTimePicker(
      context: context,
      initialHour: 7,
      initialMinute: 0,
      title: 'Heure de réveil',
    );

    if (time != null) {
      setState(() {
        final now = DateTime.now();
        _wakeTime = DateTime(
          now.year,
          now.month,
          now.day,
          time['hour']!,
          time['minute']!,
        );

        if (_bedTime != null) {
          _bedTime = DateTime(
            _wakeTime!.year,
            _wakeTime!.month,
            _wakeTime!.day,
            _bedTime!.hour,
            _bedTime!.minute,
          );
          if (_bedTime!.isAfter(_wakeTime!)) {
            _bedTime = _bedTime!.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<Map<String, int>?> _showModernTimePicker({
    required BuildContext context,
    required int initialHour,
    required int initialMinute,
    required String title,
  }) async {
    return showModalBottomSheet<Map<String, int>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ModernTimePicker(
        initialHour: initialHour,
        initialMinute: initialMinute,
        title: title,
      ),
    );
  }

  Future<void> _save() async {
    if (_bedTime == null || _wakeTime == null) {
      MinimalSnackBar.showWarning(
        context,
        title: 'Attention',
        message: 'Veuillez saisir les heures de coucher et de réveil',
      );
      return;
    }

    if (_wakeTime!.isBefore(_bedTime!)) {
      MinimalSnackBar.showError(
        context,
        title: 'Erreur',
        message: 'L\'heure de réveil doit être après l\'heure de coucher',
      );
      return;
    }

    final durationMinutes = _wakeTime!.difference(_bedTime!).inMinutes;

    final record = SleepRecordModel(
      id: widget.existingRecord?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      bedTime: _bedTime!,
      wakeTime: _wakeTime!,
      durationMinutes: durationMinutes,
      quality: _quality,
      interruptionsCount: _interruptionsCount,
      notes: _notesController.text,
      createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _storageService.sleepRecordsBox.put(record.id, record);
      print('✅ Nuit ${widget.existingRecord != null ? "modifiée" : "sauvegardée"}: ${record.toJson()}');

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
      if (mounted) {
        MinimalSnackBar.showError(
          context,
          title: 'Erreur',
          message: 'Impossible d\'enregistrer la nuit',
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre avec icône
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🌙',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingRecord != null
                          ? 'Modifier une nuit'
                          : 'Enregistrer une nuit',
                      style: const TextStyle(
                        fontSize: 22,
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
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sélection de date
              InkWell(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppTheme.textPrimaryColor,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (selectedDate != null) {
                    setState(() => _selectedDate = selectedDate);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '📅',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Heure de coucher
              _buildModernTimeSelector(
                emoji: '😴',
                label: 'Coucher',
                time: _bedTime,
                onTap: _selectBedTime,
              ),

              const SizedBox(height: 12),

              // Heure de réveil
              _buildModernTimeSelector(
                emoji: '☀️',
                label: 'Réveil',
                time: _wakeTime,
                onTap: _selectWakeTime,
              ),

              const SizedBox(height: 12),

              // Durée calculée
              if (durationText != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.shade50,
                        Colors.blue.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '⏱️',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        durationText,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Qualité du sommeil avec emojis
              const Text(
                'Qualité du sommeil',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildEmojiQualitySelector(),

              const SizedBox(height: 24),

              // Nombre d'interruptions
              const Text(
                'Réveils nocturnes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildInterruptionsCounter(),

              const SizedBox(height: 24),

              // Notes (optionnel)
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Comment s\'est passée votre nuit ?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black87, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.edit_note),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 24),

              // Bouton enregistrer
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.existingRecord != null
                      ? 'Modifier la nuit'
                      : 'Enregistrer la nuit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTimeSelector({
    required String emoji,
    required String label,
    required DateTime? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: time != null ? AppTheme.surfaceColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: time != null ? Colors.black12 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time != null
                        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                        : '--:--',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: time != null ? Colors.black87 : Colors.grey[400],
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 24,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiQualitySelector() {
    const qualityEmojis = {
      SleepQuality.poor: '😣',
      SleepQuality.fair: '😐',
      SleepQuality.good: '🙂',
      SleepQuality.excellent: '😄',
    };

    const qualityLabels = {
      SleepQuality.poor: 'Mauvais',
      SleepQuality.fair: 'Moyen',
      SleepQuality.good: 'Bon',
      SleepQuality.excellent: 'Excellent',
    };

    return Row(
      children: SleepQuality.values.map((quality) {
        final isSelected = _quality == quality;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _quality = quality);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black87 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.black87 : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      qualityEmojis[quality]!,
                      style: TextStyle(
                        fontSize: isSelected ? 32 : 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      qualityLabels[quality]!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterruptionsCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _interruptionsCount > 0
                ? () {
                    HapticFeedback.selectionClick();
                    setState(() => _interruptionsCount--);
                  }
                : null,
            icon: Icon(
              Icons.remove_circle,
              color: _interruptionsCount > 0 ? Colors.black87 : Colors.grey[300],
              size: 36,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_interruptionsCount',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _interruptionsCount++);
            },
            icon: const Icon(
              Icons.add_circle,
              color: Colors.black87,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDurationText(DateTime bedTime, DateTime wakeTime) {
    final duration = wakeTime.difference(bedTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Aujourd\'hui';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Hier';
    } else {
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}

/// Modern time picker avec roues de défilement
class _ModernTimePicker extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final String title;

  const _ModernTimePicker({
    required this.initialHour,
    required this.initialMinute,
    required this.title,
  });

  @override
  State<_ModernTimePicker> createState() => _ModernTimePickerState();
}

class _ModernTimePickerState extends State<_ModernTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour;
    _selectedMinute = widget.initialMinute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Sélecteurs
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Heures
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _hourController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedHour = index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 23) return null;
                        final isSelected = index == _selectedHour;
                        return Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: isSelected ? 32 : 24,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Séparateur
                const Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Minutes
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _minuteController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMinute = index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 59) return null;
                        final isSelected = index == _selectedMinute;
                        return Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: isSelected ? 32 : 24,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop({
                      'hour': _selectedHour,
                      'minute': _selectedMinute,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirmer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
