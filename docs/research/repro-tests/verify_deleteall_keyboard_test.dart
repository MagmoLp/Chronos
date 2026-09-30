// Delete-all dialog on a real phone size with the soft keyboard open: can the user see the field / hit the button?
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'verify_delete_common.dart';

bool hittable(WidgetTester t, Finder f) {
  final box = t.renderObject<RenderBox>(f);
  final c = box.localToGlobal(box.size.center(Offset.zero));
  final r = HitTestResult();
  t.binding.hitTestInView(r, c, t.view.viewId);
  return r.path.any((e) => e.target == box) &&
      c.dy >= 0 && c.dy <= t.view.physicalSize.height / t.view.devicePixelRatio - t.view.viewInsets.bottom / t.view.devicePixelRatio;
}

void main() {
  setUpAll(() async => loadRealFonts());
  for (final size in [const Size(360, 740), const Size(411, 914)]) {
    testWidgets('delete-all dialog ${size.width.toInt()}x${size.height.toInt()} with 300dp keyboard', (t) async {
      final errs = await captureErrors(() async {
        final h = await startApp(t, entries: baseEntries(), size: size);
        await t.tap(find.byIcon(Icons.settings));
        await t.pumpAndSettle();
        await t.tap(find.text('Alle Einträge löschen'));
        await t.pumpAndSettle();
        final field = find.byType(TextField).last;
        await t.tap(field);
        t.view.viewInsets = FakeViewPadding(bottom: 300 * t.view.devicePixelRatio);
        await t.pumpAndSettle();
        await t.enterText(field, 'Löschen');
        await t.pumpAndSettle();
        final btn = find.widgetWithText(ElevatedButton, 'Löschen');
        final fieldBox = t.renderObject<RenderBox>(field);
        final fTop = fieldBox.localToGlobal(Offset.zero).dy;
        obs('${size.width.toInt()}x${size.height.toInt()}: keyboard top=${size.height - 300}; field y=${fTop.toStringAsFixed(0)}..${(fTop + fieldBox.size.height).toStringAsFixed(0)} '
            'fieldHittable=${hittable(t, field)} button y=${t.getCenter(btn).dy.toStringAsFixed(0)} buttonHittable=${hittable(t, btn)}');
        await t.tap(btn, warnIfMissed: false);
        await t.pumpAndSettle();
        obs('  after tapping confirm: entries=${h.entries.entries.length}');
        t.view.resetViewInsets();
        await h.dispose(t);
      });
      obs('  layout errors: ${errs.map((e) => e.summary).toSet().toList()}');
      resetScreen(t);
    });
  }
}
