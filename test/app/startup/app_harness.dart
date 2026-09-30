import 'dart:io';

import 'package:chronos/app/app.dart';
import 'package:chronos/app/notifications/app_notifications.dart';
import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/startup/app_overrides.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/database.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/data/settings_repository.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/platform/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/db.dart';
import '../../fixtures/provider_harness.dart' show FixedLegacySource;
import '../../fixtures/test_clock.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

export '../../support/fakes.dart';
export '../../support/pump_app.dart';

/// "Now" of the app tests: Wednesday 30 Sep 2026, 10:00 in Berlin.
final DateTime kAppNow = DateTime.utc(2026, 9, 30, 8);

/// A running-shift notification as posted.
typedef PostedNotification = ({
  String title,
  String body,
  bool paused,
  String pauseLabel,
  String resumeLabel,
  String finishLabel,
  Duration workedSoFar,
  String? payload,
});

/// A scheduled reminder as posted.
typedef ScheduledReminder = ({
  DateTime at,
  String title,
  String body,
  String finishLabel,
  String? payload,
});

/// [FakeNotificationService] that also records every argument, the channel
/// texts and the tap handler (to simulate taps).
class RecordingNotificationService extends FakeNotificationService {
  /// Creates the fake.
  RecordingNotificationService();

  /// Number of `init` calls.
  int inits = 0;

  /// Channel texts from `init` and `updateChannelTexts`, in order.
  final List<NotificationChannelTexts> channelTexts = [];

  /// The tap handler passed to `init`.
  NotificationTapHandler? onTap;

  /// The background handler passed to `init`.
  BackgroundActionHandler? backgroundHandler;

  /// Every running-shift notification with all arguments.
  final List<PostedNotification> posted = [];

  /// Every scheduled reminder with all arguments.
  final List<ScheduledReminder> scheduled = [];

  /// Number of `launchTap` calls.
  int launchTapCalls = 0;

  /// Number of calls that post, cancel or schedule something.
  int get postingCalls =>
      posted.length + cancelled + scheduled.length + remindersCancelled;

  /// Forgets the posted notifications and reminders.
  void clearRecords() {
    posted.clear();
    shown.clear();
    scheduled.clear();
    reminders.clear();
    cancelled = 0;
    remindersCancelled = 0;
  }

  @override
  Future<bool> init({
    required NotificationChannelTexts channelTexts,
    NotificationTapHandler? onTap,
    BackgroundActionHandler? backgroundHandler,
  }) async {
    inits++;
    this.channelTexts.add(channelTexts);
    this.onTap = onTap;
    this.backgroundHandler = backgroundHandler;
    return true;
  }

  @override
  Future<bool> updateChannelTexts(NotificationChannelTexts texts) async {
    channelTexts.add(texts);
    return true;
  }

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
  }) {
    posted.add((
      title: title,
      body: body,
      paused: paused,
      pauseLabel: pauseLabel,
      resumeLabel: resumeLabel,
      finishLabel: finishLabel,
      workedSoFar: workedSoFar,
      payload: payload,
    ));
    return super.showRunningShift(
      title: title,
      body: body,
      paused: paused,
      pauseLabel: pauseLabel,
      resumeLabel: resumeLabel,
      finishLabel: finishLabel,
      workedSoFar: workedSoFar,
      payload: payload,
    );
  }

  @override
  Future<bool> scheduleReminder({
    required DateTime at,
    required String title,
    required String body,
    required String finishLabel,
    String? payload,
  }) {
    scheduled.add((
      at: at,
      title: title,
      body: body,
      finishLabel: finishLabel,
      payload: payload,
    ));
    return super.scheduleReminder(
      at: at,
      title: title,
      body: body,
      finishLabel: finishLabel,
      payload: payload,
    );
  }

  @override
  Future<NotificationTap?> launchTap() {
    launchTapCalls++;
    return super.launchTap();
  }
}

/// Share service that keeps "temporary files" in memory: widget tests run in
/// a fake-async zone where real file I/O never completes.
class MemoryShareService extends FakeShareService {
  /// Creates the service; paths point into [directory] but nothing is
  /// written.
  MemoryShareService(this.directory) : super(directory);

  /// Folder the returned paths point into.
  final Directory directory;

  /// Texts saved with [saveTextToTemp], by file name.
  final Map<String, String> savedTexts = {};

  /// Number of [clearTemp] calls.
  int clears = 0;

  /// Throw on the next save (to test error handling).
  bool failNextSave = false;

  @override
  Future<File> saveToTemp(String fileName, List<int> bytes) async {
    if (failNextSave) {
      failNextSave = false;
      throw const FileSystemException('disk full');
    }
    return File('${directory.path}/$fileName');
  }

