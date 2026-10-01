import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/job.dart';
import '../../domain/shift.dart';
import '../../l10n/app_localizations.dart';
import 'today_state.dart';

/// The action area of Today.
///
/// Idle: job chip (only with more than one active job), the big "Schicht
/// starten" button and "Früher angefangen?". Running: "Pause"/"Fortsetzen"
/// (tonal) and "Beenden" (primary). Buttons are disabled while a timer
/// action is being written.
class TodayActions extends ConsumerWidget {
  /// Creates the actions.
  const TodayActions({
    super.key,
    required this.onStart,
    required this.onStartEarlier,
    required this.onPauseResume,
    required this.onFinish,
    this.dense = false,
  });

  /// "Schicht starten".
  final VoidCallback onStart;

  /// "Früher angefangen?".
  final VoidCallback onStartEarlier;

  /// "Pause" / "Fortsetzen".
  final VoidCallback onPauseResume;

  /// "Beenden" (opens the finish sheet).
  final VoidCallback onFinish;

  /// Compact height: "Früher angefangen?" becomes an icon button next to
  /// the start button, so everything fits without scrolling.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(runningShiftProvider);
    final busy = ref.watch(activeShiftControllerProvider);
    if (!running.hasValue) return const SizedBox.shrink();
    final shift = running.value;
    if (shift != null) {
      return _RunningActions(
        shift: shift,
        busy: busy,
        onPauseResume: onPauseResume,
        onFinish: onFinish,
      );
    }
    return _IdleActions(
      busy: busy,
      dense: dense,
      onStart: onStart,
      onStartEarlier: onStartEarlier,
    );
  }
}

class _IdleActions extends ConsumerWidget {
  const _IdleActions({
    required this.busy,
    required this.dense,
    required this.onStart,
    required this.onStartEarlier,
  });

  final bool busy;
  final bool dense;
  final VoidCallback onStart;
  final VoidCallback onStartEarlier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final jobs = ref.watch(activeJobsProvider).value ?? const <Job>[];
    final job = ref.watch(todayStartJobProvider).value;
    final canStart = !busy && job != null;

    final start = FilledButton.icon(
      onPressed: canStart ? onStart : null,
      // Compact height: the 56 dp primary size keeps both columns on screen.
      style: dense
          ? ChronosButtonStyles.primary(context)
          : ChronosButtonStyles.hero(context),
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(l10n.todayStartShift, textAlign: TextAlign.center),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (jobs.length > 1 && job != null) ...<Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TodayJobChip(jobs: jobs, selected: job),
          ),
          const SizedBox(height: ChronosSpace.s8),
        ],
        if (dense)
          Row(
            children: <Widget>[
              Expanded(child: start),
              const SizedBox(width: ChronosSpace.s8),
              IconButton.filledTonal(
                onPressed: canStart ? onStartEarlier : null,
                tooltip: l10n.todayStartedEarlier,
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(
                    ChronosLayout.primaryButtonHeight,
                  ),
                ),
                icon: const Icon(Icons.history),
              ),
            ],
          )
        else ...<Widget>[
          start,
          const SizedBox(height: ChronosSpace.s4),
          Center(
            child: TextButton.icon(
              onPressed: canStart ? onStartEarlier : null,
              icon: const Icon(Icons.history),
              label: Text(l10n.todayStartedEarlier),
            ),
          ),
        ],
      ],
    );
  }
}

class _RunningActions extends StatelessWidget {
  const _RunningActions({
    required this.shift,
    required this.busy,
    required this.onPauseResume,
    required this.onFinish,
  });

  final Shift shift;
  final bool busy;
  final VoidCallback onPauseResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = ChronosButtonStyles.primary(context);
    final pause = FilledButton.tonalIcon(
      onPressed: busy ? null : onPauseResume,
      style: primary,
      icon: Icon(
        shift.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
      ),
      label: Text(shift.isPaused ? l10n.todayResume : l10n.todayPause),
    );
    final finish = FilledButton.icon(
      onPressed: busy ? null : onFinish,
      style: primary.merge(
        FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: ChronosCorners.large,
          ),
        ),
      ),
      icon: const Icon(Icons.stop_rounded),
      label: Text(l10n.todayFinish),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final sideBySide = constraints.maxWidth / scale >= 280;
        if (sideBySide) {
          return Row(
            children: <Widget>[
              Expanded(child: pause),
              const SizedBox(width: ChronosSpace.s12),
              Expanded(child: finish),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            finish,
            const SizedBox(height: ChronosSpace.s12),
            pause,
          ],
        );
      },
    );
  }
}

/// Chip with the job the next shift starts for; opens a menu of the active
/// jobs. The choice is remembered for the session.
class TodayJobChip extends ConsumerWidget {
  /// Creates the chip.
  const TodayJobChip({super.key, required this.jobs, required this.selected});

  /// Active jobs.
  final List<Job> jobs;

  /// The job currently used for starting.
  final Job selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MenuAnchor(
      menuChildren: <Widget>[
        for (final job in jobs)
          MenuItemButton(
            leadingIcon: _JobDot(color: jobColorOf(context, job)),
            trailingIcon: job.id == selected.id
                ? const Icon(Icons.check)
                : null,
            onPressed: () =>
                ref.read(todaySelectedJobIdProvider.notifier).select(job.id),
            child: Text(job.name),
          ),
      ],
      builder: (context, controller, _) => Semantics(
        label: l10n.todayJobSemantics(selected.name),
        excludeSemantics: true,
        button: true,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: ActionChip(
          avatar: _JobDot(color: jobColorOf(context, selected)),
          tooltip: l10n.todayChooseJob,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  selected.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

class _JobDot extends StatelessWidget {
  const _JobDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.circle, size: 14, color: color);
}
