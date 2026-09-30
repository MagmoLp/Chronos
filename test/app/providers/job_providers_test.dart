import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/job.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/provider_harness.dart';
import '../../fixtures/shifts.dart';

void main() {
  late ProviderHarness h;
  late JobsController controller;

  setUp(() {
    h = ProviderHarness(local(2026, 9, 30, 12));
    controller = h.read(jobsControllerProvider.notifier);
  });

  test('completeOnboarding creates the first job and sets the flag', () async {
    await h.read(settingsRepositoryProvider.future);
    final job = await controller.completeOnboarding(
      name: 'Mein Job',
      centsPerHour: 1250,
    );
    expect(job.rounding, RoundingRule.none);
    expect(h.read(settingsProvider).onboardingDone, isTrue);
    final rates = await h.settle(jobRatesProvider(job.id));
    expect(rates.single.centsPerHour, 1250);
    expect(rates.single.validFrom, LocalDate(2026, 9, 30));
    expect((await h.settle(jobByIdProvider(job.id)))!.name, 'Mein Job');
    expect(await h.settle(jobByIdProvider(999)), isNull);
  });

  test('create, update, archive, reorder', () async {
    final a = await controller.create(name: 'A', centsPerHour: 1500);
    final b = await controller.create(
      name: 'B',
      centsPerHour: 2000,
      rounding: RoundingRule.nearest5,
    );
    expect((await h.settle(jobsProvider)).map((j) => j.name), ['A', 'B']);
    await controller.update(a.copyWith(name: 'A2'));
    await controller.setArchived(b.id, true);
    expect((await h.settle(activeJobsProvider)).map((j) => j.name), ['A2']);
    expect(await h.settle(jobsProvider), hasLength(2));
    await expectLater(
      controller.setArchived(a.id, true),
      throwsA(isA<ChronosException>()),
    );
    await controller.setArchived(b.id, false);
    await controller.reorder([b.id, a.id]);
    expect((await h.settle(jobsProvider)).map((j) => j.name), ['B', 'A2']);
  });

  test(
    'renaming or re-pricing the running job re-posts the notification',
    () async {
      final job = await h.job();
      final other = await h.job(name: 'Other');
      await h.read(activeShiftControllerProvider.notifier).start(job.id);
      final before = h.effects.calls.length;
      await controller.update(other.copyWith(name: 'X'));
      expect(h.effects.calls.length, before);
      await controller.update(job.copyWith(name: 'Gala'));
      expect(h.effects.calls.length, before + 1);
      expect(h.effects.last.job!.name, 'Gala');
      final count = await controller.addRate(
        job.id,
        validFrom: LocalDate(2026, 9, 30),
        centsPerHour: 1800,
        recalcOpenFromDate: true,
      );
      expect(count, 1);
      expect(h.effects.last.running!.rateCentsPerHour, 1800);
      final plain = await controller.addRate(
        job.id,
        validFrom: LocalDate(2026, 10, 1),
        centsPerHour: 1900,
      );
      expect(plain, 0);
      final rates = await h.settle(jobRatesProvider(job.id));
      expect(rates.map((r) => r.centsPerHour), [1900, 1800, 1500]);
      await controller.deleteRate(rates.first.id);
      expect((await h.settle(jobRatesProvider(job.id))), hasLength(2));
    },
  );
}
