import 'dart:io';

import 'package:bird/services/flutter_sdk_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FlutterSdkService', () {
    test('resolves default bundled SDK path under Application Support', () {
      final bundledPath = bundledSdkRoot;
      expect(bundledPath, isNotEmpty);
      expect(bundledPath, contains('flutter-sdk'));

      if (Platform.isMacOS) {
        expect(
          bundledPath,
          contains(p.join('Library', 'Application Support', 'Bird')),
        );
      } else if (Platform.isWindows) {
        expect(bundledPath.toLowerCase(), contains('bird'));
      } else {
        expect(bundledPath, contains('bird'));
      }
    });

    test('resolves correct flutter and dart executables', () {
      final sdkDir = p.join(Directory.systemTemp.path, 'mock_flutter_sdk');
      final flutterBin = getFlutterExecutable(sdkDir);
      final dartBin = getDartExecutable(sdkDir);

      if (Platform.isWindows) {
        expect(flutterBin, endsWith('flutter.bat'));
        expect(dartBin, endsWith('dart.exe'));
      } else {
        expect(flutterBin, endsWith('bin/flutter'));
        expect(dartBin, contains('dart'));
      }
    });

    test('reads free space off the volume an SDK would land on', () async {
      // The parsing is what matters here: a wrong column would either refuse
      // every install or refuse none.
      final free = await freeBytes(Directory.systemTemp.path);
      expect(free, isNotNull);
      expect(free, greaterThan(0));

      // A path that does not exist yet still answers, from its nearest parent:
      // the same volume, give or take whatever the machine wrote meanwhile.
      final missing = await freeBytes(
        p.join(Directory.systemTemp.path, 'bird_no_such_dir', 'nested'),
      );
      expect(missing, isNotNull);
      expect(missing, closeTo(free!, free * 0.05));
    });
  });
}
