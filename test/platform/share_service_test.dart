import 'dart:convert';
import 'dart:io';

import 'package:chronos/platform/share_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

const MethodChannel _shareChannel = MethodChannel(
  'dev.fluttercommunity.plus/share',
);

/// An in-memory picked file.
final class _MemoryFile extends PlatformFile {
  _MemoryFile(this.name, this.data, {this.reportedLength});

  @override
  final String name;
  final Uint8List data;
  final int? reportedLength;

  @override
  Uri get uri => Uri.file('/cache/file_picker/$name');

  @override
  XFile get xFile => XFile.fromData(data, name: name);

  @override
  int? lengthSync() => reportedLength;

  @override
  Future<int?> length() async => data.length;

  @override
  Future<Uint8List> readAsBytes() async => data;

  @override
  Stream<Uint8List> readAsByteStream() => Stream<Uint8List>.value(data);
}

class _FakePicker extends FilePickerPlatform {
  PlatformFile? next;
  int picks = 0;
  int cacheClears = 0;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    picks++;
    expect(type, FileType.any, reason: 'no MIME filter for backups');
    return next;
  }

  @override
  Future<void> clearTemporaryFiles() async => cacheClears++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late ShareService service;
  late List<MethodCall> shareCalls;
  late Object? shareAnswer;
  late FilePickerPlatform originalPicker;
  late _FakePicker picker;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('chronos_share_test');
    service = ShareService(temporaryDirectory: () async => temp);
    shareCalls = <MethodCall>[];
    shareAnswer = 'com.example.mail';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (MethodCall call) async {
          shareCalls.add(call);
          return shareAnswer;
        });
    originalPicker = FilePickerPlatform.instance;
    picker = _FakePicker();
    FilePickerPlatform.instance = picker;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
    FilePickerPlatform.instance = originalPicker;
    temp.deleteSync(recursive: true);
  });

  Map<Object?, Object?> lastShare() =>
      shareCalls.single.arguments as Map<Object?, Object?>;

  group('temporary files', () {
    test('saveToTemp writes into the chronos_share cache folder', () async {
      final File file = await service.saveToTemp(
        'backup.json',
        utf8.encode('{}'),
      );
      expect(file.path, '${temp.path}/chronos_share/backup.json');
      expect(file.readAsStringSync(), '{}');
    });

    test('an existing file of the same name is replaced', () async {
      await service.saveToTemp('export.csv', utf8.encode('old content'));
      final File file = await service.saveToTemp(
        'export.csv',
        utf8.encode('new'),
      );
      expect(file.readAsStringSync(), 'new');
    });

    test(
      'file names cannot escape the folder or contain reserved characters',
      () async {
        final File file = await service.saveToTemp(
          '../../evil:name?.txt',
          <int>[1],
        );
        expect(file.path, '${temp.path}/chronos_share/evil_name_.txt');
        expect(() => service.saveToTemp('..', <int>[1]), throwsArgumentError);
        expect(() => service.saveToTemp('  ', <int>[1]), throwsArgumentError);
      },
    );

    test(
      'saveTextToTemp writes UTF-8, optionally with a BOM for Excel',
      () async {
        final File plain = await service.saveTextToTemp('a.csv', 'Café;1,50');
        expect(plain.readAsBytesSync(), utf8.encode('Café;1,50'));
        final File withBom = await service.saveTextToTemp(
          'b.csv',
          'Café',
          withByteOrderMark: true,
        );
        expect(withBom.readAsBytesSync(), <int>[
          0xEF,
          0xBB,
          0xBF,
          ...utf8.encode('Café'),
        ]);
      },
    );

    test('clearTemp removes the folder and tolerates a missing one', () async {
      await service.saveToTemp('a.txt', <int>[1]);
      await service.clearTemp();
      expect(Directory('${temp.path}/chronos_share').existsSync(), isFalse);
      await service.clearTemp();
    });
  });

  group('share sheet', () {
    test('shareFile passes path, MIME type and subject', () async {
      final File file = await service.saveToTemp('stundenzettel.pdf', <int>[
        1,
        2,
      ]);
      final ShareOutcome outcome = await service.shareFile(
        file.path,
        mimeType: ShareMimeTypes.pdf,
        subject: 'Stundenzettel September 2026',
      );
      expect(outcome, ShareOutcome.shared);
      final Map<Object?, Object?> args = lastShare();
      expect(shareCalls.single.method, 'share');
      expect(args['paths'], <String>[file.path]);
      expect(args['mimeTypes'], <String>['application/pdf']);
      expect(args['subject'], 'Stundenzettel September 2026');
      expect(args.containsKey('text'), isFalse);
    });

    test('shareText shares plain text', () async {
      await service.shareText('Fehlerbericht', subject: 'Chronos');
      expect(lastShare()['text'], 'Fehlerbericht');
      expect(lastShare()['subject'], 'Chronos');
    });

    test('maps the share result', () async {
      shareAnswer = '';
      expect(await service.shareText('x'), ShareOutcome.dismissed);
      shareAnswer = null;
      expect(await service.shareText('x'), ShareOutcome.unknown);
    });
  });

  group('pickBackupFile', () {
    test(
      'returns the chosen file with its bytes and clears the picker cache',
      () async {
        picker.next = _MemoryFile(
          'chronos-backup.json',
          Uint8List.fromList(utf8.encode('{"a":1}')),
        );
        final PickedFile? file = await service.pickBackupFile();
        expect(file, isNotNull);
        expect(file!.name, 'chronos-backup.json');
        expect(file.path, '/cache/file_picker/chronos-backup.json');
        expect(file.decodeText(), '{"a":1}');
        expect(picker.cacheClears, 1);
      },
    );

    test('returns null when the user cancels', () async {
      expect(await service.pickBackupFile(), isNull);
      expect(picker.picks, 1);
    });

    test('decodeText strips a byte order mark and rejects invalid UTF-8', () {
      final PickedFile withBom = PickedFile(
        name: 'b.json',
        bytes: Uint8List.fromList(<int>[
          0xEF,
          0xBB,
          0xBF,
          ...utf8.encode('{}'),
        ]),
      );
      expect(withBom.decodeText(), '{}');
      final PickedFile broken = PickedFile(
        name: 'b.json',
        bytes: Uint8List.fromList(<int>[0xFF, 0xFE, 0x00]),
      );
      expect(broken.decodeText, throwsFormatException);
    });

    test('rejects files above the limit (reported size)', () async {
      picker.next = _MemoryFile(
        'huge.json',
        Uint8List(10),
        reportedLength: 2000,
      );
      await expectLater(
        service.pickBackupFile(maxBytes: 1000),
        throwsA(
          isA<PickedFileTooLargeException>()
              .having(
                (PickedFileTooLargeException e) => e.sizeBytes,
                'sizeBytes',
                2000,
              )
              .having(
                (PickedFileTooLargeException e) => e.maxBytes,
                'maxBytes',
                1000,
              ),
        ),
      );
      expect(picker.cacheClears, 1);
    });

    test('rejects files above the limit (actual size)', () async {
      picker.next = _MemoryFile('huge.json', Uint8List(1001));
      await expectLater(
        service.pickBackupFile(maxBytes: 1000),
        throwsA(isA<PickedFileTooLargeException>()),
      );
    });
  });
}
