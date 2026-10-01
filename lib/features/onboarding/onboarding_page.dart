import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/startup/app_mark.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../domain/errors.dart';
import '../../domain/review.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/money_field.dart';

/// First start without data: two short steps.
///
/// 1. Welcome – what Chronos does.
/// 2. "Dein Job" – optional name (default "Mein Job") and the required
///    hourly rate (comma or dot). "Fertig" creates the job via
///    [JobsController.completeOnboarding]; the start gate then shows the app.
///
/// Language and theme follow the system; everything else can be changed
/// later in the settings.
class OnboardingPage extends ConsumerStatefulWidget {
  /// Creates the onboarding.
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const int _steps = 2;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final FocusNode _rateFocus = FocusNode();
  int _step = 0;
  int? _cents;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _rateFocus.dispose();
    super.dispose();
  }

  void _goTo(int step) => setState(() => _step = step);

  Future<void> _finish() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final cents = _cents;
    if (cents == null) return;
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final log = ref.read(errorLogProvider);

    final check = checkWagePlausibility(cents);
    if (!check.isPlausible) {
      final keep = await showConfirmDialog(
        context,
        title: l10n.wageCheckConfirmTitle(fmt.rate(cents)),
        message: check.issue == WageIssue.tooLow
            ? l10n.wageCheckTooLow
            : l10n.wageCheckUnusuallyHigh,
        confirmLabel: l10n.wageCheckConfirmYes,
        cancelLabel: l10n.wageCheckConfirmEdit,
        icon: Icons.euro_rounded,
      );
      if (!mounted) return;
      if (!keep) {
        _rateFocus.requestFocus();
        return;
      }
    }

    final name = _name.text.trim();
    setState(() => _saving = true);
    var created = false;
    try {
      await ref
          .read(jobsControllerProvider.notifier)
          .completeOnboarding(
            name: name.isEmpty ? l10n.onboardingDefaultJobName : name,
            centsPerHour: cents,
          );
      // The start gate switches to the app as soon as the job exists; until
      // then the form stays locked (no second job from a double tap).
      created = true;
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
      unawaited(log.record(error, stack, context: 'onboarding'));
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
    } finally {
      if (mounted && !created) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final compactHeight = size.height < ChronosLayout.compactHeight;
    final wide = size.width >= ChronosLayout.compactWidth && !compactHeight;
    final background = wide ? scheme.surfaceContainerLow : scheme.surface;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget step = _step == 0
        ? _WelcomeStep(
            key: const ValueKey<int>(0),
            sideBySide: compactHeight,
            onNext: () => _goTo(1),
          )
        : _JobStep(
            key: const ValueKey<int>(1),
            formKey: _formKey,
            name: _name,
            rateFocus: _rateFocus,
            cents: _cents,
            saving: _saving,
            onCentsChanged: (cents) => _cents = cents,
            onDone: _finish,
          );

    final content = AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : ChronosMotion.long,
      switchInCurve: ChronosMotion.enter,
      switchOutCurve: ChronosMotion.exit,
      transitionBuilder: (child, animation) {
        // Shared axis: the job step lives to the right of the welcome step.
        final isJobStep = (child.key as ValueKey<int>?)?.value == 1;
        final offset = Tween<Offset>(
          begin: Offset(isJobStep ? 0.08 : -0.08, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...previous, ?current],
      ),
      child: step,
    );

    return PopScope<Object?>(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: _step == 0
            ? null
            : AppBar(
                backgroundColor: background,
                leading: BackButton(onPressed: () => _goTo(0)),
              ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ChronosLayout.marginFor(constraints.maxWidth),
                vertical: ChronosSpace.s24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 2 * ChronosSpace.s24)
                      .clamp(0, double.infinity),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compactHeight
                          ? ChronosLayout.contentMaxWidth
                          : ChronosLayout.paneMaxWidth,
                    ),
                    child: wide
                        ? Card(
                            color: scheme.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(ChronosSpace.s32),
                              child: content,
                            ),
                          )
                        : content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 1: mark, promise, "Los geht's".
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    super.key,
    required this.sideBySide,
    required this.onNext,
  });

  /// Mark on the left, text on the right (phone landscape).
  final bool sideBySide;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final align = sideBySide ? TextAlign.start : TextAlign.center;

    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: sideBySide
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            l10n.onboardingWelcomeTitle,
            textAlign: align,
            style: text.headlineMedium?.copyWith(color: scheme.onSurface),
          ),
        ),
        const SizedBox(height: ChronosSpace.s12),
        Text(
          l10n.onboardingWelcomeBody,
          textAlign: align,
          style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: ChronosSpace.s32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: ChronosButtonStyles.hero(context),
            onPressed: onNext,
            child: Text(l10n.onboardingStart),
          ),
        ),
        const SizedBox(height: ChronosSpace.s24),
        const _StepDots(step: 0, total: _OnboardingPageState._steps),
      ],
    );

    if (sideBySide) {
      return Row(
        children: <Widget>[
          const AppMark(size: 120),
          const SizedBox(width: ChronosSpace.s32),
          Expanded(child: copy),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppMark(),
        const SizedBox(height: ChronosSpace.s32),
        copy,
      ],
    );
  }
}

/// Step 2: name (optional) and hourly rate (required).
class _JobStep extends StatelessWidget {
  const _JobStep({
    super.key,
    required this.formKey,
    required this.name,
    required this.rateFocus,
    required this.cents,
    required this.saving,
    required this.onCentsChanged,
    required this.onDone,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final FocusNode rateFocus;
  final int? cents;
  final bool saving;
  final ValueChanged<int?> onCentsChanged;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.colorScheme;
    final text = context.textTheme;
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              l10n.onboardingJobTitle,
              style: text.headlineMedium?.copyWith(color: scheme.onSurface),
            ),
          ),
          const SizedBox(height: ChronosSpace.s8),
          Text(
            l10n.onboardingJobSubtitle,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: ChronosSpace.s24),
          TextField(
            controller: name,
            enabled: !saving,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => rateFocus.requestFocus(),
            decoration: InputDecoration(
              labelText: l10n.onboardingNameLabel,
              hintText: l10n.onboardingDefaultJobName,
            ),
          ),
          const SizedBox(height: ChronosSpace.s16),
          MoneyField(
            value: cents,
            focusNode: rateFocus,
            onChanged: onCentsChanged,
            label: l10n.onboardingRateLabel,
            helperText: l10n.onboardingRateHelper,
            required: true,
            allowZero: false,
            enabled: !saving,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onDone(),
          ),
          const SizedBox(height: ChronosSpace.s24),
          FilledButton(
            style: ChronosButtonStyles.primary(context),
            onPressed: saving ? null : onDone,
            child: Text(l10n.commonDone),
          ),
          const SizedBox(height: ChronosSpace.s12),
          Text(
            l10n.onboardingMoreJobsLater,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: ChronosSpace.s24),
          const _StepDots(step: 1, total: _OnboardingPageState._steps),
        ],
      ),
    );
  }
}

/// Page dots; announced as "Schritt 1 von 2".
class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      label: AppLocalizations.of(context).onboardingStepLabel(step + 1, total),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < total; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ChronosSpace.s4),
              child: SizedBox(
                width: i == step ? 24 : 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i == step ? scheme.primary : scheme.outlineVariant,
                    borderRadius: ChronosCorners.extraSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
