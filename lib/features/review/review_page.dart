import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../data/legacy/legacy_models.dart';
import '../../domain/errors.dart';
import '../../domain/review.dart';
import '../../domain/shift.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/share_service.dart';
import '../../widgets/widgets.dart';
import '../shifts/shift_editor.dart';

/// Opens the list of migrated v1 entries to check.
Future<void> openReviewPage(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ReviewPage()));

/// "Einträge prüfen": migrated shifts that look suspicious (with the reasons)
/// and v1 entries that could not be imported (with their raw data).
///
/// Nothing is changed automatically: each shift can be edited or marked as
/// fine ("Passt so"), or all at once.
class ReviewPage extends ConsumerWidget {
  /// Creates the page.
  const ReviewPage({super.key});

  /// File name of the shared raw v1 data.
  static const String rawDataFileName = 'chronos-v1-data.json';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = combineAsync2(
      ref.watch(reviewItemsProvider),
      ref.watch(legacyFailuresProvider),
      (List<ReviewItem> items, List<LegacyFailure> failures) =>
          (items: items, failures: failures),
    );

    final Widget body;
    if (data.hasError && !data.hasValue) {
      body = EmptyState(icon: Icons.error_outline, title: l10n.errorLoadFailed);
    } else if (!data.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final (:items, :failures) = data.requireValue;
      body = items.isEmpty && failures.isEmpty
          ? EmptyState(
              icon: Icons.task_alt_rounded,
              title: l10n.reviewEmptyTitle,
              message: l10n.reviewEmptyMessage,
            )
          : _ReviewList(items: items, failures: failures);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: body,
    );
  }
}

class _ReviewList extends ConsumerWidget {
  const _ReviewList({required this.items, required this.failures});

  final List<ReviewItem> items;
  final List<LegacyFailure> failures;

  Future<void> _dismissAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.reviewDismissAllTitle(items.length),
      message: l10n.reviewDismissAllMessage,
      confirmLabel: l10n.reviewDismissAll,
      icon: Icons.done_all_rounded,
    );
    if (!confirmed || !context.mounted) return;
    await _runReviewAction(
      context,
      ref,
      () => ref.read(reviewControllerProvider.notifier).dismissAll(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final busy = ref.watch(reviewControllerProvider);

    return ListView(
      padding: EdgeInsets.only(
        bottom: ChronosSpace.s24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: <Widget>[
        ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (items.isNotEmpty) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: ChronosSpace.s8),
                  child: Text(
                    l10n.reviewIntro,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SectionHeader(
                  l10n.reviewSectionShifts(items.length),
                  padding: const EdgeInsets.only(
                    top: ChronosSpace.s24,
                    bottom: ChronosSpace.s8,
                  ),
                ),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: ChronosSpace.s12),
                    child: _ReviewShiftCard(
                      key: ValueKey<int>(item.shiftId),
                      item: item,
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _dismissAll(context, ref),
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(l10n.reviewDismissAll),
                  ),
                ),
              ],
              if (failures.isNotEmpty) _FailureSection(failures: failures),
            ],
          ),
        ),
      ],
    );
  }
}

/// Runs a review action; ignores "busy", shows other failures.
Future<void> _runReviewAction(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final log = ref.read(errorLogProvider);
  try {
    await action();
  } on ChronosException catch (e) {
    if (e.code != ChronosErrorCode.busy) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
    }
  } on Object catch (error, stack) {
    unawaited(log.record(error, stack, context: 'review'));
    messenger.showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
  }
}

/// Localized text of a review [reason].
String reviewReasonText(AppLocalizations l10n, ReviewReason reason) =>
    switch (reason) {
      ReviewReason.tooLong16h => l10n.reviewReasonTooLong,
      ReviewReason.exactly23or24h => l10n.reviewReasonExactly23or24h,
      ReviewReason.duplicateTimes => l10n.reviewReasonDuplicateTimes,
      ReviewReason.duplicateLegacyId => l10n.reviewReasonDuplicateLegacyId,
      ReviewReason.overlap => l10n.reviewReasonOverlap,
      ReviewReason.dstDay => l10n.reviewReasonDstDay,
    };

/// Localized reason why a v1 entry could not be imported.
String legacyFailureText(AppLocalizations l10n, LegacyErrorCode code) =>
    switch (code) {
      LegacyErrorCode.invalidJson => l10n.reviewFailureInvalidJson,
      LegacyErrorCode.notAList => l10n.reviewFailureNotAList,
      LegacyErrorCode.notAnObject => l10n.reviewFailureNotAnObject,
      LegacyErrorCode.missingStartTime => l10n.reviewFailureMissingStart,
      LegacyErrorCode.invalidStartTime => l10n.reviewFailureInvalidStart,
      LegacyErrorCode.missingEndTime => l10n.reviewFailureMissingEnd,
      LegacyErrorCode.invalidEndTime => l10n.reviewFailureInvalidEnd,
      LegacyErrorCode.endNotAfterStart => l10n.reviewFailureEndNotAfterStart,
      LegacyErrorCode.invalidActiveSession =>
        l10n.reviewFailureInvalidActiveSession,
      LegacyErrorCode.runningShiftExists =>
        l10n.reviewFailureRunningShiftExists,
      LegacyErrorCode.invalidSettings => l10n.reviewFailureInvalidSettings,
      LegacyErrorCode.insertFailed => l10n.reviewFailureInsertFailed,
    };

