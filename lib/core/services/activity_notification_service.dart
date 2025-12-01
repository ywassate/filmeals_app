import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:filmeals_app/data/models/location_sensor_data_model.dart';

/// Service de notifications pour confirmer les activités détectées
class ActivityNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialise le service de notifications
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Demander la permission sur Android 13+
    await _requestPermissions();

    _initialized = true;
  }

  /// Demande les permissions de notifications
  Future<void> _requestPermissions() async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  /// Callback quand l'utilisateur tape sur une notification
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Format: "activityId:actionType"
      final parts = payload.split(':');
      if (parts.length == 2) {
        final activityId = parts[0];
        final actionType = parts[1];
        _handleNotificationAction(activityId, actionType);
      }
    }
  }

  /// Gère les actions de notification
  void _handleNotificationAction(String activityId, String actionType) {
    // Cette fonction sera appelée depuis l'UI pour mettre à jour l'activité
    print('Activity $activityId action: $actionType');
    // TODO: Implémenter le callback vers le repository
  }

  /// Envoie une notification de confirmation d'activité
  Future<void> sendActivityConfirmation({
    required String activityId,
    required LocationRecordModel activity,
    required ActivityType detectedType,
    required double confidence,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final emoji = _getActivityEmoji(detectedType);
    final typeText = _getActivityText(detectedType);
    final stats = _formatStats(activity);

    // Style minimaliste pour Android
    const androidDetails = AndroidNotificationDetails(
      'activity_detection',
      'Détection d\'activité',
      channelDescription: 'Notifications pour confirmer les activités détectées',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'confirm',
          'Confirmer',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'walking',
          'Marche',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'running',
          'Course',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'cycling',
          'Vélo',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'driving',
          'Transport',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      activityId.hashCode,
      '$typeText détecté',
      '$emoji $stats',
      notificationDetails,
      payload: '$activityId:${detectedType.toString().split('.').last}',
    );
  }

  /// Formatte les statistiques de l'activité
  String _formatStats(LocationRecordModel activity) {
    final distance = activity.distanceKm.toStringAsFixed(1);
    final duration = activity.durationMinutes;

    return '$distance km en $duration min';
  }

  /// Retourne l'emoji pour le type d'activité
  String _getActivityEmoji(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return '🚶';
      case ActivityType.running:
        return '🏃';
      case ActivityType.cycling:
        return '🚴';
      case ActivityType.driving:
        return '🚌';
      case ActivityType.stationary:
        return '🪑';
      case ActivityType.other:
        return '📍';
    }
  }

  /// Retourne le texte pour le type d'activité
  String _getActivityText(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return 'Marche';
      case ActivityType.running:
        return 'Course';
      case ActivityType.cycling:
        return 'Vélo';
      case ActivityType.driving:
        return 'Transport';
      case ActivityType.stationary:
        return 'Immobile';
      case ActivityType.other:
        return 'Activité';
    }
  }

  /// Annule toutes les notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Annule une notification spécifique
  Future<void> cancel(String activityId) async {
    await _notificationsPlugin.cancel(activityId.hashCode);
  }
}
