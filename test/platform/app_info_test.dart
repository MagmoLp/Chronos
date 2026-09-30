import 'package:chronos/platform/app_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

PackageInfo _info({String buildNumber = '2'}) => PackageInfo(
  appName: 'Chronos',
  packageName: 'com.paulhuebner.chronos',
  version: '2.0.0',
  buildNumber: buildNumber,
);

void main() {
  test('reads version and build number', () async {
    final AppInfo info = await AppInfoService(loader: () async => _info())
        .load();
    expect(
      info,
      const AppInfo(
        packageName: 'com.paulhuebner.chronos',
        version: '2.0.0',
        buildNumber: '2',
      ),
    );
    expect(info.fullVersion, '2.0.0+2');
  });

  test('fullVersion without a build number', () async {
    final AppInfo info = await AppInfoService(
      loader: () async => _info(buildNumber: ''),
    ).load();
    expect(info.fullVersion, '2.0.0');
  });

  test('is read once and cached', () async {
    var reads = 0;
    final AppInfoService service = AppInfoService(
      loader: () async {
        reads++;
        return _info();
      },
    );
    await service.load();
    await service.load();
    expect(reads, 1);
  });

  test('a failed read is retried on the next call', () async {
    var reads = 0;
    final AppInfoService service = AppInfoService(
      loader: () async {
        reads++;
        if (reads == 1) {
          throw StateError('platform not ready');
        }
        return _info();
      },
    );
    await expectLater(service.load(), throwsStateError);
    expect((await service.load()).version, '2.0.0');
    expect(reads, 2);
  });

  test('uses package_info_plus by default', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Chronos',
      packageName: 'com.paulhuebner.chronos',
      version: '2.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
    expect((await AppInfoService().load()).fullVersion, '2.0.0+2');
  });
}
