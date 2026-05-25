import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class TimerProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();
  
  DateTime? _startTime;
  DateTime? get startTime => _startTime;
  
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  double _hourlyWage = 0.0;

  bool get isRunning => _startTime != null;

  void setHourlyWage(double wage) {
    _hourlyWage = wage;
  }

  Future<void> loadActiveSession() async {
    _startTime = await _storage.getActiveSession();
    if (_startTime != null) {
      _startTimer();
    }
  }

  Future<void> start() async {
    _startTime = DateTime.now();
    await _storage.saveActiveSession(_startTime);
    _startTimer();
    notifyListeners();
  }

  Future<DateTime?> stop() async {
    if (_startTime == null) return null;
    
    _timer?.cancel();
    final endTime = DateTime.now();
    await _storage.saveActiveSession(null);
    _startTime = null;
    _elapsed = Duration.zero;
    _lastNotificationUpdate = 0;
    await _notificationService.cancelWorkSessionNotification();
    notifyListeners();
    return endTime;
  }

  int _lastNotificationUpdate = 0;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        _elapsed = DateTime.now().difference(_startTime!);
        _maybeUpdateNotification();
        notifyListeners();
      }
    });
  }

  void _maybeUpdateNotification() {
    final currentSecond = _elapsed.inSeconds;
    // Update notification every 30 seconds (only earnings text changes; timer runs natively)
    if (currentSecond - _lastNotificationUpdate >= 15 || _lastNotificationUpdate == 0) {
      _lastNotificationUpdate = currentSecond;
      final earnings = getCurrentEarnings(_hourlyWage);
      _notificationService.showWorkSessionNotification(
        startTime: _startTime!,
        earnings: earnings,
      );
    }
  }

  double getCurrentEarnings(double hourlyWage) {
    if (_startTime == null) return 0.0;
    final hours = _elapsed.inMilliseconds / (1000 * 60 * 60);
    return hours * hourlyWage;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
