import 'dart:io';

import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:flutter_test/flutter_test.dart';

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

      workspace.toggleExpanded('${root.path}/sub');

      expect(editor.openFilePaths, ['bird://settings']);
    });

    test('expanding a folder does not notify the editor', () async {
      await workspace.openFolder(root.path);

      var notifications = 0;
      editor.addListener(() => notifications++);
      workspace.toggleExpanded('${root.path}/sub');

      // The whole point of splitting the two: walking the tree must not
      // rebuild the editor, which used to repaint on every expand.
      expect(notifications, 0);
    });
  });
}
