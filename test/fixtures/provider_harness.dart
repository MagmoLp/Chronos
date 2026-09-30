import 'dart:io';

import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/database.dart';
import 'package:chronos/data/legacy/legacy_migration.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/data/settings_repository.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'db.dart';
import 'test_clock.dart';

/// Records every side-effects call.
class RecordingSideEffects implements ShiftSideEffects {
  /// All calls in order.
  final List<({Shift? running, Job? job})> calls = [];

  /// Throw on the next call (to test error handling).
  bool fail = false;

  /// The last call.
  ({Shift? running, Job? job}) get last => calls.last;

  @override
  Future<void> shiftChanged(Shift? running, Job? job) async {
    if (fail) throw StateError('notification failed');
    calls.add((running: running, job: job));
  }
}

/// A legacy source with fixed data.
class FixedLegacySource implements LegacySource {
  /// Creates the source.
  FixedLegacySource([this.data = const LegacyRawData()]);

  /// Data returned by [read].
  LegacyRawData data;

  /// Throw on read (to test bootstrap failures).
  bool fail = false;

  @override
  Future<LegacyRawData> read() async {
    if (fail) throw const FileSystemException('prefs unreadable');
    return data;
  }
}

/// A [ProviderContainer] with in-memory database, test clock, in-memory
/// settings, temp folders and recording side effects.
class ProviderHarness {
  /// Creates the harness with the clock at [now].
  ProviderHarness(
    DateTime now, {
    LegacyRawData legacy = const LegacyRawData(),
    List<Override> overrides = const [],
  }) : clock = TestClock(now),
       db = memoryDb(),
       dir = tempDir(),
       store = InMemoryKeyValueStore(),
       effects = RecordingSideEffects(),
       legacySource = FixedLegacySource(legacy) {
    errorLog = ErrorLog(directory: () async => dir, clock: clock.clock);
    container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(clock.clock),
        databaseProvider.overrideWithValue(db),
        settingsStoreProvider.overrideWith((ref) async => store),
        documentsDirectoryProvider.overrideWithValue(() async => dir),
        legacySourceProvider.overrideWithValue(legacySource),
        appVersionProvider.overrideWith((ref) async => '2.0.0+2'),
        errorLogProvider.overrideWithValue(errorLog),
        shiftSideEffectsProvider.overrideWithValue(effects),
        ...overrides,
      ],
    );
  }

  /// Test clock.
  final TestClock clock;

  /// In-memory database.
  final AppDatabase db;

  /// Temporary folder (documents, error log).
  final Directory dir;

  /// Settings store.
  final InMemoryKeyValueStore store;

  /// Side-effects recorder.
  final RecordingSideEffects effects;

  /// v1 data source.
  final FixedLegacySource legacySource;

  /// Error log in [dir].
  late final ErrorLog errorLog;

  /// The container.
  late final ProviderContainer container;

  /// Reads a provider.
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  /// Keeps [provider] alive for the rest of the test.
  void keepAlive<T>(ProviderListenable<T> provider) {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
  }

  /// Latest data of an async provider after pending database updates
  /// settled (keeps the provider alive).
  Future<T> settle<T>(ProviderListenable<AsyncValue<T>> provider) async {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 5; i++) {
      await pumpEventQueue();
    }
    final value = sub.read();
    if (value.hasError) throw value.error!;
    if (!value.hasValue) {
      throw StateError('$provider has no value (still loading)');
    }
    return value.requireValue;
  }

  /// Creates a job (15,00 €/h since 2026-01-01).
  Future<Job> job({
    String name = 'Catering',
    int centsPerHour = 1500,
    RoundingRule rounding = RoundingRule.none,
  }) => read(jobRepositoryProvider).createJob(
    name: name,
    centsPerHour: centsPerHour,
    rounding: rounding,
    validFrom: LocalDate(2026, 1, 1),
  );
}
