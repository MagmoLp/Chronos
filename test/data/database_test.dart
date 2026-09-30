import 'package:chronos/data/database.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());

  Future<int> insertJob() => db
      .into(db.jobs)
      .insert(
        JobsCompanion.insert(
          uuid: 'j1',
          name: 'Job',
          colorArgb: 1,
          rounding: RoundingRule.none,
          createdAt: 0,
          updatedAt: 0,
        ),
      );

  ShiftsCompanion shift(
    int jobId,
    String uuid,
    ShiftStatus status, {
    int? deletedAt,
  }) => ShiftsCompanion.insert(
    uuid: uuid,
    jobId: jobId,
    status: status,
    startUtc: 0,
    rawStartUtc: 0,
    startOffsetMin: 0,
    rateCentsPerHour: 1500,
    source: ShiftSource.timer,
    createdAt: 0,
    updatedAt: 0,
    deletedAt: Value(deletedAt),
  );

  test('schema version 1', () {
    expect(db.schemaVersion, 1);
  });

  test('meta get / set / delete', () async {
    expect(await db.getMeta('k'), isNull);
    await db.setMeta('k', 'a');
    await db.setMeta('k', 'b');
    expect(await db.getMeta('k'), 'b');
    await db.deleteMeta('k');
    expect(await db.getMeta('k'), isNull);
  });

  test('the database allows only one running (non-deleted) shift', () async {
    final jobId = await insertJob();
    await db.into(db.shifts).insert(shift(jobId, 'a', ShiftStatus.running));
    expect(
      () => db.into(db.shifts).insert(shift(jobId, 'b', ShiftStatus.running)),
      throwsA(isA<Exception>()),
    );
    // A soft-deleted running shift does not block, finished ones never do.
    await db
        .into(db.shifts)
        .insert(shift(jobId, 'c', ShiftStatus.running, deletedAt: 1));
    await db.into(db.shifts).insert(shift(jobId, 'd', ShiftStatus.done));
    await db.into(db.shifts).insert(shift(jobId, 'e', ShiftStatus.done));
    expect(await db.select(db.shifts).get(), hasLength(4));
  });

  test('foreign keys are enforced', () async {
    expect(
      () => db.into(db.shifts).insert(shift(999, 'x', ShiftStatus.done)),
      throwsA(isA<Exception>()),
    );
  });

  test('review items are removed with their shift', () async {
    final jobId = await insertJob();
    final shiftId = await db
        .into(db.shifts)
        .insert(shift(jobId, 'a', ShiftStatus.done));
    await db
        .into(db.reviewItems)
        .insert(
          ReviewItemsCompanion.insert(
            shiftId: Value(shiftId),
            reasons: 'overlap',
          ),
        );
    await (db.delete(db.shifts)..where((t) => t.id.equals(shiftId))).go();
    expect(await db.select(db.reviewItems).get(), isEmpty);
  });

  test('deleteAllData keeps meta', () async {
    final jobId = await insertJob();
    await db.into(db.shifts).insert(shift(jobId, 'a', ShiftStatus.done));
    await db
        .into(db.wageRates)
        .insert(
          WageRatesCompanion.insert(
            jobId: jobId,
            validFrom: 20260101,
            centsPerHour: 1500,
          ),
        );
    await db
        .into(db.payouts)
        .insert(
          PayoutsCompanion.insert(
            uuid: 'p',
            untilDate: 20260101,
            paidOn: 20260101,
            expectedCents: 0,
            receivedCents: 0,
            createdAt: 0,
          ),
        );
    await db
        .into(db.legacyErrors)
        .insert(
          LegacyErrorsCompanion.insert(
            origin: 'o',
            raw: 'r',
            code: 'c',
            createdAt: 0,
          ),
        );
    await db.setMeta('legacy', '1');
    await db.deleteAllData();
    expect(await db.select(db.jobs).get(), isEmpty);
    expect(await db.select(db.shifts).get(), isEmpty);
    expect(await db.select(db.wageRates).get(), isEmpty);
    expect(await db.select(db.payouts).get(), isEmpty);
    expect(await db.select(db.legacyErrors).get(), isEmpty);
    expect(await db.getMeta('legacy'), '1');
  });
}
