import 'package:chronos/data/database.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/data/mappers.dart';
import 'package:chronos/data/review_repository.dart';
import 'package:chronos/domain/review.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/db.dart';
import '../fixtures/shifts.dart';

void main() {
  late DataHarness h;
  late ReviewRepository review;
  late int s1;
  late int s2;

  setUp(() async {
    h = DataHarness(local(2026, 9, 30, 12));
    review = ReviewRepository(h.db);
    final job = await h.job();
    s1 = (await h.shifts.insertManual(
      ShiftDraft(
        jobId: job.id,
        startUtc: local(2026, 9, 2, 8),
        endUtc: local(2026, 9, 2, 16),
      ),
    )).id;
    s2 = (await h.shifts.insertManual(
      ShiftDraft(
        jobId: job.id,
        startUtc: local(2026, 9, 1, 8),
        endUtc: local(2026, 9, 1, 16),
      ),
    )).id;
  });

  test('put, watch (oldest shift first), dismiss', () async {
    await review.putItems([
      ReviewItem(
        shiftId: s1,
        reasons: const {ReviewReason.overlap},
        relatedShiftIds: {s2},
      ),
      ReviewItem(
        shiftId: s2,
        reasons: const {ReviewReason.dstDay, ReviewReason.tooLong16h},
      ),
    ]);
    final items = await review.watchItems().first;
    expect(items.map((i) => i.shiftId), [s2, s1]);
    expect(items.last.relatedShiftIds, {s2});
    expect(items.first.reasons, {ReviewReason.dstDay, ReviewReason.tooLong16h});
    await review.dismiss(s1);
    expect((await review.getItems()).single.shiftId, s2);
    await review.dismissAll();
    expect(await review.getItems(), isEmpty);
  });

  test(
    'items of soft-deleted shifts are hidden, purged ones removed',
    () async {
      await review.putItems([
        ReviewItem(shiftId: s1, reasons: const {ReviewReason.overlap}),
      ]);
      await h.shifts.softDelete([s1]);
      expect(await review.getItems(), isEmpty);
      await h.shifts.undoDelete([s1]);
      expect(await review.getItems(), hasLength(1));
      await h.shifts.softDelete([s1]);
      await h.shifts.purgeDeleted(
        before: h.clock.now.add(const Duration(seconds: 1)),
      );
      await h.shifts.undoDelete([s1]);
      expect(await h.db.select(h.db.reviewItems).get(), isEmpty);
    },
  );

  test('putItems replaces existing items', () async {
    await review.putItems([
      ReviewItem(shiftId: s1, reasons: const {ReviewReason.overlap}),
    ]);
    await review.putItems([
      ReviewItem(shiftId: s1, reasons: const {ReviewReason.dstDay}),
    ]);
    expect((await review.getItems()).single.reasons, {ReviewReason.dstDay});
  });

  test('legacy failures', () async {
    await h.db
        .into(h.db.legacyErrors)
        .insert(
          LegacyErrorsCompanion.insert(
            origin: 'work_entries[3]',
            raw: '{"id":1}',
            code: LegacyErrorCode.missingStartTime.name,
            message: const Value('x'),
            createdAt: 0,
          ),
        );
    await h.db
        .into(h.db.legacyErrors)
        .insert(
          LegacyErrorsCompanion.insert(
            origin: 'active_session',
            raw: 'garbage',
            code: 'someFutureCode',
            createdAt: 0,
          ),
        );
    final failures = await review.watchLegacyFailures().first;
    expect(failures, hasLength(2));
    expect(failures.first.code, LegacyErrorCode.missingStartTime);
    expect(failures.first.message, 'x');
    expect(failures.first.toJson()['origin'], 'work_entries[3]');
    expect(failures.last.code, LegacyErrorCode.insertFailed);
    expect(await review.getLegacyFailures(), failures);
  });

  test('reason encoding round-trips and ignores unknown names', () {
    final encoded = encodeReviewReasons({
      ReviewReason.overlap,
      ReviewReason.dstDay,
    });
    expect(encoded, 'dstDay,overlap');
    expect(decodeReviewReasons('$encoded,unknown'), {
      ReviewReason.overlap,
      ReviewReason.dstDay,
    });
    expect(decodeReviewReasons(''), isEmpty);
  });
}
