import 'dart:io';

import 'package:bird/core/result.dart';
import 'package:bird/features/editor/document_service.dart';
import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coverage here stops at the point a buffer would be built.
///
/// `EditorDocument` creates a `CodeForgeController`, which throws
/// `flutter_rust_bridge has not been initialized` outside a running app. So
/// every path that succeeds in opening or saving a real file is out of reach,
/// and what is tested is the tab bookkeeping and the failure paths — which
/// return before a controller is ever needed.

/// A folder with one subfolder in it, so the tree has something to expand.
Directory makeFolder() {
  final root = Directory.systemTemp.createTempSync('bird_editor');
  Directory('${root.path}/sub').createSync();
  return root;
}

void main() {
  test('an open internal tab survives a language server notification', () {
    final lsp = LspProvider();
    addTearDown(lsp.dispose);
    final files = EditorProvider()..openCustomTab('bird://settings');
    addTearDown(files.dispose);
    files.attachLsp(lsp);

    // Internal tabs have no controller, and rebinding used to assume one.
    // Reproduces: open the Settings tab, then open a folder.
    expect(lsp.stopServer, returnsNormally);
  });

  group('the editor follows the workspace', () {
    late Directory root;
    late WorkspaceProvider workspace;
    late EditorProvider editor;

    setUp(() {
      root = makeFolder();
      workspace = WorkspaceProvider();
      editor = EditorProvider()..attachWorkspace(workspace);
    });

    tearDown(() {
      editor.dispose();
      workspace.dispose();
      root.deleteSync(recursive: true);
    });

    test('opening another folder closes the tabs of the old one', () async {
      await workspace.openFolder(root.path);
      editor.openCustomTab('bird://settings');

      final other = makeFolder();
      addTearDown(() => other.deleteSync(recursive: true));
      await workspace.openFolder(other.path);

      expect(editor.openFilePaths, isEmpty);
      expect(editor.selectedFilePath, isNull);
    });

    test('re-opening the same folder keeps them', () async {
      await workspace.openFolder(root.path);
      editor.openCustomTab('bird://settings');

      await workspace.openFolder(root.path);

      expect(editor.openFilePaths, ['bird://settings']);
    });

    test('expanding a folder keeps them', () async {
      await workspace.openFolder(root.path);
      editor.openCustomTab('bird://settings');

      await workspace.toggleExpanded('${root.path}/sub');

      expect(editor.openFilePaths, ['bird://settings']);
    });

    test('expanding a folder does not notify the editor', () async {
      await workspace.openFolder(root.path);

      var notifications = 0;
      editor.addListener(() => notifications++);
      await workspace.toggleExpanded('${root.path}/sub');

      // The whole point of splitting the two: walking the tree must not
      // rebuild the editor, which used to repaint on every expand.
      expect(notifications, 0);
    });
  });

  group('a failure the user has to hear about', () {
    late MemoryFileSystem fs;
    late NotificationsProvider notifications;
    late EditorProvider editor;

    setUp(() {
      fs = MemoryFileSystem();
      fs.directory('/w').createSync();
      notifications = NotificationsProvider();
      editor = EditorProvider(service: DocumentService(fileSystem: fs))
        ..attachNotifications(notifications);
    });

    tearDown(() {
      editor.dispose();
      notifications.dispose();
    });

    test('opening a file that is not there fails', () async {
      final result = await editor.openFile('/w/gone.dart');

      expect(result, isA<Failed<void>>());
      expect((result as Failed).message, contains('gone.dart'));
      // Nothing half-opened: no tab, no selection.
      expect(editor.openFilePaths, isEmpty);
      expect(editor.selectedFilePath, isNull);
    });

    test('the failure reaches the user as a notification', () async {
      await editor.openFile('/w/gone.dart');

      // Without this it would be as silent as the debugPrint it replaced.
      final posted = notifications.items.single;
      expect(posted.severity, NotificationSeverity.error);
      expect(posted.message, contains('gone.dart'));
      // Bird's users are developers; the OS error is worth showing them.
      expect(posted.detail, contains('No such file'));
    });

    test('saving an internal view is not a failure', () async {
      editor.openCustomTab('bird://settings');

      expect(await editor.saveFile(), isA<Ok<void>>());
      expect(notifications.items, isEmpty);
    });
  });
}
