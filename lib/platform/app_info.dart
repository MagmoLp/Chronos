/// Version information of the installed app (package_info_plus).
library;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Name and version of the installed app.
@immutable
class AppInfo {
  /// Creates the app info.
  const AppInfo({
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  /// Application id, `com.paulhuebner.chronos`.
  final String packageName;

  /// Version name from pubspec.yaml, e.g. `2.0.0`.
  final String version;

  /// Version code (build number), e.g. `2`; may be empty.
  final String buildNumber;

  /// `2.0.0+2` (or just `2.0.0` without build number), for error reports and
  /// backups. The UI formats [version] and [buildNumber] via l10n.
  String get fullVersion =>
      buildNumber.isEmpty ? version : '$version+$buildNumber';

  @override
  bool operator ==(Object other) =>
      other is AppInfo &&
      other.packageName == packageName &&
      other.version == version &&
      other.buildNumber == buildNumber;

  @override
  int get hashCode => Object.hash(packageName, version, buildNumber);

  @override
  String toString() => 'AppInfo($packageName $fullVersion)';
}

/// Reads [AppInfo] from the platform.
class AppInfoService {
  /// Creates the service; [loader] is injectable for tests.
  AppInfoService({Future<PackageInfo> Function()? loader})
    : _loader = loader ?? PackageInfo.fromPlatform;

  final Future<PackageInfo> Function() _loader;
  Future<AppInfo>? _cached;

  /// The app info; read once, then cached (a failed read is retried).
  Future<AppInfo> load() async {
    final Future<AppInfo> future = _cached ??= _read();
    try {
      return await future;
    } on Object {
      if (identical(_cached, future)) {
        _cached = null;
      }
      rethrow;
    }
  }

  Future<AppInfo> _read() async {
    final PackageInfo info = await _loader();
    return AppInfo(
      packageName: info.packageName,
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }
}
