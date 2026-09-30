// Item 4b: REAL-TIME measurements.
//
// The app reads DateTime.now() directly (not package:clock), which flutter_test
// does not fake. So this test keeps the fake clock in lock-step with the real
// clock: every ~16 ms of REAL time it advances the fake clock by the same
// amount, and - like the engine's vsync would - renders a frame ONLY if the
// framework actually requested one (binding.hasScheduledFrame). Timers,
// tickers, notification cadence and money digits therefore behave as on a
// device, and frames/s counts only frames the app really asked for.
//
// (LiveTestWidgetsFlutterBinding is NOT usable for this: its handleDrawFrame
// re-schedules a frame after every frame, so it reports ~60 fps even when idle
// or when framesEnabled == false.)
//
// Takes ~80 s. Run alone:  flutter test test/perf_live_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

// ignore: avoid_print
void obs(String s) => print('OBS: $s');

Map<String, int> collectBuilds() {
  final m = <String, int>{};
  for (final b in FlutterTimeline.debugCollect().aggregatedBlocks) {
    m[b.name] = b.count;
  }
  return m;
}

String summarize(Map<String, int> m, double seconds) {
  const skip = {'BUILD', 'LAYOUT', 'PAINT', 'COMPOSITING', 'SEMANTICS', 'FINALIZE TREE', 'UPDATING COMPOSITING BITS', 'Animate', 'POST_FRAME'};
  final e = m.entries.where((e) => !skip.contains(e.key)).toList()..sort((a, b) => b.value.compareTo(a.value));
  final total = e.fold<int>(0, (a, b) => a + b.value);
  String rate(String k) => ((m[k] ?? 0) / seconds).toStringAsFixed(2);
  return 'widget builds/s=${(total / seconds).toStringAsFixed(1)} (HomeScreen/s=${rate('HomeScreen')}, '
      'AnimatedDigit/s=${rate('AnimatedDigit')}, AnimatedSwitcher/s=${rate('AnimatedSwitcher')}, '
      'Text/s=${rate('Text')})';
}

void main() {

  testWidgets('live: foreground vs paused', (tester) async {
    final binding = tester.binding;
    await loadRealFonts();
    installNotificationStub();
    setScreen(tester, const Size(800, 1280));
    var notifies = 0;
    var frames = 0;
    SchedulerBinding.instance.addPersistentFrameCallback((_) => frames++);

    Future<String> window(String name, Duration d, {required AppHarness h}) async {
      notifies = 0;
      frames = 0;
      final shows0 = countNotif('show');
      FlutterTimeline.debugReset();
      final sw = Stopwatch()..start();
      var maxTransient = 0;
      var iterations = 0;
      var requested = 0;
      var last = DateTime.now();
      final end = last.add(d);
      while (DateTime.now().isBefore(end)) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 16)));
        final now = DateTime.now();
        final dt = now.difference(last);
        last = now;
        iterations++;
        if (binding.hasScheduledFrame) {
          requested++;
          await tester.pump(dt); // advances fake clock by dt, then renders the requested frame
        } else {
          await binding.delayed(dt); // advances fake clock (fires timers), no frame
        }
        final tc = SchedulerBinding.instance.transientCallbackCount;
        if (tc > maxTransient) maxTransient = tc;
      }
      final secs = sw.elapsedMilliseconds / 1000;
      final shows = countNotif('show') - shows0;
      final r = '$name (${secs.toStringAsFixed(1)} s real): frames/s=${(frames / secs).toStringAsFixed(2)}, '
          'notifyListeners/s=${(notifies / secs).toStringAsFixed(2)}, notification show() calls=$shows '
          '(= ${(shows / secs * 60).toStringAsFixed(1)}/min), max transientCallbacks=$maxTransient, '
          'harness loop ${(iterations / secs).toStringAsFixed(1)} it/s, frame requested in '
          '${(100 * requested / (iterations == 0 ? 1 : iterations)).toStringAsFixed(1)}% of vsync slots '
          '(=> ~${(60 * requested / (iterations == 0 ? 1 : iterations)).toStringAsFixed(1)} fps on a 60 Hz device), '
          '${summarize(collectBuilds(), secs)}';
      obs(r);
      return r;
    }

    final h = await bootApp({'app_settings': settingsJson(wage: 15)});
    h.timer.addListener(() => notifies++);
    debugProfileBuildsEnabled = true;
    FlutterTimeline.debugCollectionEnabled = true;

    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();
    await window('IDLE warm-up', const Duration(seconds: 2), h: h);
    await window('IDLE, timer stopped', const Duration(seconds: 5), h: h);

    await h.timer.start();
    await window('FOREGROUND, 15 EUR/h', const Duration(seconds: 32), h: h);

    await h.settings.setHourlyWage(150); // 1 cent every 0.24 s -> digits animate constantly
    await window('FOREGROUND, 150 EUR/h', const Duration(seconds: 8), h: h);
    await h.settings.setHourlyWage(15);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await window('PAUSED (background), 15 EUR/h', const Duration(seconds: 32), h: h);
    obs('while paused: framesEnabled=${SchedulerBinding.instance.framesEnabled}, timer.isRunning=${h.timer.isRunning}');

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await window('RESUMED', const Duration(seconds: 3), h: h);

    final posts = notificationCalls.where((c) => c.method == 'show').toList();
    obs('all show() bodies: ${posts.map((c) => (c.arguments as Map)['body']).toList()}');

    debugProfileBuildsEnabled = false;
    FlutterTimeline.debugCollectionEnabled = false;
    await h.dispose(tester);
    resetScreen(tester);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