/// One suspicious shift: summary, reasons, "Bearbeiten" and "Passt so".
class _ReviewShiftCard extends ConsumerWidget {
  const _ReviewShiftCard({super.key, required this.item});

  final ReviewItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.colorScheme;
    final colors = context.chronosColors;
    final text = context.textTheme;
    final busy = ref.watch(reviewControllerProvider);
    final shiftValue = ref.watch(shiftByIdProvider(item.shiftId));
    final shift = shiftValue.value;
    final missing = shiftValue.hasValue && (shift == null || shift.isDeleted);

    Widget header;
    if (shift != null && !shift.isDeleted) {
      header = _ShiftSummary(shift: shift);
    } else if (missing) {
      header = Text(
        l10n.reviewShiftDeleted,
        style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    } else {
      header = const SizedBox(height: DateBlock.size);
    }

    final reasons = <ReviewReason>[
      for (final reason in ReviewReason.values)
        if (item.reasons.contains(reason)) reason,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ChronosSpace.s16,
          ChronosSpace.s16,
          ChronosSpace.s16,
          ChronosSpace.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            header,
            if (!missing) ...<Widget>[
              const SizedBox(height: ChronosSpace.s12),
              for (final reason in reasons)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ExcludeSemantics(
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: colors.warning,
                        ),
                      ),
                      const SizedBox(width: ChronosSpace.s8),
                      Expanded(
                        child: Text(
                          reviewReasonText(l10n, reason),
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: ChronosSpace.s4),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: ChronosSpace.s8,
              children: <Widget>[
                if (!missing)
                  TextButton.icon(
                    onPressed: shift == null
                        ? null
                        : () => showShiftEditor(context, shiftId: shift.id),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.commonEdit),
                  ),
                FilledButton.tonal(
                  onPressed: busy
                      ? null
                      : () => _runReviewAction(
                          context,
                          ref,
                          () => ref
                              .read(reviewControllerProvider.notifier)
                              .dismiss(item.shiftId),
                        ),
                  child: Text(l10n.reviewDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Date block, "08:00–16:15 · 8:15 h" and the amount.
class _ShiftSummary extends StatelessWidget {
  const _ShiftSummary({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final start = shift.startUtc.toLocal();
    final end = shift.endUtc?.toLocal();
    final times = end == null ? fmt.time(start) : fmt.timeRange(start, end);
    return Row(
      children: <Widget>[
        DateBlock(date: start),
        const SizedBox(width: ChronosSpace.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.reviewShiftSummary(times, fmt.durationHm(shift.workedMs)),
                style: text.titleMedium?.copyWith(color: scheme.onSurface),
              ),
              Text(
                fmt.money(shift.earnedCents),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// v1 entries that could not be imported, with their raw data.
class _FailureSection extends ConsumerStatefulWidget {
  const _FailureSection({required this.failures});

  final List<LegacyFailure> failures;

  @override
  ConsumerState<_FailureSection> createState() => _FailureSectionState();
}

class _FailureSectionState extends ConsumerState<_FailureSection> {
  static const int _snippetLength = 280;
  bool _sharing = false;

  Future<void> _shareRawData() async {
    if (_sharing) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final log = ref.read(errorLogProvider);
    setState(() => _sharing = true);
    try {
      final json = await ref.read(legacyMigratorProvider).exportRawJson();
      final share = ref.read(shareServiceProvider);
      final file = await share.saveTextToTemp(ReviewPage.rawDataFileName, json);
      await share.shareFile(
        file.path,
        mimeType: ShareMimeTypes.json,
        subject: l10n.recoveryRawDataSubject,
      );
    } on Object catch (error, stack) {
      unawaited(log.record(error, stack, context: 'review.shareRawData'));
      messenger.showSnackBar(SnackBar(content: Text(l10n.recoveryShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _snippet(String raw) => raw.length > _snippetLength
      ? '${raw.substring(0, _snippetLength)}…'
      : raw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.colorScheme;
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          l10n.reviewSectionFailures(widget.failures.length),
          padding: const EdgeInsets.only(
            top: ChronosSpace.s24,
            bottom: ChronosSpace.s8,
          ),
        ),
        Text(
          l10n.reviewFailuresIntro,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: ChronosSpace.s8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: _sharing ? null : _shareRawData,
            icon: const Icon(Icons.share_outlined),
            label: Text(l10n.recoveryShareRawData),
          ),
        ),
        const SizedBox(height: ChronosSpace.s12),
        for (final failure in widget.failures)
          Padding(
            padding: const EdgeInsets.only(bottom: ChronosSpace.s12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(ChronosSpace.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      legacyFailureText(l10n, failure.code),
                      style: text.titleSmall?.copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      failure.origin,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: ChronosSpace.s8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: ChronosCorners.small,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(ChronosSpace.s8),
                        child: Text(
                          _snippet(failure.raw),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
