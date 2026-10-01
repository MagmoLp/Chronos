import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';

/// App-level lifecycle hooks (placed above the navigator).
///
/// * At start (after the first frame): removes the temporary share files of
///   the previous session.
/// * On resume: re-reads today's date (day change while in the background)
///   and reconciles the notification and reminder with the database – once
///   the start sequence has finished.
/// * While the app is visible: one single-shot timer to the next local
///   midnight so "Heute" switches days when the screen stays on overnight.
///   It is cancelled as soon as the app is hidden (nothing runs in the
///   background).
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
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: _onResume,
      onShow: _scheduleMidnight,
      onHide: _cancelMidnight,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_clearTemp());
    });
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      _scheduleMidnight();
    }
  }

  @override
  void dispose() {
    _cancelMidnight();
    _listener.dispose();
    super.dispose();
  }

  /// Arms a single timer for shortly after the next local midnight.
  void _scheduleMidnight() {
    _cancelMidnight();
    final now = ref.read(clockProvider).now();
    final local = now.toLocal();
    final nextDay = DateTime(local.year, local.month, local.day + 1);
    final wait = nextDay.difference(local) + const Duration(seconds: 1);
    _midnight = Timer(wait, () {
      if (!mounted) return;
      ref.read(currentDateProvider.notifier).refresh();
      _scheduleMidnight();
    });
  }

  void _cancelMidnight() {
    _midnight?.cancel();
    _midnight = null;
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
