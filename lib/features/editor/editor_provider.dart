import 'dart:async';
import 'dart:io';

import 'package:bird/features/editor/editor_document.dart';
import 'package:bird/features/editor/languages.dart';
import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:code_forge/code_forge.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// The open buffers and the tabs above them.
class EditorProvider extends ChangeNotifier {
  /// Tab order. Holds `bird://` views as well as files, so this is the one
  /// place a tab can exist without a buffer behind it.
  final List<String> _tabs = [];

  /// The state of every file-backed tab, keyed by path. A tab with no entry
  /// here has no buffer — that is the whole distinction, and it is the data
  /// answering it rather than a `bird://` string match.
  final Map<String, EditorDocument> _docs = {};

  String? _selectedFilePath;

  /// Watches are per directory, not per file: an editor that saves by writing a
  /// temporary file and renaming it over the original — Bird's own settings do
  /// exactly that — replaces the inode, and a watch on the file dies with it.
  final Map<String, StreamSubscription<FileSystemEvent>> _watchers = {};

  LspProvider? _lsp;
  WorkspaceProvider? _workspace;

  /// The folder these buffers were opened from.
  ///
  /// Compared on every workspace notification because expanding a folder
  /// notifies too, and that must not close anything.
  String? _boundRoot;

  List<String> get openFilePaths => List.unmodifiable(_tabs);
  String? get selectedFilePath => _selectedFilePath;

  /// True while [path] holds edits that are not on disk.
  bool isDirty(String path) => _docs[path]?.isDirty ?? false;

  /// True while [path] changed on disk under unsaved edits.
  bool hasConflict(String path) => _docs[path]?.hasConflict ?? false;

  /// The state behind a file-backed tab, or null for a `bird://` view.
  EditorDocument? documentFor(String path) => _docs[path];

  CodeForgeController get currentController =>
      _docs[_selectedFilePath]?.controller ?? _defaultController;

  /// Built on first use: creating a controller initializes code_forge's native
  /// library, which a session that never opens an editor must not require.
  CodeForgeController? _defaultControllerInstance;
  CodeForgeController get _defaultController =>
      _defaultControllerInstance ??= CodeForgeController();

  /// Called from `ChangeNotifierProxyProvider` on every build, so it must be
  /// idempotent.
  void attachLsp(LspProvider lsp) {
    if (identical(_lsp, lsp)) return;
    _lsp?.removeListener(_rebindControllers);
    _lsp = lsp;
    lsp.addListener(_rebindControllers);
  }

  /// Called from `ChangeNotifierProxyProvider` on every build, so it must be
  /// idempotent.
  void attachWorkspace(WorkspaceProvider workspace) {
    if (identical(_workspace, workspace)) return;
    _workspace?.removeListener(_onWorkspaceChanged);
    _workspace = workspace;
    _boundRoot = workspace.rootPath;
    workspace.addListener(_onWorkspaceChanged);
  }

  /// Drops everything when the workspace moves.
  ///
  /// Tabs belong to the folder they were opened from, and their controllers
  /// would keep talking to a language server that is about to be replaced.
  /// Re-opening the same folder is not a move and keeps the tabs.
  void _onWorkspaceChanged() {
    final root = _workspace?.rootPath;
    if (root == _boundRoot) return;
    _boundRoot = root;
    _closeAll();
  }

  void _closeAll() {
    if (_tabs.isEmpty && _docs.isEmpty) return;
    for (final doc in _docs.values) {
      doc.dispose();
    }
    _docs.clear();
    _tabs.clear();
    _selectedFilePath = null;
    _pruneWatchers();
    notifyListeners();
  }

