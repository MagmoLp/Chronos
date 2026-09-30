import 'dart:io';

import 'package:chronos/platform/app_info.dart';
import 'package:chronos/platform/notifications.dart';
import 'package:chronos/platform/share_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Notification service that records calls instead of talking to Android.
class FakeNotificationService extends NotificationService {
  /// Creates the fake; notifications start [enabled].
  FakeNotificationService({this.enabled = true, this.grantOnRequest = true})
    : super(plugin: AndroidFlutterLocalNotificationsPlugin());

  /// Whether notifications are allowed.
  bool enabled;

  /// What [requestPermission] answers.
  bool grantOnRequest;

  /// Number of permission requests.
  int permissionRequests = 0;

  /// Number of times the system settings were opened.
  int settingsOpened = 0;

  /// Every posted running-shift notification (title, body, paused).
  final List<({String title, String body, bool paused, String? payload})>
  shown = [];

  /// Number of cancelled running-shift notifications.
  int cancelled = 0;

  /// Scheduled reminders (time, title).
  final List<({DateTime at, String title})> reminders = [];

  /// Number of cancelled reminders.
  int remindersCancelled = 0;

  /// Returned by [launchTap].
  NotificationTap? launch;

  @override
  Future<bool> init({
    required NotificationChannelTexts channelTexts,
    NotificationTapHandler? onTap,
    BackgroundActionHandler? backgroundHandler,
  }) async => true;

  @override
  Future<bool> updateChannelTexts(NotificationChannelTexts texts) async => true;

  @override
  Future<bool> showRunningShift({
    required String title,
    required String body,
    required bool paused,
    required String pauseLabel,
    required String resumeLabel,
    required String finishLabel,
    Duration workedSoFar = Duration.zero,
    String? payload,
  }) async {
    shown.add((title: title, body: body, paused: paused, payload: payload));
    return true;
  }

  @override
  Future<void> cancelRunningShift() async => cancelled++;

  @override
  Future<List<int>> activeNotificationIds() async => const [];

  @override
  Future<bool> isRunningShiftVisible() async => shown.isNotEmpty;

  @override
  Future<bool> scheduleReminder({
    required DateTime at,
    required String title,
    required String body,
    required String finishLabel,
    String? payload,
  }) async {
    reminders.add((at: at, title: title));
    return true;
  }

  @override
  Future<void> cancelReminder() async => remindersCancelled++;

  @override
  Future<bool> areNotificationsEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    enabled = grantOnRequest;
    return enabled;
  }

  @override
  Future<bool> openNotificationSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<NotificationTap?> launchTap() async => launch;
}

/// Share service that records shares instead of opening the share sheet.
class FakeShareService extends ShareService {
  /// Creates the fake writing temp files to [directory].
  FakeShareService(Directory directory)
    : super(temporaryDirectory: () async => directory);

  /// Shared files (path, MIME type, subject).
  final List<({String path, String mimeType, String? subject})> sharedFiles =
      [];

  /// Shared texts.
  final List<String> sharedTexts = [];

  /// Returned by [pickBackupFile] (null = user cancelled).
  PickedFile? nextPick;

  @override
  Future<ShareOutcome> shareFile(
    String path, {
    required String mimeType,
    String? subject,
    String? text,
    String? title,
  }) async {
    sharedFiles.add((path: path, mimeType: mimeType, subject: subject));
    return ShareOutcome.shared;
  }

  @override
  Future<ShareOutcome> shareText(
    String text, {
    String? subject,
    String? title,
  }) async {
    sharedTexts.add(text);
    return ShareOutcome.shared;
  }

  @override
  Future<PickedFile?> pickBackupFile({
    String? dialogTitle,
    int maxBytes = ShareService.defaultMaxBackupBytes,
  }) async => nextPick;
}

/// App info with a fixed version.
AppInfoService fakeAppInfoService() => AppInfoService(
  loader: () async => PackageInfo(
    appName: 'Chronos',
    packageName: 'com.paulhuebner.chronos',
    version: '2.0.0',
    buildNumber: '2',
  ),
);
