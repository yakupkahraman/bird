import 'dart:ui';

import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/settings/settings_store.dart';
import 'package:bird/features/sky/sky_provider.dart';
import 'package:bird/features/sky/sky_service.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:bird/features/workspace/workspace_service.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryFileSystem fs;
  late SkyService service;
  late WorkspaceProvider workspace;
  late EditorProvider editor;
  late SkyProvider sky;
  const screen = Rect.fromLTWH(0, 0, 1600, 1000);

  SkyProvider attach() =>
      SkyProvider(service: service, saveDelay: Duration.zero)
        ..attachWorkspace(workspace)
        ..attachEditor(editor);

  setUp(() async {
    fs = MemoryFileSystem();
    fs.directory('/a').createSync();
    fs.directory('/b').createSync();
    service = SkyService(
      store: SettingsStore(fileSystem: fs),
      directory: '/config/sky',
    );
    workspace = WorkspaceProvider(service: WorkspaceService(fileSystem: fs));
    await workspace.openFolder('/a');
    editor = EditorProvider();
    sky = attach();
  });

  tearDown(() {
    sky.dispose();
    editor.dispose();
    workspace.dispose();
  });

  test('a new node lands in view, clear of the open ones', () {
    editor
      ..openCustomTab('bird://settings')
      ..openCustomTab('bird://keymap');

    final first = sky.rectOf('bird://settings', screen);
    final second = sky.rectOf('bird://keymap', screen);

    expect(screen.contains(first.center), isTrue);
    expect(first.overlaps(second), isFalse);
  });

  test('focus follows a newly selected tab, but not back after letting go', () {
    editor.openCustomTab('bird://settings');
    expect(sky.focused, 'bird://settings');

    sky.focus(null);
    // The editor notifies for plenty besides selection; none of it should
    // drag focus back.
    editor.openCustomTab('bird://settings');
    expect(sky.focused, isNull);

    editor.openCustomTab('bird://keymap');
    expect(sky.focused, 'bird://keymap');
  });

  test('focusing a node selects its tab', () {
    editor
      ..openCustomTab('bird://settings')
      ..openCustomTab('bird://keymap');

    sky.focus('bird://settings');

    expect(editor.selectedFilePath, 'bird://settings');
  });

  test('a closed tab reopens where it was left', () {
    editor.openCustomTab('bird://settings');
    sky.rectOf('bird://settings', screen);
    sky.move('bird://settings', const Offset(300, 120));
    final moved = sky.rectOf('bird://settings', screen);

    editor.closeTab('bird://settings');
    editor.openCustomTab('bird://settings');

    expect(sky.rectOf('bird://settings', screen), moved);
  });

  test('the layout is kept per folder', () async {
    editor.openCustomTab('bird://settings');
    sky.rectOf('bird://settings', screen);
    sky.move('bird://settings', const Offset(500, 0));
    sky.setView((scale: 0.5, x: 10, y: 20));
    final moved = sky.rectOf('bird://settings', screen);
    await pumpEventQueue();

    // Another folder starts empty...
    await workspace.openFolder('/b');
    expect(sky.view, isNull);
    final elsewhere = sky.rectOf('bird://settings', screen);
    expect(elsewhere, isNot(moved));

    // ...and coming back, or starting the app again, finds it as left.
    await workspace.openFolder('/a');
    expect(sky.rectOf('bird://settings', screen), moved);
    sky.dispose();
    sky = attach();
    expect(sky.rectOf('bird://settings', screen), moved);
    expect(sky.view, (scale: 0.5, x: 10.0, y: 20.0));
  });
}
