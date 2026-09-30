import 'package:chronos/domain/review.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/shifts.dart';
import '../fixtures/tz.dart';

void main() {
  Map<int, Set<ReviewReason>> reasonsOf(List<ReviewItem> items) => {
    for (final i in items) i.shiftId: i.reasons,
  };

  group('computeReviewItems', () {
    test('clean data yields nothing', () {
      final items = computeReviewItems([
        doneShift(
          id: 1,
          start: local(2026, 9, 1, 8),
          end: local(2026, 9, 1, 16),
        ),
        doneShift(
          id: 2,
          start: local(2026, 9, 2, 8),
          end: local(2026, 9, 2, 16),
        ),
      ]);
      expect(items, isEmpty);
    });

    test('16 h or longer', () {
      final items = computeReviewItems([
        doneShift(
          id: 1,
          start: local(2026, 9, 1, 6),
          end: local(2026, 9, 1, 22),
        ),
        doneShift(
          id: 2,
          start: local(2026, 9, 3, 6),
          end: local(2026, 9, 3, 21, 59),
        ),
      ]);
      expect(reasonsOf(items), {
        1: {ReviewReason.tooLong16h},
      });
    });

    test('exactly 23 h and 24 h (v1 turned end ≤ start into these)', () {
      final items = computeReviewItems([
        doneShift(
          id: 1,
          start: local(2026, 5, 26, 9),
          end: local(2026, 5, 27, 8),
        ),
        doneShift(
          id: 2,
          start: local(2026, 6, 1, 9),
          end: local(2026, 6, 2, 9),
        ),
        doneShift(
          id: 3,
          start: local(2026, 6, 5, 9),
          end: local(2026, 6, 6, 7),
        ),
      ]);
      expect(reasonsOf(items), {
        1: {ReviewReason.tooLong16h, ReviewReason.exactly23or24h},
        2: {ReviewReason.tooLong16h, ReviewReason.exactly23or24h},
        3: {ReviewReason.tooLong16h},
      });
    });

    test('duplicate times and duplicate legacy ids', () {
      final items = computeReviewItems([
        doneShift(
          id: 1,
          start: local(2026, 9, 1, 8),
          end: local(2026, 9, 1, 16),
          legacyId: 'a',
        ),
        doneShift(
          id: 2,
          start: local(2026, 9, 1, 8),
          end: local(2026, 9, 1, 16),
          legacyId: 'b',
        ),
        doneShift(
          id: 3,
          start: local(2026, 9, 5, 8),
          end: local(2026, 9, 5, 9),
          legacyId: 'x',
        ),
        doneShift(
          id: 4,
          start: local(2026, 9, 6, 8),
          end: local(2026, 9, 6, 9),
          legacyId: 'x',
        ),
      ]);
      final byId = {for (final i in items) i.shiftId: i};
      expect(byId[1]!.reasons, {
        ReviewReason.duplicateTimes,
        ReviewReason.overlap,
      });
      expect(byId[1]!.relatedShiftIds, {2});
      expect(byId[2]!.relatedShiftIds, {1});
      expect(byId[3]!.reasons, {ReviewReason.duplicateLegacyId});
      expect(byId[3]!.relatedShiftIds, {4});
      expect(byId[4]!.reasons, {ReviewReason.duplicateLegacyId});
    });

    test('overlaps, including nested and chained intervals', () {
      final items = computeReviewItems([
        doneShift(
          id: 1,
          start: local(2026, 9, 1, 8),
          end: local(2026, 9, 1, 18),
        ),
        doneShift(
          id: 2,
          start: local(2026, 9, 1, 9),
          end: local(2026, 9, 1, 10),
        ),
        doneShift(
          id: 3,
          start: local(2026, 9, 1, 17),
          end: local(2026, 9, 1, 20),
        ),
        // Touches 3 only at its end: no overlap.
        doneShift(
          id: 4,
          start: local(2026, 9, 1, 20),
          end: local(2026, 9, 1, 21),
        ),
      ]);
      final byId = {for (final i in items) i.shiftId: i};
      expect(byId[1]!.relatedShiftIds, {2, 3});
      expect(byId[2]!.relatedShiftIds, {1});
      expect(byId[3]!.relatedShiftIds, {1});
      expect(byId.containsKey(4), isFalse);
      expect(byId[1]!.reasons, {ReviewReason.overlap});
    });

    test('shifts on EU DST switch days', () {
      final items = computeReviewItems([
        doneShift(
          id: 1,
          start: local(2026, 3, 29, 8),
          end: local(2026, 3, 29, 16),
        ),
        doneShift(
          id: 2,
          start: local(2026, 10, 24, 22),
          end: local(2026, 10, 25, 6),
        ),
        doneShift(
          id: 3,
          start: local(2025, 10, 26, 8),
          end: local(2025, 10, 26, 9),
        ),
      ]);
      expect(reasonsOf(items), {
        1: {ReviewReason.dstDay},
        2: {ReviewReason.dstDay},
        3: {ReviewReason.dstDay},
      });
    });

    test(
      'Berlin: v1 "23 h" across the autumn switch is flagged by wall time',
      () {
        // 09:00 → next day 08:00 wall clock = 24 h real time on 25 Oct.
        final items = computeReviewItems([
          doneShift(
            id: 1,
            start: local(2026, 10, 24, 9),
            end: local(2026, 10, 25, 8),
          ),
          doneShift(
            id: 2,
            start: local(2026, 3, 28, 9),
            end: local(2026, 3, 29, 9),
          ),
        ]);
        expect(items.first.reasons, contains(ReviewReason.exactly23or24h));
        expect(items.last.reasons, contains(ReviewReason.exactly23or24h));
      },
      skip: skipUnlessBerlin,
    );

    test('deleted and running shifts are ignored', () {
      final items = computeReviewItems([
        doneShift(
          id: 1,
          start: local(2026, 9, 1, 0),
          end: local(2026, 9, 2, 0),
          deletedAt: local(2026, 9, 2),
        ),
        runningShift(id: 2, start: local(2026, 9, 1, 8)),
        doneShift(
          id: 3,
          start: local(2026, 9, 1, 8),
          end: local(2026, 9, 1, 9),
        ),
      ]);
      expect(items, isEmpty);
    });

    test('items are ordered by start', () {
      final items = computeReviewItems([
        doneShift(
          id: 9,
          start: local(2026, 9, 5, 0),
          end: local(2026, 9, 6, 0),
        ),
        doneShift(
          id: 3,
          start: local(2026, 9, 1, 0),
          end: local(2026, 9, 2, 0),
        ),
      ]);
      expect(items.map((i) => i.shiftId), [3, 9]);
    });

    test('ReviewItem equality', () {
      const a = ReviewItem(shiftId: 1, reasons: {ReviewReason.overlap});
      const b = ReviewItem(shiftId: 1, reasons: {ReviewReason.overlap});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(const ReviewItem(shiftId: 1, reasons: {ReviewReason.dstDay})),
      );
      expect(a.toString(), contains('overlap'));
    });
  });

  group('checkWagePlausibility', () {
    test('plausible range 5–100 €/h inclusive', () {
      expect(checkWagePlausibility(1500).isPlausible, isTrue);
      expect(checkWagePlausibility(500).isPlausible, isTrue);
      expect(checkWagePlausibility(10000).isPlausible, isTrue);
    });

    test('1250 €/h (v1 comma bug) suggests 12,50 €/h', () {
      final p = checkWagePlausibility(125000);
      expect(p.issue, WageIssue.tooHigh);
      expect(p.suggestedCentsPerHour, 1250);
      expect(p.isPlausible, isFalse);
    });

    test('125 €/h suggests 12,50 €/h, 139 €/h suggests 13,90 €/h', () {
      expect(checkWagePlausibility(12500).suggestedCentsPerHour, 1250);
      expect(checkWagePlausibility(13900).suggestedCentsPerHour, 1390);
    });

    test('too high without an exact suggestion', () {
      final p = checkWagePlausibility(10001);
      expect(p.issue, WageIssue.tooHigh);
      expect(p.suggestedCentsPerHour, isNull);
    });

    test('too low', () {
      final p = checkWagePlausibility(499);
      expect(p.issue, WageIssue.tooLow);
      expect(p.suggestedCentsPerHour, isNull);
      expect(checkWagePlausibility(0).issue, WageIssue.tooLow);
    });

    test('equality', () {
      expect(checkWagePlausibility(125000), checkWagePlausibility(125000));
      expect(
        checkWagePlausibility(125000).hashCode,
        checkWagePlausibility(125000).hashCode,
      );
      expect(checkWagePlausibility(125000).toString(), contains('1250'));
    });
  });
}
