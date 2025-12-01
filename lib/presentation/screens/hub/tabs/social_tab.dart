// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/widgets/minimal_snackbar.dart';
import 'package:filmeals_app/core/widgets/page_banner.dart';
import 'package:filmeals_app/core/services/bluetooth_service.dart';
import 'package:filmeals_app/core/services/permission_service.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/models/social_sensor_data_model.dart';
import 'package:intl/intl.dart';

class SocialTab extends StatefulWidget {
  final LocalStorageService storageService;

  const SocialTab({super.key, required this.storageService});

  @override
  State<SocialTab> createState() => _SocialTabState();
}

class _SocialTabState extends State<SocialTab> {
  bool _isScanning = false;
  bool _bluetoothPermissionsGranted = false;
  bool _contactsPermissionGranted = false;
  int _appareilsDetectes = 0;
  int _pendingDetections = 0;
  int _validatedContacts = 0;
  List<BluetoothContactModel> _contacts = [];

  @override
  void initState() {
    super.initState();
    BluetoothService.instance.init(widget.storageService);
    _checkPermissions();
    _loadContacts();
    _restoreScanState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les données quand on revient sur cette page
    if (mounted) {
      _loadContacts();
    }
  }

  void _restoreScanState() {
    if (BluetoothService.instance.isScanning) {
      setState(() {
        _isScanning = true;
        _appareilsDetectes = BluetoothService.instance.currentTrackedDevices;
        _pendingDetections = BluetoothService.instance.currentPendingCount;
      });

      BluetoothService.instance
          .setProgressCallback((total, pending, validated) {
        if (mounted) {
          setState(() {
            _appareilsDetectes = total;
            _pendingDetections = pending;
            _validatedContacts += validated;
          });

          if (validated > 0) {
            _loadContacts();
          }
        }
      });

      print(
          '✅ État du scan restauré: $_appareilsDetectes trackés, $_pendingDetections en attente');
    }
  }

  @override
  void dispose() {
    if (BluetoothService.instance.isScanning) {
      BluetoothService.instance.setProgressCallback(null);
      print('🧹 Callback UI désenregistré (scan continue en arrière-plan)');
    }
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    bool bluetooth = await PermissionService.hasBluetoothPermissions();
    bool contacts = await PermissionService.hasContactsPermission();

    setState(() {
      _bluetoothPermissionsGranted = bluetooth;
      _contactsPermissionGranted = contacts;
    });
  }

  void _loadContacts() {
    setState(() {
      _contacts = BluetoothService.instance.getAllContacts();
    });
  }

  Future<void> _requestBluetoothPermissions() async {
    bool granted = await PermissionService.requestBluetoothPermissions();

    setState(() {
      _bluetoothPermissionsGranted = granted;
    });

    if (granted) {
      MinimalSnackBar.showSuccess(
        context,
        title: 'Autorisé',
        message: 'Permissions Bluetooth accordées',
      );
    } else {
      _showPermissionDeniedDialog('Bluetooth');
    }
  }

