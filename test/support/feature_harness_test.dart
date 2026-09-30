import 'package:chronos/app/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feature_harness.dart';

class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(activeJobsProvider).value ?? const [];
    final running = ref.watch(runningShiftProvider).value;
    return Column(
      children: [
        Text('jobs:${jobs.length}'),
        Text('running:${running != null}'),
        TextButton(
          onPressed: () => ref
              .read(activeShiftControllerProvider.notifier)
              .start(jobs.first.id),
          child: const Text('start'),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('database streams drive the UI in widget tests', (tester) async {
    final f = await pumpFeature(
      tester,
      const _Probe(),
      wrapInScaffold: true,
      seed: (h) => h.job(),
    );
    expect(find.text('jobs:1'), findsOneWidget);
    expect(find.text('running:false'), findsOneWidget);

    await tester.tap(find.text('start'));
    await settleData(tester);
    expect(find.text('running:true'), findsOneWidget);
    expect(f.data.effects.calls, isNotEmpty);
  });
}
