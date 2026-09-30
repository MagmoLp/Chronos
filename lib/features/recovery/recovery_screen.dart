import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/share_service.dart';

/// Shown instead of the app when the start sequence failed (database,
/// settings or v1 migration).
///
/// Nothing is deleted here. The user can try again, share the raw v1 data
/// (the old preference values, exactly as stored) and share the local error
/// log.
class RecoveryScreen extends ConsumerStatefulWidget {
  /// Creates the screen for the start [error].
  const RecoveryScreen({super.key, required this.error, this.stackTrace});

  /// What went wrong.
  final Object error;

  /// Where it went wrong.
  final StackTrace? stackTrace;

  /// File name of the shared raw v1 data.
  static const String rawDataFileName = 'chronos-v1-data.json';

  /// File name of the shared error report.
  static const String errorReportFileName = 'chronos-error-log.txt';

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  bool _sharing = false;

  void _retry() {
    // Re-open everything the start sequence depends on, then run it again.
    ref
      ..invalidate(settingsStoreProvider)
      ..invalidate(databaseProvider)
      ..invalidate(bootstrapProvider);
  }

  Future<void> _shareRawData() => _share((l10n) async {
    final json = await ref.read(legacyMigratorProvider).exportRawJson();
    final share = ref.read(shareServiceProvider);
    final file = await share.saveTextToTemp(
      RecoveryScreen.rawDataFileName,
      json,
    );
    await share.shareFile(
      file.path,
      mimeType: ShareMimeTypes.json,
      subject: l10n.recoveryRawDataSubject,
    );
  });

  Future<void> _shareErrorReport() => _share((l10n) async {
    final log = await ref.read(errorLogProvider).read();
    final report = log.trim().isEmpty
        ? '${widget.error}\n${widget.stackTrace ?? ''}'
        : log;
    final share = ref.read(shareServiceProvider);
    final file = await share.saveTextToTemp(
      RecoveryScreen.errorReportFileName,
      report,
    );
    await share.shareFile(
      file.path,
      mimeType: ShareMimeTypes.text,
      subject: l10n.recoveryErrorReportSubject,
    );
  });

  Future<void> _share(
    Future<void> Function(AppLocalizations l10n) action,
  ) async {
    if (_sharing) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final log = ref.read(errorLogProvider);
    setState(() => _sharing = true);
    try {
      await action(l10n);
    } on Object catch (error, stack) {
      unawaited(log.record(error, stack, context: 'recovery.share'));
      messenger.showSnackBar(SnackBar(content: Text(l10n.recoveryShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String get _details {
    final text = widget.error.toString();
    return text.length > 600 ? '${text.substring(0, 600)}…' : text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.colorScheme;
    final text = context.textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ChronosSpace.s24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ChronosLayout.paneMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(ChronosSpace.s16),
                          child: Icon(
                            Icons.healing_outlined,
                            size: 40,
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: ChronosSpace.s24),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.recoveryTitle,
                      textAlign: TextAlign.center,
                      style: text.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: ChronosSpace.s12),
                  Text(
                    l10n.recoveryMessage,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: ChronosSpace.s32),
                  FilledButton.icon(
                    style: ChronosButtonStyles.primary(context),
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRetry),
                  ),
                  const SizedBox(height: ChronosSpace.s12),
                  OutlinedButton.icon(
                    onPressed: _sharing ? null : _shareRawData,
                    icon: const Icon(Icons.data_object),
                    label: Text(l10n.recoveryShareRawData),
                  ),
                  const SizedBox(height: ChronosSpace.s8),
                  OutlinedButton.icon(
                    onPressed: _sharing ? null : _shareErrorReport,
                    icon: const Icon(Icons.bug_report_outlined),
                    label: Text(l10n.recoveryShareErrorReport),
                  ),
                  const SizedBox(height: ChronosSpace.s16),
                  ExpansionTile(
                    title: Text(l10n.recoveryDetails),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      ChronosSpace.s16,
                      0,
                      ChronosSpace.s16,
                      ChronosSpace.s16,
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SelectableText(
                        _details,
                        style: text.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
