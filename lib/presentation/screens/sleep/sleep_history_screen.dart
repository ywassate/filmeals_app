import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/sleep_sensor_data_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/presentation/screens/sleep/sleep_input_dialog.dart';
import 'package:intl/intl.dart';

/// Historique du sommeil avec design minimaliste
class SleepHistoryScreen extends StatefulWidget {
  const SleepHistoryScreen({super.key});

  @override
  State<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends State<SleepHistoryScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late UserRepository _userRepository;

  List<SleepRecordModel> _allRecords = [];
  List<SleepRecordModel> _filteredRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  SleepQuality? _selectedQuality;
  String? _userId;
  bool _hasChanges = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository(_storageService);
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      // Get user ID from centralDataBox (same as tabs)
      final centralData = _storageService.centralDataBox.get('currentUser');
      _userId = centralData?.id ?? 'default_user';

      print('👤 SleepHistoryScreen using user ID: $_userId');

      // Load all sleep records for this user
      final sleepBox = _storageService.sleepRecordsBox;
      _allRecords = sleepBox.values
          .where((record) {
            if (record is! SleepRecordModel) return false;
            final sleepRecord = record as SleepRecordModel;
            return sleepRecord.userId == _userId;
          })
          .cast<SleepRecordModel>()
          .toList();

      // Sort by bedTime (most recent first)
      _allRecords.sort((a, b) => b.bedTime.compareTo(a.bedTime));

      _applyFilters();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading sleep records: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final dateStr = DateFormat('dd/MM/yyyy').format(record.bedTime).toLowerCase();
          final notes = record.notes.toLowerCase();
          if (!dateStr.contains(query) && !notes.contains(query)) {
            return false;
          }
        }

        if (_selectedQuality != null && record.quality != _selectedQuality) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedQuality = null;
      _searchController.clear();
      _applyFilters();
    });
  }

  Future<void> _deleteRecord(SleepRecordModel record) async {
    try {
      await _storageService.sleepRecordsBox.delete(record.id);
      if (mounted) {
        MinimalSnackBar.showSuccess(
          context,
          title: 'Deleted',
          message: 'Sleep record deleted',
        );
      }
      await _loadRecords();
      // Marquer que des données ont été modifiées
      _hasChanges = true;
    } catch (e) {
      if (mounted) {
        MinimalSnackBar.showError(
          context,
          title: 'Error',
          message: 'Failed to delete record',
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
                      // Retourner true si des données ont été modifiées
                      Navigator.pop(context, _hasChanges);
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
                      'History',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  if (_selectedQuality != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _clearFilters();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppTheme.textPrimaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search sleep records...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondaryColor.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppTheme.textSecondaryColor,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ),

            // Quality filters
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', null, ''),
                    const SizedBox(width: 8),
                    _buildFilterChip('Poor', SleepQuality.poor, '😣'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Fair', SleepQuality.fair, '😐'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Good', SleepQuality.good, '🙂'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Excellent', SleepQuality.excellent, '😄'),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.textPrimaryColor,
                        strokeWidth: 2,
                      ),
                    )
                  : _filteredRecords.isEmpty
                      ? _buildEmptyState()
                      : _buildRecordsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, SleepQuality? quality, String emoji) {
    final isSelected = _selectedQuality == quality;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedQuality = quality;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textPrimaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji.isNotEmpty) ...[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No sleep records found',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    final groupedRecords = <String, List<SleepRecordModel>>{};
    for (final record in _filteredRecords) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.bedTime);
      groupedRecords.putIfAbsent(dateKey, () => []).add(record);
    }

    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final date = DateTime.parse(dateKey);
        final records = groupedRecords[dateKey]!;
        final totalHours = records.fold(0.0, (sum, record) => sum + record.durationHours);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${totalHours.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            ...records.map((record) => _buildRecordCard(record)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(SleepRecordModel record) {
    final qualityEmojis = {
      SleepQuality.poor: '😣',
      SleepQuality.fair: '😐',
      SleepQuality.good: '🙂',
      SleepQuality.excellent: '😄',
    };

    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                qualityEmojis[record.quality] ?? '😴',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${timeFormat.format(record.bedTime)} → ${timeFormat.format(record.wakeTime)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${record.durationHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    if (record.interruptionsCount > 0) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        '${record.interruptionsCount} interruption${record.interruptionsCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.durationHours.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Text(
                'hours',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _showRecordOptions(record);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.more_horiz,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE d MMM').format(date);
    }
  }

  void _showRecordOptions(SleepRecordModel record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppTheme.textPrimaryColor),
                title: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);

                  if (_userId == null) return;

                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => SleepInputDialog(
                      userId: _userId!,
                      existingRecord: record,
                      initialDate: record.bedTime,
                    ),
                  );
                  if (result == true) {
                    await _loadRecords();
                    _hasChanges = true;
                    if (mounted) {
                      MinimalSnackBar.showSuccess(
                        context,
                        title: 'Updated',
                        message: 'Sleep record updated',
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.textPrimaryColor),
                title: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);

                  await MinimalConfirmDialog.show(
                    context: context,
                    title: 'Delete sleep record?',
                    message: 'This action cannot be undone',
                    icon: Icons.delete_outline,
                    confirmText: 'Delete',
                    onConfirm: () => _deleteRecord(record),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
