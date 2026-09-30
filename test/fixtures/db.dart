import 'dart:io';

import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/database.dart';
import 'package:chronos/data/job_repository.dart';
import 'package:chronos/data/shift_repository.dart';
import 'package:chronos/domain/job.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_clock.dart';

/// A fresh in-memory database; closed automatically after the test.
AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// A temporary directory, deleted after the test.
Directory tempDir() {
  final dir = Directory.systemTemp.createTempSync('chronos_test_');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return dir;
}

/// Database, clock and repositories wired together for data tests.
class DataHarness {
  /// Creates the harness with the clock at [now].
  DataHarness(DateTime now) : clock = TestClock(now), db = memoryDb() {
    jobs = JobRepository(db, clock: clock.clock);
    shifts = ShiftRepository(db, clock: clock.clock, jobs: jobs);
  }

  /// Test clock.
  final TestClock clock;

  /// In-memory database.
  final AppDatabase db;

  /// Job repository.
  late final JobRepository jobs;

  /// Shift repository.
  late final ShiftRepository shifts;

  /// Creates a job with [centsPerHour] valid since 2026-01-01.
  Future<Job> job({
    String name = 'Catering',
    int centsPerHour = 1500,
    RoundingRule rounding = RoundingRule.none,
  }) => jobs.createJob(
    name: name,
    centsPerHour: centsPerHour,
    rounding: rounding,
    validFrom: LocalDate(2026, 1, 1),
  );
}
