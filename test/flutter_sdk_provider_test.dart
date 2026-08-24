import 'dart:io';

import 'package:bird/features/sdk/flutter_sdk.dart';
import 'package:bird/features/sdk/flutter_sdk_service.dart';
import 'package:bird/features/sdk/flutter_sdk_provider.dart';
import 'package:bird/features/settings/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Detection spawns processes; wait for the scan in flight to finish.
Future<void> settled(FlutterSdkProvider provider) async {
  while (provider.isDetecting) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Writes a directory detection accepts as a Flutter SDK of [version].
void writeFakeSdk(String sdkPath, String version, {String channel = 'stable'}) {
  Directory(p.join(sdkPath, 'bin', 'cache')).createSync(recursive: true);
  File(getFlutterExecutable(sdkPath)).writeAsStringSync('');
  File(
    p.join(sdkPath, 'bin', 'cache', 'flutter.version.json'),
  ).writeAsStringSync(
    '{"flutterVersion": "$version", "dartSdkVersion": "3.13.1", '
    '"channel": "$channel"}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterSdkProvider', () {
    test('lists every source and pins the one the user picked', () async {
      final directory = Directory.systemTemp.createTempSync('bird_sdk_test');
      addTearDown(() => directory.deleteSync(recursive: true));

      final sdkPath = p.join(directory.path, 'flutter');
      Directory(p.join(sdkPath, 'bin', 'cache')).createSync(recursive: true);
      File(getFlutterExecutable(sdkPath)).writeAsStringSync('');
      File(
        p.join(sdkPath, 'bin', 'cache', 'flutter.version.json'),
      ).writeAsStringSync(
        '{"flutterVersion": "3.47.1", "dartSdkVersion": "3.13.1", "channel": "beta"}',
      );

      final settings = SettingsProvider(
        userFile: p.join(directory.path, SettingsProvider.fileName),
      );
      addTearDown(settings.dispose);

      final provider = FlutterSdkProvider();
      addTearDown(provider.dispose);
      provider.attachSettings(settings);
      await settled(provider);

      await provider.setCustomPath(sdkPath);
      expect(provider.lastError, isNull, reason: 'a real SDK folder was given');

      // The choice is written to settings.json, so it survives a restart.
      expect(settings.flutterSdkPath, sdkPath);
      expect(settings.flutterPreferredLocation, 'custom');

      final custom = provider.sdkAt(FlutterSdkLocation.custom);
      expect(custom, isNotNull);
      expect(custom!.flutterVersion, '3.47.1');
      expect(custom.channel, 'beta');
      expect(provider.sdkInfo?.location, FlutterSdkLocation.custom);
      expect(provider.preferredLocation, FlutterSdkLocation.custom);
    });

    test('refuses a folder that holds no flutter executable', () async {
      final directory = Directory.systemTemp.createTempSync('bird_sdk_empty');
      addTearDown(() => directory.deleteSync(recursive: true));

      final provider = FlutterSdkProvider();
      addTearDown(provider.dispose);
      await settled(provider);

      expect(await provider.setCustomPath(directory.path), isFalse);
      expect(provider.lastError, contains(directory.path));
      expect(provider.sdkAt(FlutterSdkLocation.custom), isNull);
    });

    test('refuses a channel switch while the SDK has local changes', () async {
      final directory = Directory.systemTemp.createTempSync('bird_sdk_dirty');
      addTearDown(() => directory.deleteSync(recursive: true));
      final sdkPath = p.join(directory.path, 'flutter');

      // A checkout that is a real git repo with one edited tracked file, which
      // is the state `flutter channel` walks into and refuses.
      Directory(p.join(sdkPath, 'bin', 'cache')).createSync(recursive: true);
      File(getFlutterExecutable(sdkPath)).writeAsStringSync('');
      File(
        p.join(sdkPath, 'bin', 'cache', 'flutter.version.json'),
      ).writeAsStringSync('{"flutterVersion": "3.47.1", "channel": "stable"}');
      final lock = File(p.join(sdkPath, 'pubspec.lock'))
        ..writeAsStringSync('a');
      for (final args in [
        ['init'],
        ['config', 'user.email', 'test@bird'],
        ['config', 'user.name', 'bird'],
        ['add', '.'],
        ['commit', '-m', 'sdk'],
      ]) {
        final result = Process.runSync('git', ['-C', sdkPath, ...args]);
        expect(
          result.exitCode,
          0,
          reason: 'git ${args.first}: ${result.stderr}',
        );
      }
      lock.writeAsStringSync('changed');

      final provider = FlutterSdkProvider();
      addTearDown(provider.dispose);
      await settled(provider);
      await provider.setCustomPath(sdkPath);
      expect(provider.sdkInfo?.sdkPath, sdkPath);

      expect(await provider.switchChannel('beta'), isFalse);
      expect(provider.lastError, contains('pubspec.lock'));
      expect(provider.lastError, contains('git -C $sdkPath checkout --'));
      // It must not have started the switch it knows would fail: no command
      // was run, so no line was logged with the '\$ ' prefix _runLogged adds.
      expect(
        provider.installLog.any((line) => line.startsWith(r'$ ')),
        isFalse,
      );
      expect(provider.isBusy, isFalse);
    });

    test(
      'keeps several versions side by side and switches between them',
      () async {
        final directory = Directory.systemTemp.createTempSync('bird_versions');
        addTearDown(() => directory.deleteSync(recursive: true));
        final root = p.join(directory.path, 'flutter-sdk');
        writeFakeSdk(p.join(root, '3.44.9'), '3.44.9');
        writeFakeSdk(p.join(root, '3.47.1'), '3.47.1');

        final settings = SettingsProvider(
          userFile: p.join(directory.path, SettingsProvider.fileName),
        );
        addTearDown(settings.dispose);

        final provider = FlutterSdkProvider(bundledRoot: root);
        addTearDown(provider.dispose);
        provider.attachSettings(settings);
        await settled(provider);

        // Newest first, and the newest is in charge until told otherwise.
        expect(provider.bundledSdks.map((sdk) => sdk.flutterVersion), [
          '3.47.1',
          '3.44.9',
        ]);
        expect(provider.sdkInfo?.flutterVersion, '3.47.1');

        await provider.selectVersion('3.44.9');
        expect(provider.sdkInfo?.flutterVersion, '3.44.9');
        expect(settings.flutterVersion, '3.44.9');
        expect(settings.flutterPreferredLocation, 'bundled');

        // The choice survives a restart, since it is read back from settings.
        final restarted = FlutterSdkProvider(bundledRoot: root);
        addTearDown(restarted.dispose);
        restarted.attachSettings(settings);
        await settled(restarted);
        expect(restarted.sdkInfo?.flutterVersion, '3.44.9');

        // A version that is pinned but missing is reported, not silently ignored.
        await settings.set('flutter.version', '3.40.0');
        await restarted.detectSdk();
        expect(restarted.missingPinnedVersion, '3.40.0');

        await restarted.deleteBundledSdk('3.44.9');
        expect(restarted.bundledSdks.map((sdk) => sdk.flutterVersion), [
          '3.47.1',
        ]);
        expect(Directory(p.join(root, '3.44.9')).existsSync(), isFalse);
      },
    );

    test(
      'moves an SDK installed under the old layout into a version folder',
      () async {
        final directory = Directory.systemTemp.createTempSync('bird_legacy');
        addTearDown(() => directory.deleteSync(recursive: true));
        final root = p.join(directory.path, 'flutter-sdk');
        // The layout before versions: the SDK sat directly in the root.
        writeFakeSdk(root, '3.47.1');

        final provider = FlutterSdkProvider(bundledRoot: root);
        addTearDown(provider.dispose);
        await settled(provider);

        expect(Directory(p.join(root, '3.47.1')).existsSync(), isTrue);
        expect(File(p.join(root, 'bin', 'flutter')).existsSync(), isFalse);
        expect(provider.bundledSdks.single.flutterVersion, '3.47.1');
      },
    );

    test('provider lifecycle and initial state', () {
      final provider = FlutterSdkProvider();

      expect(provider.isBusy, isFalse);
      expect(provider.downloadProgress, 0.0);
      expect(provider.lastDoctorOutput, isEmpty);

      provider.dispose();
    });
  });
}
