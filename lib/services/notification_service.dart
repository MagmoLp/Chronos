import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _workSessionNotificationId = 1;
  static const String _channelId = 'work_session_timer';
  static const String _channelName = 'Arbeitssession';
  static const String _channelDescription = 'Zeigt die aktive Arbeitssession an';

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Request notification permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showWorkSessionNotification({
    required DateTime startTime,
    required double earnings,
  }) async {
    final earningsString = earnings.toStringAsFixed(2);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      usesChronometer: true,
      chronometerCountDown: false,
      when: startTime.millisecondsSinceEpoch,
      silent: true,
      category: AndroidNotificationCategory.service,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      _workSessionNotificationId,
      'Arbeite',
      'Verdient: $earningsString €',
      details,
    );
  }

  Future<void> cancelWorkSessionNotification() async {
    await _plugin.cancel(_workSessionNotificationId);
  }
}
