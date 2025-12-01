import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/presentation/screens/tracking/activity_detail_screen.dart';
import 'package:intl/intl.dart';

// Enum ActivityType from location_sensor_data_model.dart

/// Historique des activités physiques avec design minimaliste
class ActivityHistoryScreen extends StatefulWidget {
  final String userId;

  const ActivityHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final LocalStorageService _storageService = LocalStorageService();

  List<LocationRecordModel> _allRecords = [];
  List<LocationRecordModel> _filteredRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedActivityType;
  bool _hasChanges = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      // Load all activity records for this user
      final locationBox = _storageService.locationRecordsBox;
      _allRecords = locationBox.values
          .whereType<LocationRecordModel>()
          .where((record) => record.userId == widget.userId)
          .toList();

      // Sort by start time (most recent first)
      _allRecords.sort((a, b) => b.startTime.compareTo(a.startTime));

      _applyFilters();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading activity records: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final dateStr = DateFormat('dd/MM/yyyy').format(record.startTime).toLowerCase();
          final activityType = record.activityType.toString().split('.').last.toLowerCase();
          if (!dateStr.contains(query) && !activityType.contains(query)) {
            return false;
          }
        }

        if (_selectedActivityType != null) {
          final recordActivityType = record.activityType.toString().split('.').last;
          if (recordActivityType != _selectedActivityType) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedActivityType = null;
      _searchController.clear();
      _applyFilters();
    });
  }

  Future<void> _deleteRecord(LocationRecordModel record) async {
    try {
      await _storageService.locationRecordsBox.delete(record.id);
      if (mounted) {
        MinimalSnackBar.showSuccess(
          context,
          title: 'Deleted',
          message: 'Activity deleted',
        );
      }
      await _loadRecords();
      _hasChanges = true;
    } catch (e) {
      if (mounted) {
        MinimalSnackBar.showError(
          context,
          title: 'Error',
          message: 'Failed to delete activity',
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
                      'Activity History',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  if (_selectedActivityType != null)
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
                    hintText: 'Search activities...',
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

            // Activity type filters
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', null, Icons.all_inclusive),
                    const SizedBox(width: 8),
                    _buildFilterChip('Running', 'running', Icons.directions_run),
                    const SizedBox(width: 8),
                    _buildFilterChip('Walking', 'walking', Icons.directions_walk),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cycling', 'cycling', Icons.directions_bike),
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

  Widget _buildFilterChip(String label, String? type, IconData icon) {
    final isSelected = _selectedActivityType == type;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedActivityType = type;
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
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 6),
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
            'No activities found',
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
    final groupedRecords = <String, List<LocationRecordModel>>{};
    for (final record in _filteredRecords) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.startTime);
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
        final totalDistance = records.fold(0.0, (sum, record) => sum + record.distanceKm);

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
                    '${(totalDistance / 1000).toStringAsFixed(1)} km',
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

  Widget _buildRecordCard(LocationRecordModel record) {
    final activityIcons = {
      'running': Icons.directions_run,
      'walking': Icons.directions_walk,
      'cycling': Icons.directions_bike,
    };

    final timeFormat = DateFormat('HH:mm');
    final distance = record.distanceKm.toStringAsFixed(2);
    final durationText = '${record.durationMinutes}min';

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
            child: Icon(
              activityIcons[record.activityType] ?? Icons.directions_run,
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatActivityType(record.activityType),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${timeFormat.format(record.startTime)} • $durationText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distance,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Text(
                'km',
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

  String _formatActivityType(ActivityType type) {
    final typeName = type.toString().split('.').last;
    return '${typeName[0].toUpperCase()}${typeName.substring(1)}';
  }

  void _showRecordOptions(LocationRecordModel record) {
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
                leading: const Icon(Icons.info_outline, color: AppTheme.textPrimaryColor),
                title: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityDetailScreen(activity: record),
                    ),
                  );
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
                    title: 'Delete activity?',
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
