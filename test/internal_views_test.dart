import 'dart:io';

import 'package:bird/providers/file_provider.dart';
import 'package:bird/services/flutter_sdk_service.dart';
import 'package:bird/providers/flutter_sdk_provider.dart';
import 'package:bird/providers/lsp_provider.dart';
import 'package:bird/providers/settings_provider.dart';
import 'package:bird/theme/theme_provider.dart';
import 'package:bird/ui/bars/bottom_bar.dart';
import 'package:bird/ui/panels/code_panel.dart';
import 'package:bird/ui/views/internal_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

/// Renders [child] with the providers the IDE chrome reads, with [openPath]
/// already selected as a tab.
Future<void> pumpWithTab(
  WidgetTester tester,
  Widget child,
  String openPath, {
  FlutterSdkProvider? sdkProvider,
}) async {
  final fileProvider = FileProvider()..openCustomTab(openPath);
  addTearDown(fileProvider.dispose);

  // A throwaway path, so a test run never reads or writes the real config.
  final directory = Directory.systemTemp.createTempSync('bird_views_test');
  addTearDown(() => directory.deleteSync(recursive: true));
  final settings = SettingsProvider(
    userFile: p.join(directory.path, SettingsProvider.fileName),
  );
  addTearDown(settings.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..attachSettings(settings),
        ),
        if (sdkProvider case final provider?)
          ChangeNotifierProvider.value(value: provider)
        else
          ChangeNotifierProvider(create: (_) => FlutterSdkProvider()),
        ChangeNotifierProvider(create: (_) => LspProvider()),
        ChangeNotifierProvider.value(value: fileProvider),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

void main() {
  group('registry', () {
    test('every view is reachable by its path', () {
      for (final view in InternalViews.values) {
        expect(InternalViews.of(view.path), same(view));
        expect(view.path, 'bird://${view.id}');
      }
    });

    test('ids are unique', () {
      final ids = InternalViews.values.map((view) => view.id).toSet();
      expect(ids, hasLength(InternalViews.values.length));
    });

    test('unknown and regular paths resolve to null', () {
      expect(InternalViews.of('bird://nope'), isNull);
      expect(InternalViews.of('/tmp/main.dart'), isNull);
    });

    test('menu groups hold every view, with no duplicates across groups', () {
      final grouped = InternalViews.menuGroups.expand((group) => group);
      expect(grouped, InternalViews.values);
    });
  });

  group('CodePanel', () {
    for (final view in InternalViews.values) {
      testWidgets('renders ${view.id} and titles its tab', (tester) async {
        await pumpWithTab(tester, const CodePanel(), view.path);

        expect(find.byWidget(view.view), findsOneWidget);
        expect(find.text(view.title), findsWidgets);
      });
    }
  });

  group('BottomBar', () {
    testWidgets('labels an internal tab with its title', (tester) async {
      await pumpWithTab(tester, const BottomBar(), InternalViews.themes.path);

      expect(find.text('Bird > Themes'), findsOneWidget);
    });

    testWidgets('its SDK menu starts nothing long-running on the spot', (
      tester,
    ) async {
      final directory = Directory.systemTemp.createTempSync('bird_bar_test');
      addTearDown(() => directory.deleteSync(recursive: true));

      // A directory detection accepts, so the status bar has an SDK to show.
      final sdkPath = p.join(directory.path, 'flutter');
      Directory(p.join(sdkPath, 'bin', 'cache')).createSync(recursive: true);
      File(getFlutterExecutable(sdkPath)).writeAsStringSync('');
      File(
        p.join(sdkPath, 'bin', 'cache', 'flutter.version.json'),
      ).writeAsStringSync(
        '{"flutterVersion": "3.47.1", "dartSdkVersion": "3.13.1", '
        '"channel": "beta"}',
      );

      final sdkProvider = FlutterSdkProvider();
      addTearDown(sdkProvider.dispose);
      while (sdkProvider.isDetecting) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      await tester.runAsync(() => sdkProvider.setCustomPath(sdkPath));

      await pumpWithTab(
        tester,
        const BottomBar(),
        InternalViews.themes.path,
        sdkProvider: sdkProvider,
      );
      await tester.tap(find.byTooltip('Flutter 3.47.1 (beta) • System'));
      await tester.pumpAndSettle();

      // Switching channel is a multi-minute download with nothing to watch from
      // here; it lives in settings, where its progress is on screen.
      expect(find.textContaining('Channel:'), findsNothing);
      expect(find.text('Manage Flutter SDK...'), findsOneWidget);
    });
  });
}
