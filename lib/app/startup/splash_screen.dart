import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../theme/theme.dart';
import 'app_mark.dart';

/// Shown while the database opens and the v1 migration runs.
///
/// Same background as the Android splash (`surface`: #F6F9FC / #0B1320), so
/// the hand-over from the native splash is seamless. A thin progress bar
/// appears only if the start takes noticeably long.
class SplashScreen extends StatelessWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  /// How long the start may take before the progress bar appears.
  static const Duration progressDelay = Duration(milliseconds: 600);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ChronosTheme.overlayStyleFor(theme.brightness),
      child: Material(
        color: theme.colorScheme.surface,
        child: Semantics(
          label: AppLocalizations.of(context).startupLoading,
          container: true,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppMark(),
                SizedBox(height: ChronosSpace.s32),
                _DelayedProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A thin indeterminate bar that only shows after [SplashScreen.progressDelay]
/// (a quick start shows no spinner at all).
class _DelayedProgress extends StatefulWidget {
  const _DelayedProgress();

  @override
  State<_DelayedProgress> createState() => _DelayedProgressState();
}

class _DelayedProgressState extends State<_DelayedProgress> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.progressDelay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 4,
      child: _visible
          ? ExcludeSemantics(
              child: LinearProgressIndicator(
                borderRadius: ChronosCorners.extraSmall,
                backgroundColor: context.colorScheme.surfaceContainerHighest,
              ),
            )
          : null,
    );
  }
}
