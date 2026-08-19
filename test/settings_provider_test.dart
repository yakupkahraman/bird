import 'dart:convert';
import 'dart:io';

import 'package:bird/providers/settings_provider.dart';
import 'package:bird/theme/theme_provider.dart';
import 'package:bird/ui/views/settings_view.dart';
import 'package:bird/widgets/my_switch.dart';
import 'package:bird/widgets/my_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

void main() {
  late Directory temporary;
  late String userFile;
  final providers = <SettingsProvider>[];

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('bird_settings_test');
    userFile = p.join(temporary.path, 'settings.json');
  });

  tearDown(() {
    for (final provider in providers) {
      provider.dispose();
    }
    providers.clear();
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  /// Disposed in tearDown, so the directory watcher never outlives its test.
  SettingsProvider open() {
    final provider = SettingsProvider(userFile: userFile);
    providers.add(provider);
    return provider;
  }

  void writeUser(Map<String, Object?> values) =>
      File(userFile).writeAsStringSync(jsonEncode(values));

  String writeWorkspace(Map<String, Object?> values) {
    final root = Directory(p.join(temporary.path, 'project'))
      ..createSync(recursive: true);
    final directory = Directory(
      p.join(root.path, SettingsProvider.workspaceDirectory),
    )..createSync(recursive: true);
    File(
      p.join(directory.path, SettingsProvider.fileName),
    ).writeAsStringSync(jsonEncode(values));
    return root.path;
  }

  group('SettingsProvider', () {
    test('falls back to the defaults when nothing is stored', () {
      final settings = open();

      expect(settings.editorFontSize, 13);
      expect(settings.editorTabSize, 2);
      expect(settings.editorWordWrap, isFalse);
      expect(settings.editorLineNumbers, isTrue);
      expect(settings.colorTheme, 'vs2015');
    });

    test('reads the user file', () {
      writeUser({'editor.fontSize': 18, 'workbench.colorTheme': 'monokai'});

      final settings = open();

      expect(settings.editorFontSize, 18);
      expect(settings.colorTheme, 'monokai');
      // Untouched keys still come from the defaults.
      expect(settings.editorTabSize, 2);
    });

    test('workspace settings win over the user ones', () {
      writeUser({'editor.tabSize': 4});
      final root = writeWorkspace({'editor.tabSize': 8});

      final settings = open()..setWorkspace(root);

      expect(settings.editorTabSize, 8);

      // Closing the folder gives the user's own value back.
      settings.setWorkspace(null);
      expect(settings.editorTabSize, 4);
    });

    test('a hand-edited value of the wrong type falls back', () {
      writeUser({'editor.tabSize': 'four', 'editor.wordWrap': 'yes'});

      final settings = open();

      expect(settings.editorTabSize, 2);
      expect(settings.editorWordWrap, isFalse);
    });

    test('a corrupt file does not stop the app from starting', () {
      File(userFile).writeAsStringSync('{ this is not json');

      expect(open().editorFontSize, 13);
    });

    test('set() persists and keeps keys Bird does not know about', () async {
      writeUser({'editor.fontSize': 15, 'some.future.key': 'keep me'});

      final settings = open();
      await settings.set('editor.tabSize', 4);

      expect(settings.editorTabSize, 4);

      final stored =
          jsonDecode(File(userFile).readAsStringSync()) as Map<String, dynamic>;
      expect(stored['editor.tabSize'], 4);
      expect(stored['editor.fontSize'], 15);
      expect(stored['some.future.key'], 'keep me');
    });

    test('writing leaves no temporary file behind', () async {
      await open().set('editor.fontSize', 20);

      expect(File('$userFile.tmp').existsSync(), isFalse);
      expect(File(userFile).existsSync(), isTrue);
    });

    test('set() notifies listeners', () async {
      final settings = open();
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.set('editor.fontSize', 16);

      expect(notifications, 1);
      expect(settings.editorFontSize, 16);
    });
  });

  group('where the file lives', () {
    test('macOS and Linux share ~/.config, Windows keeps %APPDATA%', () {
      final directory = SettingsProvider.defaultDirectory;
      final xdg = Platform.environment['XDG_CONFIG_HOME'];

      if (xdg != null && xdg.isNotEmpty) {
        expect(directory, p.join(xdg, 'bird'));
      } else if (Platform.isWindows) {
        expect(directory, endsWith(p.join('Bird')));
      } else {
        // Deliberately not ~/Library/Application Support on macOS: this file
        // belongs with the user's dotfiles.
        expect(directory, endsWith(p.join('.config', 'bird')));
      }
    });
  });

  group('the settings file itself', () {
    test('ensureUserFile creates it so there is something to open', () async {
      expect(File(userFile).existsSync(), isFalse);

      final path = await open().ensureUserFile();

      expect(path, userFile);
      expect(File(userFile).existsSync(), isTrue);
      // Empty rather than a copy of the defaults, which would freeze them.
      expect(jsonDecode(File(userFile).readAsStringSync()), isEmpty);
    });

    test('ensureUserFile leaves an existing file alone', () async {
      writeUser({'editor.fontSize': 19});

      await open().ensureUserFile();

      final stored =
          jsonDecode(File(userFile).readAsStringSync()) as Map<String, dynamic>;
      expect(stored['editor.fontSize'], 19);
    });

    test('there is no workspace file until a folder is open', () async {
      final settings = open();

      expect(settings.workspaceFile, isNull);
      expect(await settings.ensureWorkspaceFile(), isNull);
    });

    test('ensureWorkspaceFile creates .bird only when asked', () async {
      final root = Directory(p.join(temporary.path, 'untouched'))
        ..createSync(recursive: true);
      final settings = open()..setWorkspace(root.path);

      // Opening a folder must not litter it with a .bird directory.
      expect(
        Directory(
          p.join(root.path, SettingsProvider.workspaceDirectory),
        ).existsSync(),
        isFalse,
      );

      final path = await settings.ensureWorkspaceFile();

      expect(path, settings.workspaceFile);
      expect(File(path!).existsSync(), isTrue);
    });
  });

  group('across a restart', () {
    test('a changed setting is still there next time Bird starts', () async {
      await open().set('editor.tabSize', 8);

      // A second provider on the same file is what a restart amounts to.
      expect(open().editorTabSize, 8);
    });

    test(
      'the chosen theme survives, which is what issue #5 is about',
      () async {
        final theme = ThemeProvider()..attachSettings(open());
        await theme.setTheme('github');

        final restarted = ThemeProvider()..attachSettings(open());
        expect(restarted.themeName, 'github');
      },
    );
  });

  group('SettingsView', () {
    testWidgets('a switch changes the setting it is bound to', (tester) async {
      final settings = open();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider(
              create: (_) => ThemeProvider()..attachSettings(settings),
            ),
          ],
          child: const MaterialApp(home: SettingsView()),
        ),
      );

      expect(settings.editorWordWrap, isFalse);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(MyTile, 'Editor: Word Wrap'),
          matching: find.byType(MySwitch),
        ),
      );
      await tester.pump();

      expect(settings.editorWordWrap, isTrue);
    });

    testWidgets('shows where the settings file lives', (tester) async {
      final settings = open();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider(
              create: (_) => ThemeProvider()..attachSettings(settings),
            ),
          ],
          child: const MaterialApp(home: SettingsView()),
        ),
      );

      expect(find.text(settings.userFile), findsOneWidget);
      // No folder is open, so there is nothing to say about a workspace one.
      expect(find.text('Settings: Workspace'), findsNothing);
    });
  });
}
