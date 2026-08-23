import 'package:bird/models/flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('flutter_sdk model', () {
    test('parses version JSON output correctly', () {
      const sampleJson = '''
{
  "frameworkVersion": "3.44.0",
  "channel": "stable",
  "repositoryUrl": "https://github.com/flutter/flutter.git",
  "frameworkRevision": "c1a3eee26a00a5ba5e48ba98109e53d9d8675d87",
  "frameworkCommitDate": "2026-08-19 23:44:24 +0300",
  "engineRevision": "925e526cdd3b028f4d858f37598d246391f22d7f",
  "dartSdkVersion": "3.12.0",
  "flutterVersion": "3.44.0",
  "flutterRoot": "/mock/flutter",
  "frameworkRevisionShort": "c1a3eee",
  "engineRevisionShort": "925e526"
}
''';

      final info = parseVersionJson(
        sampleJson,
        sdkPath: '/mock/flutter',
        location: FlutterSdkLocation.bundled,
      );

      expect(info, isNotNull);
      expect(info!.flutterVersion, '3.44.0');
      expect(info.dartVersion, '3.12.0');
      expect(info.channel, 'stable');
      expect(info.location, FlutterSdkLocation.bundled);
      expect(info.isBundled, isTrue);
      expect(info.frameworkRevision, 'c1a3eee');
    });

    test('parses version plain text output correctly', () {
      const sampleText = '''
Flutter 3.44.0 • channel beta • https://github.com/flutter/flutter.git
Framework • revision c1a3eee (3 days ago) • 2026-08-19 23:44:24 +0300
Engine • revision 925e526
Tools • Dart 3.12.0 • DevTools 2.45.0
''';

      final info = parseVersionText(
        sampleText,
        sdkPath: '/mock/flutter',
        location: FlutterSdkLocation.system,
      );

      expect(info, isNotNull);
      expect(info!.flutterVersion, '3.44.0');
      expect(info.dartVersion, '3.12.0');
      expect(info.channel, 'beta');
      expect(info.location, FlutterSdkLocation.system);
      expect(info.isBundled, isFalse);
    });

    test('handles malformed version JSON gracefully', () {
      final info = parseVersionJson(
        'not valid json',
        sdkPath: '/mock/flutter',
        location: FlutterSdkLocation.custom,
      );

      expect(info, isNull);
    });

    test('picks the archive built for the host CPU, not the first match', () {
      // Both builds share the release hash; only dart_sdk_arch tells them apart.
      final manifest = {
        'base_url': 'https://example.test/releases',
        'current_release': {'stable': 'abc123'},
        'releases': [
          {
            'hash': 'abc123',
            'channel': 'stable',
            'version': '3.47.1',
            'dart_sdk_arch': 'x64',
            'archive': 'stable/macos/flutter_macos_3.47.1-stable.zip',
          },
          {
            'hash': 'abc123',
            'channel': 'stable',
            'version': '3.47.1',
            'dart_sdk_arch': 'arm64',
            'archive': 'stable/macos/flutter_macos_arm64_3.47.1-stable.zip',
          },
        ],
      };

      final arm = pickRelease(manifest, 'stable', arch: 'arm64');
      expect(arm.archivePath, contains('arm64'));
      expect(
        arm.downloadUrl,
        'https://example.test/releases/${arm.archivePath}',
      );
      expect(arm.version, '3.47.1');

      final intel = pickRelease(manifest, 'stable', arch: 'x64');
      expect(intel.archivePath, isNot(contains('arm64')));
    });

    test('reports an empty manifest instead of installing nothing', () {
      expect(
        () => pickRelease({'releases': []}, 'stable', arch: 'arm64'),
        throwsA(isA<Exception>()),
      );
    });

    test('formats byte counts for the progress panel', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(2257635847), '2.1 GB');
    });

    test('orders versions by number, and a release above its pre-release', () {
      expect(compareVersions('3.47.1', '3.44.9'), greaterThan(0));
      expect(compareVersions('3.44.10', '3.44.9'), greaterThan(0));
      expect(compareVersions('3.47.1', '3.47.1'), 0);
      expect(compareVersions('3.48.0', '3.48.0-0.1.pre'), greaterThan(0));
      expect(
        compareVersions('3.48.0-0.2.pre', '3.48.0-0.1.pre'),
        greaterThan(0),
      );
    });

    test('lists each version once, newest first', () {
      final manifest = {
        'releases': [
          {'version': '3.44.9', 'channel': 'stable', 'dart_sdk_arch': 'arm64'},
          {'version': '3.47.1', 'channel': 'stable', 'dart_sdk_arch': 'arm64'},
          {'version': '3.47.1', 'channel': 'stable', 'dart_sdk_arch': 'x64'},
          {
            'version': '3.48.0-0.1.pre',
            'channel': 'beta',
            'dart_sdk_arch': 'arm64',
          },
        ],
      };

      final releases = listReleases(manifest, arch: 'arm64');
      expect(releases.map((r) => r.version), [
        '3.48.0-0.1.pre',
        '3.47.1',
        '3.44.9',
      ]);
      expect(releases.first.channel, 'beta');
    });

    test('installs the version asked for, not the channel tip', () {
      final manifest = {
        'base_url': 'https://example.test/releases',
        'current_release': {'stable': 'newest'},
        'releases': [
          {
            'hash': 'newest',
            'version': '3.47.1',
            'channel': 'stable',
            'dart_sdk_arch': 'arm64',
            'archive': 'stable/macos/flutter_macos_arm64_3.47.1-stable.zip',
          },
          {
            'hash': 'older',
            'version': '3.44.9',
            'channel': 'stable',
            'dart_sdk_arch': 'arm64',
            'archive': 'stable/macos/flutter_macos_arm64_3.44.9-stable.zip',
          },
        ],
      };

      final pinned = pickRelease(
        manifest,
        'stable',
        arch: 'arm64',
        version: '3.44.9',
      );
      expect(pinned.version, '3.44.9');
      expect(pinned.archivePath, contains('3.44.9'));
      expect(
        () => pickRelease(manifest, 'stable', arch: 'arm64', version: '1.0.0'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
