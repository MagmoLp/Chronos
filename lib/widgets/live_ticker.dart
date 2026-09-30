import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

/// Builds the live part of the UI for the wall-clock instant [now].
typedef LiveTickerBuilder = Widget Function(BuildContext context, DateTime now);

/// Returns the next instant at which a [LiveTicker] should rebuild, given the
/// current time, or `null` if no further rebuild is needed.
typedef NextTickScheduler = DateTime? Function(DateTime now);

/// Rebuilds [builder] with the current time, but only while it can be seen.
///
/// By default it ticks at every full wall-clock second (so a stopwatch text
/// changes exactly on the second). A [nextTick] scheduler can pick other
/// instants, e.g. the millisecond at which the next cent is earned; those
/// ticks are at least [minInterval] apart.
///
/// It never runs a timer while
/// * the app is hidden, paused or detached ([AppLifecycleListener]),
/// * tickers are disabled for this subtree ([TickerMode], e.g. an inactive
///   tab or a route covered by another), or
/// * the subtree is hidden by [Visibility] / [IndexedStack].
///
/// When it becomes visible again it rebuilds immediately with the fresh time,
/// so no work is ever done in the background (CLAUDE.md, "Nichts im
/// Hintergrund"). Time comes from `package:clock`, so tests can control it.
class LiveTicker extends StatefulWidget {
  /// Creates a live ticker.
  const LiveTicker({
    super.key,
    required this.builder,
    this.nextTick,
    this.minInterval = const Duration(milliseconds: 250),
    this.enabled = true,
  });

  /// Called on every tick (and on ordinary rebuilds) with `clock.now()`.
  final LiveTickerBuilder builder;

  /// Custom schedule; defaults to [nextFullSecond].
  final NextTickScheduler? nextTick;

  /// Lower bound between two ticks of a custom [nextTick] schedule
  /// (4 updates per second at most).
  final Duration minInterval;

  /// When false the builder runs once per rebuild and no timer is started
  /// (e.g. while a shift is paused).
  final bool enabled;

  /// The next full wall-clock second strictly after [now].
  static DateTime nextFullSecond(DateTime now) {
    final ms = now.millisecondsSinceEpoch;
    return DateTime.fromMillisecondsSinceEpoch(
      (ms ~/ 1000 + 1) * 1000,
      isUtc: now.isUtc,
    );
  }

  @override
  State<LiveTicker> createState() => _LiveTickerState();
}

class _LiveTickerState extends State<LiveTicker> {
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;
  bool _appVisible = true;
  bool _subtreeActive = true;

  bool get _active => widget.enabled && _appVisible && _subtreeActive;

  static bool _isVisible(AppLifecycleState? state) =>
      state == null ||
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;

  @override
  void initState() {
    super.initState();
    _appVisible = _isVisible(WidgetsBinding.instance.lifecycleState);
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subtreeActive =
        TickerMode.valuesOf(context).enabled && Visibility.of(context);
    _schedule();
  }

  @override
  void didUpdateWidget(LiveTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.nextTick != widget.nextTick ||
        oldWidget.minInterval != widget.minInterval) {
      _schedule();
    }
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    final visible = _isVisible(state);
    if (visible == _appVisible) return;
    _appVisible = visible;
    if (visible) {
      // Refresh right away; the time may have moved on a lot.
      setState(() {});
    }
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_active) return;
    final now = clock.now();
    final custom = widget.nextTick;
    final Duration delay;
    if (custom == null) {
      delay = LiveTicker.nextFullSecond(now).difference(now);
    } else {
      final next = custom(now);
      if (next == null) return;
      final wanted = next.difference(now);
      delay = wanted < widget.minInterval ? widget.minInterval : wanted;
    }
    _timer = Timer(delay, _onTick);
  }

  void _onTick() {
    _timer = null;
    if (!mounted) return;
    setState(() {});
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, clock.now());
}
