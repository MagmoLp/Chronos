/// Sharing files and text through the Android share sheet (share_plus),
/// picking a backup file (file_picker) and writing temporary export files.
///
/// Nothing here needs a storage permission: exports are written to the app's
/// cache directory and handed to the share sheet, backups are read through the
/// system file picker.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Common MIME types of Chronos' exports.
abstract final class ShareMimeTypes {
  /// Backup files (`*.json`).
  static const String json = 'application/json';

  /// CSV exports.
  static const String csv = 'text/csv';

  /// PDF timesheets.
  static const String pdf = 'application/pdf';

  /// Error reports and other plain text.
  static const String text = 'text/plain';
}

/// What the user did with the share sheet.
enum ShareOutcome {
  /// A target app was chosen (Android cannot tell whether it really sent).
  shared,

  /// The share sheet was closed without choosing a target.
  dismissed,

  /// The platform does not report the result.
  unknown,
}

/// A file chosen with [ShareService.pickBackupFile], read into memory.
@immutable
class PickedFile {
  /// Creates a picked file.
  const PickedFile({required this.name, required this.bytes, this.path});

  /// File name including the extension, as shown in the picker.
  final String name;

  /// Local path of the (cached) copy, if the platform provides one.
  final String? path;

  /// The file content.
  final Uint8List bytes;

  /// The content as UTF-8 text without a leading byte order mark.
  ///
  /// Throws a [FormatException] if the file is not valid UTF-8.
  String decodeText() {
    final String text = utf8.decode(bytes);
    return text.startsWith('﻿') ? text.substring(1) : text;
  }
}

/// Thrown by [ShareService.pickBackupFile] when the chosen file is larger
/// than allowed (a backup is a few MB at most; this protects the memory).
class PickedFileTooLargeException implements Exception {
  /// Creates the exception.
  const PickedFileTooLargeException({
    required this.fileName,
    required this.sizeBytes,
    required this.maxBytes,
  });

  /// Name of the rejected file.
  final String fileName;

  /// Size of the rejected file in bytes.
  final int sizeBytes;

  /// The limit in bytes.
  final int maxBytes;

  @override
  String toString() =>
      'PickedFileTooLargeException: $fileName has $sizeBytes bytes '
      '(limit $maxBytes)';
}

/// Share sheet, file picker and temporary files.
class ShareService {
  /// Creates the service. All parameters are injectable for tests.
  ShareService({
    SharePlus? sharePlus,
    Future<Directory> Function()? temporaryDirectory,
  }) : _sharePlus = sharePlus ?? SharePlus.instance,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final SharePlus _sharePlus;
  final Future<Directory> Function() _temporaryDirectory;

  /// Default limit for [pickBackupFile]: 50 MB.
  static const int defaultMaxBackupBytes = 50 * 1024 * 1024;

  /// Name of the folder inside the cache directory used by [saveToTemp].
  static const String tempFolderName = 'chronos_share';

  /// Opens the share sheet for the file at [path].
  ///
  /// [subject] becomes the e-mail subject, [text] an accompanying message,
  /// [title] the title of the share sheet (all optional, already localized).
  Future<ShareOutcome> shareFile(
    String path, {
    required String mimeType,
    String? subject,
    String? text,
    String? title,
  }) async {
    final ShareResult result = await _sharePlus.share(
      ShareParams(
        files: <XFile>[XFile(path, mimeType: mimeType)],
        subject: subject,
        text: text,
        title: title,
      ),
    );
    return _outcome(result);
  }

  /// Opens the share sheet for plain [text].
  Future<ShareOutcome> shareText(
    String text, {
    String? subject,
    String? title,
  }) async {
    final ShareResult result = await _sharePlus.share(
      ShareParams(text: text, subject: subject, title: title),
    );
    return _outcome(result);
  }

  /// Lets the user choose a backup file and reads it.
  ///
  /// Returns `null` if the user cancelled. Any file type can be chosen:
  /// Android filters by MIME type, and backups received via messengers or
  /// cloud drives are often labelled `application/octet-stream` and would be
  /// greyed out with a `.json` filter. The caller validates the content.
  /// Throws a [PickedFileTooLargeException] above [maxBytes]. The picker's
  /// cached copy is deleted after reading.
  Future<PickedFile?> pickBackupFile({
    String? dialogTitle,
    int maxBytes = defaultMaxBackupBytes,
  }) async {
    final PlatformFile? file = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
    );
    if (file == null) {
      return null;
    }
    try {
      final int? size = file.lengthSync() ?? await file.length();
      if (size != null && size > maxBytes) {
        throw PickedFileTooLargeException(
          fileName: file.name,
          sizeBytes: size,
          maxBytes: maxBytes,
        );
      }
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.length > maxBytes) {
        throw PickedFileTooLargeException(
          fileName: file.name,
          sizeBytes: bytes.length,
          maxBytes: maxBytes,
        );
      }
      return PickedFile(name: file.name, path: file.path, bytes: bytes);
    } finally {
      await _clearPickerCache();
    }
  }

  /// Writes [bytes] to `<cache>/chronos_share/<fileName>` (replacing an older
  /// file of that name) and returns the file, ready for [shareFile].
  Future<File> saveToTemp(String fileName, List<int> bytes) async {
    final Directory folder = await _tempFolder();
    final File file = File(p.join(folder.path, _safeFileName(fileName)));
    return file.writeAsBytes(bytes, flush: true);
  }

  /// Writes [text] as UTF-8 (optionally with a byte order mark, which Excel
  /// needs to detect UTF-8 in CSV files) via [saveToTemp].
  Future<File> saveTextToTemp(
    String fileName,
    String text, {
    bool withByteOrderMark = false,
  }) => saveToTemp(fileName, <int>[
    if (withByteOrderMark) ...<int>[0xEF, 0xBB, 0xBF],
    ...utf8.encode(text),
  ]);

  /// Deletes all files written by [saveToTemp] (e.g. at app start). Android
  /// may also clear the cache on its own when storage runs low.
  Future<void> clearTemp() async {
    final Directory folder = Directory(
      p.join((await _temporaryDirectory()).path, tempFolderName),
    );
    if (folder.existsSync()) {
      await folder.delete(recursive: true);
    }
  }

  Future<Directory> _tempFolder() async {
    final Directory folder = Directory(
      p.join((await _temporaryDirectory()).path, tempFolderName),
    );
    return folder.create(recursive: true);
  }

  Future<void> _clearPickerCache() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } on PlatformException {
      // Only housekeeping; the system clears the cache eventually.
    }
  }

  static ShareOutcome _outcome(ShareResult result) => switch (result.status) {
    ShareResultStatus.success => ShareOutcome.shared,
    ShareResultStatus.dismissed => ShareOutcome.dismissed,
    ShareResultStatus.unavailable => ShareOutcome.unknown,
  };

  /// Keeps only the base name and replaces characters that are not allowed
  /// in file names on Android or in e-mail attachments.
  static String _safeFileName(String fileName) {
    final String base = p.basename(fileName.trim());
    final String safe = base.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
    if (safe.isEmpty || safe == '.' || safe == '..') {
      throw ArgumentError.value(fileName, 'fileName', 'is not a file name');
    }
    return safe;
  }
}