  @override
  Future<File> saveTextToTemp(
    String fileName,
    String text, {
    bool withByteOrderMark = false,
  }) async {
    final file = await saveToTemp(fileName, const []);
    savedTexts[fileName] = text;
    return file;
  }

  @override
  Future<void> clearTemp() async => clears++;
}

/// A folder that cannot be opened: the error log then keeps its entries in
/// memory and the raw v1 backup is skipped, so no real file I/O happens in
/// widget tests.
Future<Directory> noDirectory() =>
    Future<Directory>.error(const FileSystemException('no files in tests'));

/// Fixed device locales / 24 h setting for texts outside the widget tree.
Override deviceFormatOverride({
  List<Locale> locales = const [Locale('de', 'DE')],
  bool use24HourFormat = true,
}) => deviceFormatProvider.overrideWithValue(
  () => (locales: locales, use24HourFormat: use24HourFormat),
);

/// The app's provider graph as `main` builds it (real notification side
/// effects via [chronosOverrides]) on an in-memory database, a test clock,
/// in-memory settings and fake platform services – without file I/O.
class AppHarness {
  /// Creates the harness with the clock at [now] (default [kAppNow]).
  AppHarness({
    DateTime? now,
    LegacyRawData legacy = const LegacyRawData(),
    Map<String, Object>? settings,
    List<Override> overrides = const [],
    Override? deviceFormat,
  }) : clock = TestClock(now ?? kAppNow),
       db = memoryDb(),
       store = InMemoryKeyValueStore(settings),
       legacySource = FixedLegacySource(legacy),
       notifications = RecordingNotificationService(),
       share = MemoryShareService(Directory.systemTemp) {
    errorLog = ErrorLog(directory: noDirectory, clock: clock.clock);
    container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(clock.clock),
        databaseProvider.overrideWithValue(db),
        settingsStoreProvider.overrideWith((ref) async => store),
        documentsDirectoryProvider.overrideWithValue(noDirectory),
        legacySourceProvider.overrideWithValue(legacySource),
        appVersionProvider.overrideWith((ref) async => '2.0.0+2'),
        shareServiceProvider.overrideWithValue(share),
        appInfoServiceProvider.overrideWithValue(fakeAppInfoService()),
        deviceFormat ?? deviceFormatOverride(),
        ...chronosOverrides(
          errorLog: errorLog,
          defaultJobName: 'Mein Job',
          notifications: notifications,
        ),
        ...overrides,
      ],
    );
  }

  /// Test clock.
  final TestClock clock;

  /// In-memory database.
  final AppDatabase db;

  /// Settings store.
  final InMemoryKeyValueStore store;

  /// v1 data source.
  final FixedLegacySource legacySource;

  /// Recording notification service.
  final RecordingNotificationService notifications;

  /// In-memory share service.
  final MemoryShareService share;

  /// Error log (memory only).
  late final ErrorLog errorLog;

  /// The container.
  late final ProviderContainer container;

  /// Reads a provider.
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  /// Creates a job (15,00 €/h since 2026-01-01).
  Future<Job> job({String name = 'Catering', int centsPerHour = 1500}) =>
      read(jobRepositoryProvider).createJob(
        name: name,
        centsPerHour: centsPerHour,
        validFrom: LocalDate(2026, 1, 1),
      );

  /// All shifts that are not deleted (straight from the database).
  Future<List<ShiftRow>> shiftRows() async => [
    for (final row in await db.select(db.shifts).get())
      if (row.deletedAt == null) row,
  ];

  /// Finished shifts (straight from the database).
  Future<List<ShiftRow>> doneRows() async => [
    for (final row in await shiftRows())
      if (row.status == ShiftStatus.done) row,
  ];
}

/// Pumps [child] in a themed, localised test app on [h]'s providers.
Future<void> pumpOnHarness(
  WidgetTester tester,
  AppHarness h,
  Widget child, {
  TestConfig config = const TestConfig(),
  bool settle = true,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
}) async {
  setScreenSize(tester, config.size);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: buildTestApp(
        child,
        brightness: config.brightness,
        locale: config.locale,
        textScale: config.textScale,
        disableAnimations: disableAnimations,
        accessibleNavigation: accessibleNavigation,
        wrapInScaffold: false,
      ),
    ),
  );
  if (settle) await settleApp(tester);
  expectNoLayoutErrors(tester, config);
}

/// Pumps the real [ChronosApp] on [h]'s providers.
Future<void> pumpChronosApp(
  WidgetTester tester,
  AppHarness h, {
  Size size = TestScreens.phoneLarge,
  bool settle = true,
}) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: const ChronosApp(),
    ),
  );
  if (settle) await settleApp(tester);
}

/// Lets database work, streams and side effects complete and the UI settle.
Future<void> settleApp(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
