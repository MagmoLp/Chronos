import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../domain/errors.dart';
import '../../domain/review.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/money_field.dart';
import '../providers/providers.dart';
import '../theme/theme.dart';

/// Asks once after the v1 migration whether an implausible wage is right
/// ("1.250,00 €/h übernommen – stimmt das?").
///
/// The field is prefilled with the likely intended wage (12,50 € for
/// 1250 €/h). Correcting updates the job's wage and every migrated shift
/// ([ReviewController.fixWage]); keeping confirms it
/// ([ReviewController.confirmWage]). Either way the app continues.
class WageCheckPage extends ConsumerStatefulWidget {
  /// Creates the page for [check].
  const WageCheckPage({super.key, required this.check});

  /// The implausible migrated wage.
  final WagePlausibility check;

  @override
  ConsumerState<WageCheckPage> createState() => _WageCheckPageState();
}

class _WageCheckPageState extends ConsumerState<WageCheckPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late int? _cents = widget.check.suggestedCentsPerHour;
  bool _saving = false;

  Future<void> _fix() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final cents = _cents;
    if (cents == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _run(() async {
      final count = await ref
          .read(reviewControllerProvider.notifier)
          .fixWage(cents);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.wageCheckFixed(count))),
      );
    });
  }

  Future<void> _keep() =>
      _run(() => ref.read(reviewControllerProvider.notifier).confirmWage());

  Future<void> _run(Future<void> Function() action) async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final log = ref.read(errorLogProvider);
    setState(() => _saving = true);
    var done = false;
    try {
      await action();
      // The start gate moves on; stay locked until then.
      done = true;
    } on ChronosException catch (e) {
      if (e.code != ChronosErrorCode.busy) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              e.code == ChronosErrorCode.invalidAmount
                  ? l10n.errorAmountNotPositive
                  : l10n.errorSaveFailed,
            ),
          ),
        );
      }
    } on Object catch (error, stack) {
      unawaited(log.record(error, stack, context: 'wageCheck'));
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
    } finally {
      if (mounted && !done) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = context.colorScheme;
    final colors = context.chronosColors;
    final text = context.textTheme;
    final rate = fmt.rate(widget.check.centsPerHour);
    final explanation = widget.check.issue == WageIssue.tooLow
        ? l10n.wageCheckTooLow
        : l10n.wageCheckTooHigh;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ChronosSpace.s24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ChronosLayout.paneMaxWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.warningContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(ChronosSpace.s16),
                            child: Icon(
                              Icons.euro_rounded,
                              size: 40,
                              color: colors.onWarningContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: ChronosSpace.s24),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.wageCheckTitle(rate),
                        textAlign: TextAlign.center,
                        style: text.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: ChronosSpace.s12),
                    Text(
                      explanation,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: ChronosSpace.s32),
                    MoneyField(
                      value: _cents,
                      onChanged: (cents) => _cents = cents,
                      label: l10n.wageCheckFieldLabel,
                      helperText: l10n.wageCheckFieldHelper,
                      required: true,
                      allowZero: false,
                      enabled: !_saving,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _fix(),
                    ),
                    const SizedBox(height: ChronosSpace.s24),
                    FilledButton(
                      style: ChronosButtonStyles.primary(context),
                      onPressed: _saving ? null : _fix,
                      child: Text(l10n.wageCheckFix),
                    ),
                    const SizedBox(height: ChronosSpace.s8),
                    TextButton(
                      onPressed: _saving ? null : _keep,
                      child: Text(
                        l10n.wageCheckKeep(rate),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
