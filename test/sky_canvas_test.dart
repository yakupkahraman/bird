import 'package:bird/core/ui/nf_icons.dart';
import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/settings/settings_provider.dart';
import 'package:bird/features/settings/settings_store.dart';
import 'package:bird/features/sky/sky_canvas.dart';
import 'package:bird/features/sky/sky_node.dart';
import 'package:bird/features/sky/sky_provider.dart';
import 'package:bird/features/sky/sky_service.dart';
import 'package:bird/features/theme/theme_provider.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:file/memory.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Bird's own views stand in for files: they render without code_forge.
const account = 'bird://account';
const keymap = 'bird://keymap';

void main() {
  late EditorProvider editor;
  late SkyProvider sky;

  Future<void> pumpCanvas(WidgetTester tester) async {
    final fs = MemoryFileSystem();
    final settings = SettingsProvider(
      userFile: '/config/settings.json',
      store: SettingsStore(fileSystem: fs),
    );
    final workspace = WorkspaceProvider();
    editor = EditorProvider()
      ..openCustomTab(account)
      ..openCustomTab(keymap);
    sky =
        SkyProvider(
            service: SkyService(
              store: SettingsStore(fileSystem: fs),
              directory: '/config/sky',
            ),
          )
          ..attachWorkspace(workspace)
          ..attachEditor(editor);
    addTearDown(() {
      sky.dispose();
      editor.dispose();
      workspace.dispose();
      settings.dispose();
    });

    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider()..attachSettings(settings),
          ),
          ChangeNotifierProvider.value(value: editor),
          ChangeNotifierProvider.value(value: sky),
        ],
        child: const MaterialApp(home: Scaffold(body: SkyCanvas())),
      ),
    );
    // Past the delay before the first snapshots.
    await tester.pump(const Duration(seconds: 1));
  }

  Finder node(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(SkyNode));

  testWidgets('every open tab is a node, the selected one focused', (
    tester,
  ) async {
    await pumpCanvas(tester);

    expect(find.byType(SkyNode), findsNWidgets(2));
    expect(sky.focused, keymap);
    // Focused is drawn last, on top of the rest.
    final nodes = tester.widgetList<SkyNode>(find.byType(SkyNode));
    expect(nodes.last.title, 'Keymap');
  });

  testWidgets('pressing a node focuses it and selects its tab', (tester) async {
    await pumpCanvas(tester);

    await tester.tap(node('Account').first, warnIfMissed: false);
    await tester.pump();

    expect(sky.focused, account);
    expect(editor.selectedFilePath, account);
  });

  testWidgets('empty canvas and Escape let go of the focused node', (
    tester,
  ) async {
    await pumpCanvas(tester);

    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(sky.focused, isNull);

    await tester.tap(node('Account').first, warnIfMissed: false);
    await tester.pump();
    expect(sky.focused, account);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(sky.focused, isNull);
  });

  testWidgets('a node\'s close button closes its tab', (tester) async {
    await pumpCanvas(tester);

    await tester.tap(
      find.descendant(
        of: node('Account'),
        matching: find.byIcon(NfIcons.close),
      ),
    );
    await tester.pump();

    expect(editor.openFilePaths, [keymap]);
    expect(find.byType(SkyNode), findsOneWidget);
  });

  testWidgets('a trackpad pinch zooms, even over a scrolling node', (
    tester,
  ) async {
    await pumpCanvas(tester);
    final zoom = find.textContaining('%');
    expect(tester.widget<Text>(zoom).data, '100%');

    // Keymap is a list, so it scrolls like a live editor does: a scrollable
    // used to take the pinch for itself, and the canvas never zoomed.
    final at = tester.getCenter(node('Keymap'));
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(pointer.panZoomStart(at));
    await tester.sendEventToBinding(pointer.panZoomUpdate(at, scale: 1.5));
    await tester.sendEventToBinding(pointer.panZoomEnd());
    await tester.pump();

    expect(tester.widget<Text>(zoom).data, '150%');
  });

  testWidgets('a pinch on empty canvas zooms once, not twice', (tester) async {
    await pumpCanvas(tester);
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(pointer.panZoomStart(const Offset(20, 20)));
    await tester.sendEventToBinding(
      pointer.panZoomUpdate(const Offset(20, 20), scale: 1.5),
    );
    await tester.sendEventToBinding(pointer.panZoomEnd());
    await tester.pump();

    expect(tester.widget<Text>(find.textContaining('%')).data, '150%');
  });
}
