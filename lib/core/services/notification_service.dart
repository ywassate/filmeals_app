import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {

  // Singleton
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialiser les notifications
  Future<void> init() async {
    if (_isInitialized) return;

    // Sur Linux (WSL), on ne fait rien car il y a des problèmes de compatibilité
    if (Platform.isLinux) {
      print("⚠️ [NotificationService] Désactivé sur Linux (WSL)");
      _isInitialized = true;
      return;
    }

    try {
      // Initialiser les fuseaux horaires
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));

      // Configuration Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configuration complète
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      print("✅ [NotificationService] Initialisé");
    } catch (e) {
      print("❌ [NotificationService] Erreur d'initialisation: $e");
      print("⚠️ [NotificationService] Les notifications ne seront pas disponibles");
      // On marque quand même comme initialisé pour éviter de réessayer
      _isInitialized = true;
    }
  }

  /// Callback quand l'utilisateur tape sur la notification
  void _onNotificationTapped(NotificationResponse response) {
    print("🔔 Notification tapée: ${response.payload}");
  }

  /// Activer les notifications (version sûre)
  Future<void> enableNotifications() async {
    await init();

    // Sur Linux, on ne fait rien
    if (Platform.isLinux) {
      print("⚠️ [NotificationService] Notifications programmées non disponibles sur Linux");
      return;
    }

    // Sur Android/iOS, programmer les notifications
    await _scheduleEveningNotification();
    await _scheduleMorningNotification();
    print("✅ [NotificationService] Toutes les notifications activées");
  }

  /// Programmer la notification du soir (22h) - PRIVÉ
  Future<void> _scheduleEveningNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      1,
      '🌙 C\'est l\'heure de dormir !',
      'Pense à noter vers quelle heure tu vas te coucher',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_evening_channel',
          'Rappel du soir',
          channelDescription: 'Notifications pour enregistrer l\'heure de coucher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print("✅ [NotificationService] Notification du soir programmée pour 22h");
  }

  /// Programmer la notification du matin (7h) - PRIVÉ
  Future<void> _scheduleMorningNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      2,
      '☀️ Bonjour !',
      'Es-tu réveillé ? Note ton heure de réveil',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_morning_channel',
          'Rappel du matin',
          channelDescription: 'Notifications pour enregistrer l\'heure de réveil',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print("✅ [NotificationService] Notification du matin programmée pour 7h");
  }

  /// Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print("🔕 [NotificationService] Toutes les notifications annulées");
  }

  /// Tester les notifications (immédiat) - Fonctionne sur toutes les plateformes
  Future<void> testNotification() async {
    await init();

    // Sur Linux, on ne peut pas envoyer de notifications
    if (Platform.isLinux) {
      print("❌ [NotificationService] Les notifications ne sont pas supportées sur Linux/WSL");
      throw UnsupportedError('Les notifications ne sont pas disponibles sur Linux/WSL');
    }

    await _notifications.show(
      999,
      '🧪 Test de notification',
      'Si tu vois ce message, les notifications fonctionnent !',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test',
          channelDescription: 'Canal de test',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    print("🧪 [NotificationService] Notification de test envoyée");
  }
}
