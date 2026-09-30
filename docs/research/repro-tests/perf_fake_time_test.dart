// Item 4a: deterministic (fake-time) rebuild / notify / lifecycle measurements.
//
// NOTE: DateTime.now() is NOT faked by flutter_test, so TimerProvider._elapsed
// does not advance with fake time. Anything that depends on elapsed seconds
// (notification cadence, money digits changing) must be measured in
// perf_live_test.dart instead. Here we only count work per timer tick.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

// ignore: avoid_print
void obs(String s) => print('OBS: $s');

class Counters {
  int notifies = 0;
  int frames = 0;
  final dirtyRoots = <String, int>{};
  void reset() {
    notifies = 0;
    frames = 0;
    dirtyRoots.clear();
    FlutterTimeline.debugReset();
  }

  Map<String, int> builds() {
    final agg = FlutterTimeline.debugCollect();
    final m = <String, int>{};
    for (final b in agg.aggregatedBlocks) {
      m[b.name] = b.count;
    }
    return m;
  }
}

String topBuilds(Map<String, int> m, {int n = 12}) {
  final skip = {'BUILD', 'LAYOUT', 'PAINT', 'COMPOSITING', 'SEMANTICS', 'FINALIZE TREE', 'UPDATING COMPOSITING BITS', 'Animate', 'POST_FRAME'};
  final e = m.entries.where((e) => !skip.contains(e.key)).toList()..sort((a, b) => b.value.compareTo(a.value));
  final total = e.fold<int>(0, (a, b) => a + b.value);
  return 'total widget builds=$total; top: ${e.take(n).map((x) => '${x.key}=${x.value}').join(', ')}';
}

void main() {
  setUpAll(() async => loadRealFonts());

  testWidgets('per-tick work while timer runs; lifecycle paused keeps the Timer alive', (tester) async {
    installNotificationStub();
    setScreen(tester, const Size(800, 1280));
    final c = Counters();
    final h = await bootApp({
      'app_settings': settingsJson(),
      'work_entries': sampleEntriesJson(),
      'active_session': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    });
    h.timer.addListener(() => c.notifies++);
    SchedulerBinding.instance.addPersistentFrameCallback((_) => c.frames++);
    debugOnRebuildDirtyWidget = (e, builtOnce) {
      final k = e.widget.runtimeType.toString();
      c.dirtyRoots[k] = (c.dirtyRoots[k] ?? 0) + 1;
    };
    debugProfileBuildsEnabled = true;
    FlutterTimeline.debugCollectionEnabled = true;

    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();

    // ---- Home visible, 10 ticks
    c.reset();
    final shows0 = countNotif('show');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    final homeBuilds = c.builds();
    obs('FAKE-TIME: restored 1h session -> notification show() calls in 10 fake seconds = ${countNotif('show') - shows0} '
        '(elapsed is read from the real clock, so the 15 s cadence cannot be observed under fake time)');
    obs('HOME visible, 10 s fake: notifyListeners=${c.notifies}, frames=${c.frames}, '
        'dirty rebuild roots=${c.dirtyRoots}; ${topBuilds(homeBuilds)}');

    // ---- Settings pushed on top of Home: Home is covered but still rebuilt
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    c.reset();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    obs('SETTINGS on top of Home, 10 s: notifyListeners=${c.notifies}, frames=${c.frames}, '
        'dirty rebuild roots=${c.dirtyRoots}; ${topBuilds(c.builds(), n: 6)}');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    // ---- Work log tab: HomeScreen unmounted
    await tester.tap(find.byIcon(Icons.format_list_bulleted));
    await tester.pumpAndSettle();
    c.reset();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    obs('WORK LOG tab, 10 s: notifyListeners=${c.notifies}, frames=${c.frames}, '
        'dirty rebuild roots=${c.dirtyRoots}; ${topBuilds(c.builds(), n: 6)}');
    await tester.tap(find.byIcon(Icons.timer));
    await tester.pumpAndSettle();

    // ---- App backgrounded
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    c.reset();
    var scheduledWhilePaused = 0;
    for (var i = 0; i < 60; i++) {
      await tester.binding.delayed(const Duration(seconds: 1));
      if (tester.binding.hasScheduledFrame) scheduledWhilePaused++;
    }
    obs('PAUSED 60 s (fake): framesEnabled=${SchedulerBinding.instance.framesEnabled}, '
        'Timer still active=${h.timer.isRunning}, notifyListeners=${c.notifies}, frames=${c.frames}, '
        'hasScheduledFrame true in $scheduledWhilePaused/60 samples, transientCallbacks='
        '${SchedulerBinding.instance.transientCallbackCount}; ${topBuilds(c.builds(), n: 4)}');

    // ---- Resume: how much work is done on the first frame?
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    c.reset();
    await tester.pump();
    obs('RESUME first frame: frames=${c.frames}; ${topBuilds(c.builds(), n: 4)}');

    debugOnRebuildDirtyWidget = null;
    debugProfileBuildsEnabled = false;
    FlutterTimeline.debugCollectionEnabled = false;
    await h.dispose(tester);
    resetScreen(tester);
  });

  testWidgets('fake-time artifact: fresh start posts a notification on EVERY tick', (tester) async {
    installNotificationStub();
    setScreen(tester, const Size(800, 1280));
    final h = await bootApp({'app_settings': settingsJson()});
    await tester.pumpWidget(h.app);
    await h.timer.start();
    final before = countNotif('show');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    obs('FAKE-TIME ARTIFACT: fresh start, 10 fake seconds -> show() calls=${countNotif('show') - before} '
        '(elapsed stays 0 s, so "_lastNotificationUpdate == 0" is true every tick). Real cadence: perf_live_test.dart');
    await h.dispose(tester);
    resetScreen(tester);
  });

  testWidgets('idle (timer stopped): no periodic work', (tester) async {
    installNotificationStub();
    setScreen(tester, const Size(800, 1280));
    final h = await bootApp({'app_settings': settingsJson()});
    var frames = 0;
    SchedulerBinding.instance.addPersistentFrameCallback((_) => frames++);
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();
    frames = 0;
    var scheduled = 0;
    for (var i = 0; i < 10; i++) {
      await tester.binding.delayed(const Duration(seconds: 1));
      if (tester.binding.hasScheduledFrame) scheduled++;
    }
    obs('IDLE 10 s: frames requested in $scheduled/10 samples');
    expect(scheduled, 0);
    await h.dispose(tester);
    resetScreen(tester);
  });
}
