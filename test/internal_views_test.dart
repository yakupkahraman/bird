import 'dart:io';

import 'package:bird/providers/file_provider.dart';
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
  String openPath,
) async {
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
  });
}
