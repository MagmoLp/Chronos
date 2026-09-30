import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/local_date.dart';
import '../../data/job_repository.dart';
import '../../domain/job.dart';
import '../../domain/shift.dart';
import '../../domain/wage_rate.dart';
import 'async_utils.dart';
import 'core_providers.dart';
import 'settings_providers.dart';
import 'shift_providers.dart';

/// All jobs including archived ones, in list order.
final jobsProvider = StreamProvider<List<Job>>(
  (ref) => ref.watch(jobRepositoryProvider).watchJobs(),
  name: 'jobsProvider',
);

/// Jobs that are not archived (pickers). The job chip is shown only if
/// there is more than one.
final activeJobsProvider = StreamProvider<List<Job>>(
  (ref) => ref.watch(jobRepositoryProvider).watchJobs(includeArchived: false),
  name: 'activeJobsProvider',
);

/// One job by id (`null` if unknown).
final jobByIdProvider = Provider.autoDispose.family<AsyncValue<Job?>, int>(
  (ref, id) => ref.watch(jobsProvider).whenData((jobs) {
    for (final job in jobs) {
      if (job.id == id) return job;
    }
    return null;
  }),
  name: 'jobByIdProvider',
);

/// Wage history of a job, newest first.
final jobRatesProvider = StreamProvider.autoDispose.family<List<WageRate>, int>(
  (ref, jobId) => ref.watch(jobRepositoryProvider).watchRates(jobId),
  name: 'jobRatesProvider',
);

/// The job preselected for "Schicht starten" / new shifts: the running
/// shift's job, else the job of the last shift, else the first active job
/// (archived jobs are never chosen). `null` if there are no active jobs.
final defaultJobProvider = Provider<AsyncValue<Job?>>((ref) {
  return combineAsync3(
    ref.watch(activeJobsProvider),
    ref.watch(runningShiftProvider),
    ref.watch(lastShiftProvider),
    (List<Job> jobs, Shift? running, Shift? last) {
      Job? find(int? id) {
        for (final job in jobs) {
          if (job.id == id) return job;
        }
        return null;
      }

      return find(running?.jobId) ??
          find(last?.jobId) ??
          (jobs.isEmpty ? null : jobs.first);
    },
  );
}, name: 'defaultJobProvider');

/// Whether onboarding must be shown: there is no active job (fresh install
/// without v1 data, or after "delete all data").
final onboardingNeededProvider = Provider<AsyncValue<bool>>(
  (ref) => ref.watch(activeJobsProvider).whenData((jobs) => jobs.isEmpty),
  name: 'onboardingNeededProvider',
);

/// Job and wage management.
final jobsControllerProvider = NotifierProvider<JobsController, bool>(
  JobsController.new,
  name: 'jobsControllerProvider',
);

/// Create/update/archive jobs and manage wage history.
class JobsController extends BusyNotifier {
  JobRepository get _jobs => ref.read(jobRepositoryProvider);

  /// Creates a job with its first wage (valid from [validFrom], default
  /// today).
  Future<Job> create({
    required String name,
    required int centsPerHour,
    int colorArgb = kDefaultJobColorArgb,
    RoundingRule rounding = RoundingRule.none,
    LocalDate? validFrom,
  }) => runBusy(
    () => _jobs.createJob(
      name: name,
      centsPerHour: centsPerHour,
      colorArgb: colorArgb,
      rounding: rounding,
      validFrom: validFrom,
    ),
  );

  /// Onboarding step "Dein Job": creates the first job (no rounding) and
  /// marks onboarding as done. [name] is the (localized) name to use; the
  /// UI passes its default ("Mein Job") when the field is empty.
  Future<Job> completeOnboarding({
    required String name,
    required int centsPerHour,
    int colorArgb = kDefaultJobColorArgb,
  }) => runBusy(() async {
    final settings = ref.read(settingsProvider.notifier);
    final job = await _jobs.createJob(
      name: name,
      centsPerHour: centsPerHour,
      colorArgb: colorArgb,
      validFrom: ref.read(clockProvider).today(),
    );
    await settings.setOnboardingDone(true);
    return job;
  });

  /// Saves name, colour, rounding, order and archive flag.
  Future<Job> update(Job job) => runBusy(() async {
    final saved = await _jobs.updateJob(job);
    await _syncIfRunning(saved.id);
    return saved;
  });

  /// Archives or restores a job (at least one must stay active).
  Future<Job> setArchived(int jobId, bool archived) =>
      runBusy(() => _jobs.setArchived(jobId, archived));

  /// Stores the list order.
  Future<void> reorder(List<int> jobIds) =>
      runBusy(() => _jobs.reorder(jobIds));

  /// Adds a wage valid from [validFrom]. With [recalcOpenFromDate], open
  /// shifts from that date are re-priced. Returns the number of re-priced
  /// shifts.
  Future<int> addRate(
    int jobId, {
    required LocalDate validFrom,
    required int centsPerHour,
    bool recalcOpenFromDate = false,
  }) => runBusy(() async {
    final count = await _jobs.addRate(
      jobId,
      validFrom: validFrom,
      centsPerHour: centsPerHour,
      recalcOpenFromDate: recalcOpenFromDate,
    );
    if (count > 0) await _syncIfRunning(jobId);
    return count;
  });

  /// Removes a wage rate (not the last one of a job).
  Future<void> deleteRate(int rateId) =>
      runBusy(() => _jobs.deleteRate(rateId));

  Future<void> _syncIfRunning(int jobId) async {
    final running = await ref.read(shiftRepositoryProvider).getRunning();
    if (running?.jobId == jobId) await notifyShiftSideEffects(ref);
  }
}
