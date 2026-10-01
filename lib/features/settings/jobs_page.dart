import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../domain/errors.dart';
import '../../domain/job.dart';
import '../../domain/wage_rate.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import 'error_text.dart';
import 'job_editor_page.dart';
import 'widgets/job_color.dart';
import 'widgets/settings_group.dart';

/// The wage that applies on [date] from a job's history (any order):
/// the latest rate starting on or before [date], else the earliest one.
WageRate? currentRate(List<WageRate> rates, LocalDate date) {
  WageRate? best;
  WageRate? earliest;
  for (final rate in rates) {
    if (earliest == null || rate.validFrom.isBefore(earliest.validFrom)) {
      earliest = rate;
    }
    if (rate.validFrom.isOnOrBefore(date) &&
        (best == null || rate.validFrom.isAfter(best.validFrom))) {
      best = rate;
    }
  }
  return best ?? earliest;
}

/// "Jobs & Stundenlohn": active and archived jobs with their current wage.
class JobsPage extends ConsumerWidget {
  /// Creates the page.
  const JobsPage({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, Job? job) async {
    final l10n = AppLocalizations.of(context);
    final result = await Navigator.of(context).push<JobEditorResult>(
      MaterialPageRoute(builder: (_) => JobEditorPage(job: job)),
    );
    if (result == null || !context.mounted) return;
    if (result.archivedChanged) {
      final jobs = ref.read(jobsControllerProvider.notifier);
      final archived = result.job.archived;
      final messenger = ScaffoldMessenger.of(context);
      showUndoSnackBar(
        context,
        message: archived
            ? l10n.jobsArchived(result.job.name)
            : l10n.jobsUnarchived(result.job.name),
        onUndo: () async {
          try {
            await jobs.setArchived(result.job.id, !archived);
          } on ChronosException catch (e) {
            if (e.code == ChronosErrorCode.busy) return;
            messenger.showSnackBar(
              SnackBar(content: Text(chronosErrorText(l10n, e.code))),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final jobsValue = ref.watch(jobsProvider);
    final jobs = jobsValue.value;
    final active = [
      for (final j in jobs ?? const <Job>[])
        if (!j.archived) j,
    ];
    final archived = [
      for (final j in jobs ?? const <Job>[])
        if (j.archived) j,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsJobs)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.jobsAdd),
      ),
      body: jobs == null
          ? Center(
              child: jobsValue.hasError
                  ? Text(l10n.errorLoadFailed)
                  : const CircularProgressIndicator(),
            )
          : SettingsListView(
              bottomPadding: 96,
              children: [
                if (active.isEmpty && archived.isEmpty)
                  EmptyState(
                    icon: Icons.work_outline,
                    title: l10n.settingsJobsCount(0),
                  ),
                if (active.isNotEmpty)
                  SettingsGroup(
                    title: archived.isEmpty ? null : l10n.jobsActiveSection,
                    children: [
                      for (final job in active)
                        JobTile(job: job, onTap: () => _open(context, ref, job)),
                    ],
                  ),
                if (archived.isNotEmpty)
                  SettingsGroup(
                    title: l10n.jobsArchivedSection,
                    children: [
                      for (final job in archived)
                        JobTile(job: job, onTap: () => _open(context, ref, job)),
                    ],
                  ),
              ],
            ),
    );
  }
}

/// A job row: colour dot, name and "15,00 €/h seit 01.01.2026".
class JobTile extends ConsumerWidget {
  /// Creates the row.
  const JobTile({super.key, required this.job, required this.onTap});

  /// The job.
  final Job job;

  /// Opens the editor.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final today = ref.watch(currentDateProvider);
    final rates = ref.watch(jobRatesProvider(job.id)).value;
    final rate = rates == null ? null : currentRate(rates, today);
    return ListTile(
      onTap: onTap,
      leading: SizedBox.square(
        dimension: 40,
        child: Center(child: JobColorDot(colorArgb: job.colorArgb, size: 16)),
      ),
      title: Text(job.name),
      subtitle: rate == null
          ? null
          : Text(
              l10n.jobsRateSince(
                fmt.rate(rate.centsPerHour),
                fmt.dateNumeric(rate.validFrom.toLocalDateTime()),
              ),
              style: context.chronosText.bodyNumbers.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
