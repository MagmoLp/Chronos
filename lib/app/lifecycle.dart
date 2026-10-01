import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';

/// App-level lifecycle hooks (placed above the navigator). No timers.
///
/// * At start (after the first frame): removes the temporary share files of
///   the previous session.
/// * On resume: re-reads today's date (day change while in the background)
///   and reconciles the notification and reminder with the database – once
///   the start sequence has finished.
class AppLifecycleScope extends ConsumerStatefulWidget {
  /// Wraps [child].
  const AppLifecycleScope({super.key, required this.child});

  /// The app below.
  final Widget child;

  @override
  ConsumerState<AppLifecycleScope> createState() => _AppLifecycleScopeState();
}

class _AppLifecycleScopeState extends ConsumerState<AppLifecycleScope> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _onResume);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_clearTemp());
    });
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _onResume() {
    ref.read(currentDateProvider.notifier).refresh();
    if (ref.read(bootstrapProvider).hasValue) {
      unawaited(ref.read(activeShiftControllerProvider.notifier).reconcile());
    }
  }

  Future<void> _clearTemp() async {
    final log = ref.read(errorLogProvider);
    try {
      await ref.read(shareServiceProvider).clearTemp();
    } on Object catch (error, stack) {
      unawaited(log.record(error, stack, context: 'clearTemp'));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