  /// Re-creates controllers so files opened before the language server was
  /// ready still get it. `lspConfig` is final on the controller, so there is no
  /// way to swap it in place; the text is carried over.
  void _rebindControllers() {
    var changed = false;
    for (final doc in _docs.values) {
      final config = _lsp?.getLspConfigForFile(doc.path);
      if (identical(doc.controller.lspConfig, config)) continue;

      final text = doc.controller.text;
      doc.controller.dispose();
      doc.controller = CodeForgeController(lspConfig: config)..text = text;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> openFile(String path) async {
    try {
      if (!_tabs.contains(path)) {
        final content = await File(path).readAsString();

        // The file may have been clicked again while we were reading it.
        if (!_tabs.contains(path)) {
          _docs[path] = EditorDocument(
            path: path,
            text: content,
            language: Languages.forPath(path),
            lspConfig: _lsp?.getLspConfigForFile(path),
          );
          _tabs.add(path);
          _watchDirectory(p.dirname(path));
        }
      }

      _selectedFilePath = path;
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to read file: $e");
    }
  }

  void openCustomTab(String path) {
    if (!_tabs.contains(path)) {
      _tabs.add(path);
    }
    _selectedFilePath = path;
    notifyListeners();
  }

  void selectTab(String path) {
    if (_tabs.contains(path)) {
      _selectedFilePath = path;
      notifyListeners();
    }
  }

  void closeTab(String path) {
    final index = _tabs.indexOf(path);
    if (index != -1) {
      _tabs.removeAt(index);
      _docs.remove(path)?.dispose();
      _pruneWatchers();

      if (_selectedFilePath == path) {
        if (_tabs.isNotEmpty) {
          final newIndex = index.clamp(0, _tabs.length - 1);
          _selectedFilePath = _tabs[newIndex];
        } else {
          _selectedFilePath = null;
        }
      }
      notifyListeners();
    }
  }

  /// Watches [directory] for changes to the files open from it.
  ///
  /// One subscription per directory, however many files are open in it.
  void _watchDirectory(String directory) {
    if (_watchers.containsKey(directory)) return;
    try {
      _watchers[directory] = Directory(
        directory,
      ).watch().listen(_onFileSystemEvent);
    } catch (e) {
      // Watching is a convenience; editing still works without it.
      debugPrint('Failed to watch $directory: $e');
    }
  }

  /// Drops watches on directories no open file lives in any more.
  void _pruneWatchers() {
    final needed = _docs.keys.map(p.dirname).toSet();

    for (final directory in _watchers.keys.toList()) {
      if (needed.contains(directory)) continue;
      _watchers.remove(directory)?.cancel();
    }
  }

  void _onFileSystemEvent(FileSystemEvent event) {
    // A rename reports the old path; the new one arrives as the destination.
    for (final path in {
      event.path,
      if (event is FileSystemMoveEvent) event.destination,
    }) {
      if (path != null && _docs.containsKey(path)) _reloadFromDisk(path);
    }
  }

  /// Brings an open file back in line with what is on disk.
  ///
  /// A buffer with no unsaved edits is replaced silently — that is what makes a
  /// settings change show up in an open settings.json. A buffer with edits is
  /// left alone and flagged instead, because reloading would discard work the
  /// user has not saved.
  /// [force] is the user answering the conflict: take the file, edits and all.
  /// Without it, unsaved work is never overwritten.
  Future<void> _reloadFromDisk(String path, {bool force = false}) async {
    final doc = _docs[path];
    if (doc == null) return;

    try {
      final file = File(path);
      // A deleted file leaves the buffer as the only copy left; keep it.
      if (!file.existsSync()) return;

      final content = await file.readAsString();

      if (!force) {
        if (content == doc.savedText) return;
        if (doc.isDirty) {
          if (!doc.hasConflict) {
            doc.hasConflict = true;
            notifyListeners();
          }
          return;
        }
      }

      doc.controller.text = content;
      doc.savedText = content;
      doc.hasConflict = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reload $path: $e');
    }
  }

  /// Takes the version on disk, discarding the unsaved edits.
  Future<void> reloadFromDisk(String path) =>
      _reloadFromDisk(path, force: true);

  /// Keeps the buffer as it is; the next save overwrites what is on disk.
  void keepMine(String path) {
    final doc = _docs[path];
    if (doc == null || !doc.hasConflict) return;
    doc.hasConflict = false;
    notifyListeners();
  }

  Future<void> saveFile() async {
    // A tab with no document — an internal view — has nothing to write. A null
    // selection is different: that is a new file, handled just below.
    if (_selectedFilePath != null && !_docs.containsKey(_selectedFilePath)) {
      return;
    }

    if (_selectedFilePath == null) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save New File',
        fileName: 'new_chick.txt',
        allowedExtensions: ['txt'],
        type: FileType.custom,
      );

      if (outputFile == null) return;
      _selectedFilePath = outputFile;
      _tabs.add(outputFile);
      _docs[outputFile] = EditorDocument(path: outputFile, text: '');
    }

    try {
      final path = _selectedFilePath!;
      final doc = _docs[path];
      final text = doc?.controller.text ?? currentController.text;

      // Recorded before the write, so the watch event our own save triggers
      // arrives to a provider that already knows this content.
      doc?.savedText = text;
      doc?.hasConflict = false;
      await File(path).writeAsString(text);
      _watchDirectory(p.dirname(path));

      // A new file has to show up in the tree it was saved into.
      _workspace?.refreshListing(p.dirname(path));

      notifyListeners();
    } catch (e) {
      debugPrint("Failed to save file: $e");
    }
  }

  @override
  void dispose() {
    for (final watcher in _watchers.values) {
      watcher.cancel();
    }
    _watchers.clear();
    _lsp?.removeListener(_rebindControllers);
    _workspace?.removeListener(_onWorkspaceChanged);
    for (final doc in _docs.values) {
      doc.dispose();
    }
    _defaultControllerInstance?.dispose();
    super.dispose();
  }
}
