import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/payout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/shifts.dart';

void main() {
  group('selectForPayout', () {
    final shifts = [
      doneShift(id: 1, start: local(2026, 9, 1, 8), end: local(2026, 9, 1, 16)),
      doneShift(
        id: 2,
        jobId: 2,
        start: local(2026, 9, 2, 8),
        end: local(2026, 9, 2, 12),
        tips: 500,
      ),
      doneShift(
        id: 3,
        start: local(2026, 9, 3, 8),
        end: local(2026, 9, 3, 16),
        paid: true,
      ),
      doneShift(
        id: 4,
        start: local(2026, 9, 4, 8),
        end: local(2026, 9, 4, 16),
        deletedAt: local(2026, 9, 5),
      ),
      // Overnight shift starting on the 10th belongs to the 10th.
      doneShift(
        id: 5,
        start: local(2026, 9, 10, 22),
        end: local(2026, 9, 11, 6),
      ),
      doneShift(
        id: 6,
        start: local(2026, 9, 11, 8),
        end: local(2026, 9, 11, 9),
      ),
      runningShift(id: 7, start: local(2026, 9, 12, 8)),
    ];

    test('open shifts up to and including the date, all jobs', () {
      final sel = selectForPayout(shifts, until: LocalDate(2026, 9, 10));
      expect(sel.shiftIds, [1, 2, 5]);
      expect(sel.count, 3);
      expect(sel.expectedCents, 12000 + 6000 + 12000);
      expect(sel.workedMs, 20 * msPerHour);
      expect(sel.tipsCents, 500);
      expect(sel.isEmpty, isFalse);
    });

    test('filtered by job', () {
      final sel = selectForPayout(
        shifts,
        until: LocalDate(2026, 9, 30),
        jobId: 1,
      );
      expect(sel.shiftIds, [1, 5, 6]);
    });

    test('nothing open', () {
      final sel = selectForPayout(shifts, until: LocalDate(2026, 8, 31));
      expect(sel.isEmpty, isTrue);
      expect(sel, PayoutSelection.empty);
    });

    test('equality', () {
      final a = selectForPayout(shifts, until: LocalDate(2026, 9, 10));
      final b = selectForPayout(shifts.reversed, until: LocalDate(2026, 9, 10));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('3 shifts'));
    });
  });

  group('Payout', () {
    final payout = Payout(
      id: 1,
      uuid: 'p1',
      jobId: 2,
      untilDate: LocalDate(2026, 9, 30),
      paidOn: LocalDate(2026, 10, 5),
      expectedCents: 258750,
      receivedCents: 250000,
      createdAt: DateTime.utc(2026, 10, 5),
      note: 'Sept',
    );

    test('difference', () {
      expect(payout.differenceCents, -8750);
    });

    test('copyWith can clear nullable fields', () {
      final c = payout.copyWith(jobId: null, note: null, receivedCents: 1);
      expect(c.jobId, isNull);
      expect(c.note, isNull);
      expect(c.receivedCents, 1);
      expect(payout.copyWith(), payout);
      expect(payout.copyWith().hashCode, payout.hashCode);
      expect(payout.toString(), contains('258750'));
    });
  });
}