  Future<void> _requestContactsPermission() async {
    bool granted = await PermissionService.requestContactsPermission();

    setState(() {
      _contactsPermissionGranted = granted;
    });

    if (granted) {
      MinimalSnackBar.showSuccess(
        context,
        title: 'Autorisé',
        message: 'Permission Contacts accordée',
      );
    } else {
      _showPermissionDeniedDialog('Contacts');
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    MinimalConfirmDialog.show(
      context: context,
      title: 'Permission refusée',
      message:
          'L\'accès à $permissionType est nécessaire pour le fonctionnement du scan.\n\nVoulez-vous ouvrir les paramètres ?',
      icon: Icons.warning,
      confirmText: 'Paramètres',
      onConfirm: () {
        PermissionService.openSettings();
      },
    );
  }

  Future<void> _toggleScan() async {
    if (!_bluetoothPermissionsGranted) {
      MinimalSnackBar.showWarning(
        context,
        title: 'Attention',
        message: 'Permissions Bluetooth requises',
      );
      return;
    }

    if (!_contactsPermissionGranted) {
      MinimalSnackBar.showWarning(
        context,
        title: 'Attention',
        message: 'Permission Contacts requise',
      );
      return;
    }

    if (_isScanning) {
      await BluetoothService.instance.stopScan();
      setState(() {
        _isScanning = false;
      });
    } else {
      setState(() {
        _isScanning = true;
        _appareilsDetectes = 0;
        _pendingDetections = 0;
        _validatedContacts = 0;
      });

      try {
        BluetoothService.instance.setMinimumDuration(300);

        await BluetoothService.instance.startContinuousScan(
          onProgress: (total, pending, validated) {
            if (mounted) {
              setState(() {
                _appareilsDetectes = total;
                _pendingDetections = pending;
                _validatedContacts += validated;
              });

              if (validated > 0) {
                _loadContacts();
              }
            }
          },
        );
      } catch (e) {
        setState(() {
          _isScanning = false;
        });

        if (mounted) {
          MinimalSnackBar.showError(
            context,
            title: 'Erreur',
            message: 'Impossible de démarrer le scan',
          );
        }
      }
    }
  }

  Future<void> _deleteAllContacts() async {
    // Demander confirmation avant suppression
    final confirm = await MinimalConfirmDialog.show(
      context: context,
      title: 'Supprimer tous les contacts',
      message:
          'Voulez-vous vraiment supprimer tous les contacts ?\nCette action est irréversible.',
      icon: Icons.delete_forever,
      confirmText: 'Supprimer',
      onConfirm: () async {
        await BluetoothService.instance.deleteAllContacts();
        _loadContacts();
        if (mounted) {
          MinimalSnackBar.showSuccess(
            context,
            title: 'Supprimé',
            message: 'Tous les contacts ont été supprimés',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                        title: 'Social Connect',
                        subtitle: 'Track your social interactions',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                        ),
                        imagePath: 'assets/images/carousel/progress.png',
                      ),
                      const SizedBox(height: 32),

                      // Permissions
                      if (!_bluetoothPermissionsGranted ||
                          !_contactsPermissionGranted)
                        _buildPermissionsCard(),

                      if (!_bluetoothPermissionsGranted ||
                          !_contactsPermissionGranted)
                        const SizedBox(height: 32),

                      // Scanner
                      _buildScannerCard(),
                      const SizedBox(height: 40),

                      // Statistiques
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
                      _buildStatsRow(),
                      const SizedBox(height: 40),

                      // Liste des contacts
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Contacts (${_contacts.length})',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (_contacts.isNotEmpty)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: AppTheme.textPrimaryColor,
                                  size: 20,
                                ),
                                onPressed: _deleteAllContacts,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildContactsList(),
                    ],
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
          'Social',
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
            Icons.bluetooth_searching,
            color: AppTheme.textPrimaryColor,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Permissions Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // Bluetooth
          _PermissionItem(
            label: 'Bluetooth',
            granted: _bluetoothPermissionsGranted,
            onRequest: _requestBluetoothPermissions,
          ),
          const SizedBox(height: 12),
          // Contacts
          _PermissionItem(
            label: 'Contacts',
            granted: _contactsPermissionGranted,
            onRequest: _requestContactsPermission,
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (_isScanning) ...[
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppTheme.textPrimaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scanning',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Every 5 minutes',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ScanStatItem(
                  label: 'Tracked',
                  value: '$_appareilsDetectes',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.borderColor,
                ),
                _ScanStatItem(
                  label: 'Pending',
                  value: '$_pendingDetections',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.borderColor,
                ),
                _ScanStatItem(
                  label: 'Validated',
                  value: '$_validatedContacts',
                ),
              ],
            ),
          ] else ...[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.bluetooth_searching,
                color: AppTheme.textPrimaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to Scan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_contacts.length} contacts saved',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_bluetoothPermissionsGranted && _contactsPermissionGranted)
                      ? _toggleScan
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning
                    ? AppTheme.backgroundColor
                    : AppTheme.textPrimaryColor,
                foregroundColor:
                    _isScanning ? AppTheme.textPrimaryColor : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _isScanning ? 'Stop Scanning' : 'Start Scanning',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int totalEncounters = _contacts.fold(0, (sum, c) => sum + c.encounterCount);

    return Row(
      children: [
        Expanded(
          child: _MinimalStatCard(
            value: '${_contacts.length}',
            label: 'CONTACTS',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MinimalStatCard(
            value: '$totalEncounters',
            label: 'ENCOUNTERS',
          ),
        ),
      ],
    );
  }

  Widget _buildContactsList() {
    if (_contacts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 48,
              color: AppTheme.textSecondaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start scanning to detect nearby devices',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _contacts.map((contact) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ContactCard(contact: contact),
        );
      }).toList(),
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

class _ScanStatItem extends StatelessWidget {
  final String label;
  final String value;

  const _ScanStatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final String label;
  final bool granted;
  final VoidCallback onRequest;

  const _PermissionItem({
    required this.label,
    required this.granted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: granted ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        if (!granted)
          TextButton(
            onPressed: onRequest,
            child: const Text(
              'Allow',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final BluetoothContactModel contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                contact.contactName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.contactName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.deviceName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  dateFormat.format(contact.lastEncounter),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${contact.encounterCount}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'times',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
