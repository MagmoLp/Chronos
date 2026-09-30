import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local error log ("Fehlerbericht teilen"): a text file capped at
/// [maxBytes] that keeps the newest entries (ring buffer). Nothing leaves the
/// device unless the user shares the file.
///
/// Writing never throws; if the file cannot be written, entries are kept in
/// memory and still returned by [read].
class ErrorLog {
  /// Creates a log in the folder returned by [directory].
  ErrorLog({
    required this._directory,
    this.maxBytes = 200 * 1024,
    this.fileName = 'error_log.txt',
    Clock? clock,
  }) : _clockOverride = clock;

  final Future<Directory> Function() _directory;
  final Clock? _clockOverride;

  /// Size limit of the file in bytes (about 200 KB).
  final int maxBytes;

  /// File name inside the directory.
  final String fileName;

  Clock get _clock => _clockOverride ?? clock;

  static const int _memoryLimit = 50;
  final List<String> _memory = [];
  Future<void> _queue = Future.value();
  FlutterExceptionHandler? _previousFlutterHandler;
  bool Function(Object, StackTrace)? _previousPlatformHandler;
  bool _installed = false;

  /// The log file (it may not exist yet).
  Future<File> file() async =>
      File(p.join((await _directory()).path, fileName));

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  /// Appends an entry for [error] with its [stack] and optional [context].
  Future<void> record(Object error, StackTrace? stack, {String? context}) {
    final buffer = StringBuffer()
      ..write('[${_clock.now().toUtc().toIso8601String()}]')
      ..writeln(context == null ? '' : ' $context')
      ..writeln(error);
    if (stack != null) buffer.writeln(stack.toString().trimRight());
    buffer.writeln();
    final entry = buffer.toString();
    _memory.add(entry);
    if (_memory.length > _memoryLimit) _memory.removeAt(0);
    return _serial(() async {
      try {
        final f = await file();
        await f.parent.create(recursive: true);
        final bytes = utf8.encode(entry);
        final size = f.existsSync() ? await f.length() : 0;
        if (size + bytes.length > maxBytes) {
          await _trim(f, maxBytes * 3 ~/ 4 - bytes.length);
        }
        await f.writeAsBytes(bytes, mode: FileMode.append, flush: true);
      } on Object {
        // Logging must never fail; the entry stays in memory.
      }
    });
  }

  /// Keeps only the newest [keepBytes] (cut at an entry boundary).
  Future<void> _trim(File f, int keepBytes) async {
    if (!f.existsSync()) return;
    final bytes = await f.readAsBytes();
    if (keepBytes <= 0) {
      await f.writeAsBytes(const [], flush: true);
      return;
    }
    var cut = bytes.length - keepBytes;
    if (cut <= 0) return;
    // Advance to the next entry start ("\n[").
    while (cut < bytes.length - 1 &&
        !(bytes[cut] == 0x0A && bytes[cut + 1] == 0x5B)) {
      cut++;
    }
    final kept = cut >= bytes.length - 1 ? <int>[] : bytes.sublist(cut + 1);
    await f.writeAsBytes(kept, flush: true);
  }

  /// The log contents (file, or in-memory entries if there is no file).
  Future<String> read() => _serial(() async {
    try {
      final f = await file();
      if (f.existsSync()) {
        return utf8.decode(await f.readAsBytes(), allowMalformed: true);
      }
    } on Object {
      // Fall through to memory.
    }
    return _memory.join();
  });

  /// Deletes all entries.
  Future<void> clear() => _serial(() async {
    _memory.clear();
    try {
      final f = await file();
      if (f.existsSync()) await f.delete();
    } on Object {
      // Nothing to clear.
    }
  });

  /// Routes Flutter framework errors and uncaught platform/async errors to
  /// this log. Previous handlers keep working.
  void install() {
    if (_installed) return;
    _installed = true;
    _previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      unawaited(
        record(
          details.exception,
          details.stack,
          context: details.context?.toDescription(),
        ),
      );
      _previousFlutterHandler?.call(details);
    };
    final dispatcher = PlatformDispatcher.instance;
    _previousPlatformHandler = dispatcher.onError;
    dispatcher.onError = (error, stack) {
      unawaited(record(error, stack, context: 'uncaught'));
      return _previousPlatformHandler?.call(error, stack) ?? true;
    };
  }

  /// Restores the handlers that were active before [install].
  void uninstall() {
    if (!_installed) return;
    _installed = false;
    FlutterError.onError = _previousFlutterHandler;
    PlatformDispatcher.instance.onError = _previousPlatformHandler;
  }
}

/// The app's error log (app support folder). Override in tests or create it
/// in `main` before `runApp` and pass it via `overrideWithValue`.
final errorLogProvider = Provider<ErrorLog>(
  (ref) => ErrorLog(directory: getApplicationSupportDirectory),
  name: 'errorLogProvider',
);
