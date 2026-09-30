import 'dart:io';

import 'package:chronos/app/error_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/db.dart';
import '../fixtures/shifts.dart';
import '../fixtures/test_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late ErrorLog log;

  setUp(() {
    dir = tempDir();
    log = ErrorLog(
      directory: () async => dir,
      clock: TestClock(local(2026, 9, 30, 12)).clock,
    );
  });

  test('records entries with time, context, error and stack', () async {
    await log.record(StateError('boom'), StackTrace.current, context: 'test');
    final text = await log.read();
    expect(
      text,
      contains('[${local(2026, 9, 30, 12).toIso8601String()}] test'),
    );
    expect(text, contains('Bad state: boom'));
    expect(text, contains('error_log_test.dart'));
    expect(File('${dir.path}/error_log.txt').existsSync(), isTrue);
  });

  test('keeps the newest entries within the size limit', () async {
    final small = ErrorLog(directory: () async => dir, maxBytes: 2000);
    for (var i = 0; i < 100; i++) {
      await small.record('error number $i', null);
    }
    final text = await small.read();
    expect(await (await small.file()).length(), lessThanOrEqualTo(2000));
    expect(text, contains('error number 99'));
    expect(text, isNot(contains('error number 0\n')));
    expect(text.startsWith('['), isTrue); // cut at an entry boundary
  });

  test('clear', () async {
    await log.record('x', null);
    await log.clear();
    expect(await log.read(), isEmpty);
    await log.clear(); // no file: fine
  });

  test('falls back to memory when the folder is unusable', () async {
    final broken = ErrorLog(
      directory: () async => throw const FileSystemException('ro'),
    );
    await broken.record('kept in memory', null);
    expect(await broken.read(), contains('kept in memory'));
    await broken.clear();
    expect(await broken.read(), isEmpty);
  });

  test(
    'install routes Flutter and platform errors, uninstall restores',
    () async {
      final previousFlutter = FlutterError.onError;
      final previousPlatform = PlatformDispatcher.instance.onError;
      FlutterErrorDetails? forwarded;
      FlutterError.onError = (details) => forwarded = details;
      addTearDown(() {
        FlutterError.onError = previousFlutter;
        PlatformDispatcher.instance.onError = previousPlatform;
      });

      log.install();
      log.install(); // idempotent
      FlutterError.onError!(
        FlutterErrorDetails(exception: Exception('widget')),
      );
      expect(forwarded, isNotNull);
      final handled = PlatformDispatcher.instance.onError!(
        Exception('async'),
        StackTrace.empty,
      );
      expect(handled, isTrue);
      await pumpEventQueue();
      final text = await log.read();
      expect(text, contains('widget'));
      expect(text, contains('async'));

      log.uninstall();
      log.uninstall();
      FlutterError.onError!(FlutterErrorDetails(exception: Exception('after')));
      await pumpEventQueue();
      expect(await log.read(), isNot(contains('after')));
    },
  );
}
