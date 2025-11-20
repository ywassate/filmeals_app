import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions Bluetooth accordées')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission Contacts accordée')),
      );
    } else {
      _showPermissionDeniedDialog('Contacts');
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission refusée'),
        content: Text(
            'L\'accès à $permissionType est nécessaire pour le fonctionnement du scan.\n\n'
            'Voulez-vous ouvrir les paramètres ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PermissionService.openSettings();
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleScan() async {
    if (!_bluetoothPermissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions Bluetooth requises')),
      );
      return;
    }

    if (!_contactsPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission Contacts requise')),
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
        // Durée minimum: 5 minutes (300 secondes)
        BluetoothService.instance.setMinimumDuration(300);

        await BluetoothService.instance.startContinuousScan(
          onProgress: (total, pending, validated) {
            if (mounted) {
              setState(() {
                _appareilsDetectes = total;
                _pendingDetections = pending;
                _validatedContacts += validated;
              });

              // Recharger la liste si de nouveaux contacts sont validés
              if (validated > 0) {
                _loadContacts();
              }
            }
          },
        );

        // Le scan continue jusqu'à ce que l'utilisateur l'arrête
        // pas de setState(_isScanning = false) ici

      } catch (e) {
        setState(() {
          _isScanning = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteAllContacts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les contacts ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BluetoothService.instance.deleteAllContacts();
      _loadContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tous les contacts supprimés')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.socialGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.bluetooth_searching_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Social',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Détection Bluetooth des contacts',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (_contacts.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  onPressed: _deleteAllContacts,
                  tooltip: 'Supprimer tout',
                ),
            ],
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permissions
                  if (!_bluetoothPermissionsGranted ||
                      !_contactsPermissionGranted)
                    _buildPermissionsCard(),

                  if (!_bluetoothPermissionsGranted ||
                      !_contactsPermissionGranted)
                    const SizedBox(height: 24),

                  // Scanner
                  _buildScannerCard(),
                  const SizedBox(height: 24),

                  // Statistiques
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // Liste des contacts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contacts détectés (${_contacts.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadContacts,
                        tooltip: 'Rafraîchir',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContactsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Permissions requises',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bluetooth
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _bluetoothPermissionsGranted
                  ? Icons.check_circle
                  : Icons.cancel,
              color:
                  _bluetoothPermissionsGranted ? Colors.green : Colors.red,
            ),
            title: const Text('Bluetooth'),
            trailing: _bluetoothPermissionsGranted
                ? null
                : ElevatedButton(
                    onPressed: _requestBluetoothPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.socialColor,
                    ),
                    child: const Text('Autoriser'),
                  ),
          ),
          // Contacts
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _contactsPermissionGranted
                  ? Icons.check_circle
                  : Icons.cancel,
              color: _contactsPermissionGranted ? Colors.green : Colors.red,
            ),
            title: const Text('Contacts'),
            trailing: _contactsPermissionGranted
                ? null
                : ElevatedButton(
                    onPressed: _requestContactsPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.socialColor,
                    ),
                    child: const Text('Autoriser'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _isScanning
            ? LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              )
            : AppTheme.socialGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isScanning ? Colors.green : AppTheme.socialColor)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isScanning) ...[
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Scan continu actif',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan toutes les 5 minutes',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              '$_appareilsDetectes appareils trackés',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '$_pendingDetections en attente (< 5min)',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '$_validatedContacts validés (≥ 5min)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            const Icon(
              Icons.bluetooth_searching_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Prêt à scanner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_contacts.length} contacts enregistrés',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_bluetoothPermissionsGranted &&
                      _contactsPermissionGranted)
                  ? _toggleScan
                  : null,
              icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
              label: Text(
                _isScanning ? 'Arrêter le scan continu' : 'Démarrer le scan continu',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning ? Colors.red : Colors.white,
                foregroundColor: _isScanning ? Colors.white : AppTheme.socialColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int totalEncounters =
        _contacts.fold(0, (sum, c) => sum + c.encounterCount);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_rounded,
            value: '${_contacts.length}',
            label: 'Contacts',
            color: AppTheme.socialColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.bluetooth_connected_rounded,
            value: '$totalEncounters',
            label: 'Rencontres',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildContactsList() {
    if (_contacts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.bluetooth_disabled_rounded,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun contact détecté',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Lancez un scan pour détecter\nles appareils Bluetooth à proximité',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.socialColor,
            radius: 24,
            child: Text(
              contact.contactName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                  'Dernière: ${dateFormat.format(contact.lastEncounter)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.socialColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${contact.encounterCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.socialColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'rencontres',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
