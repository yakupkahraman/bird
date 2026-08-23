import 'dart:io';

import 'package:bird/models/flutter_sdk.dart';
import 'package:bird/services/flutter_sdk_service.dart';
import 'package:bird/providers/flutter_sdk_provider.dart';
import 'package:bird/providers/settings_provider.dart';
import 'package:bird/ui/views/settings/flutter_sdk_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

/// A directory that looks enough like a Flutter SDK for detection to accept it.
///
/// Its `flutter` is a real script, so the commands the page runs have something
/// to print; detection itself reads the version file and never runs it.
String fakeSdk(Directory parent) {
  final sdkPath = p.join(parent.path, 'flutter');
  Directory(p.join(sdkPath, 'bin', 'cache')).createSync(recursive: true);
  final executable = File(getFlutterExecutable(sdkPath));
  if (Platform.isWindows) {
    executable.writeAsStringSync('@echo [ok] Flutter is fine\r\n');
  } else {
    executable.writeAsStringSync('#!/bin/sh\necho "[ok] Flutter is fine"\n');
    Process.runSync('chmod', ['+x', executable.path]);
  }
  File(
    p.join(sdkPath, 'bin', 'cache', 'flutter.version.json'),
  ).writeAsStringSync(
    '{"flutterVersion": "3.47.1", "dartSdkVersion": "3.13.1", "channel": "beta"}',
  );
  return sdkPath;
}

/// Detection spawns processes, so let the scan in flight finish.
Future<void> settle(WidgetTester tester, FlutterSdkProvider provider) async {
  while (provider.isDetecting) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
}

void main() {
  testWidgets('offers every SDK source and marks the active one', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('bird_sdk_view');
    addTearDown(() => directory.deleteSync(recursive: true));
    final settings = SettingsProvider(
      userFile: p.join(directory.path, SettingsProvider.fileName),
    );
    addTearDown(settings.dispose);

    final provider = FlutterSdkProvider();
    addTearDown(provider.dispose);
    provider.attachSettings(settings);
    await settle(tester, provider);
    await tester.runAsync(() => provider.setCustomPath(fakeSdk(directory)));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: provider,
            child: const FlutterSdkManager(),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final source in FlutterSdkManager.sources) {
      expect(find.text(source.label), findsOneWidget);
    }
    // No bundled version is installed here, so the shelf offers to add one.
    expect(find.text('Install a Flutter version'), findsOneWidget);
    // The pinned source is named on its row and again on the active SDK card.
    expect(find.text('${FlutterSdkLocation.custom.label}  (pinned)'), findsOne);
    expect(find.text('Flutter 3.47.1'), findsOneWidget);
    // Further down the page, past the active SDK card and the channel row.
    await tester.scrollUntilVisible(
      find.text('Run Flutter Doctor'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Run Flutter Doctor'), findsOneWidget);
  });

  testWidgets('shows what a command printed above the settings, not below', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('bird_sdk_doctor');
    addTearDown(() => directory.deleteSync(recursive: true));

    final provider = FlutterSdkProvider();
    addTearDown(provider.dispose);
    await settle(tester, provider);
    await tester.runAsync(() => provider.setCustomPath(fakeSdk(directory)));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: provider,
            child: const FlutterSdkManager(),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.runAsync(provider.runDoctor);
    await tester.pump();

    // The report and the list of sources are both on screen, report first.
    final report = tester.getTopLeft(find.text('Flutter Doctor')).dy;
    final sources = tester.getTopLeft(find.text('SDK Source')).dy;
    expect(report, lessThan(sources));
    expect(find.text('[ok] Flutter is fine'), findsOneWidget);

    // And it can be dismissed once read.
    await tester.tap(find.byTooltip('Dismiss output'));
    await tester.pump();
    expect(find.text('Flutter Doctor'), findsNothing);
  });
}
