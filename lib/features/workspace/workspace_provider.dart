import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:bird/features/settings/settings_provider.dart';
import 'package:bird/features/workspace/file_tree_row.dart';
import 'package:bird/features/workspace/workspace_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// The open folder and the tree drawn from it.
///
/// Knows nothing about buffers: opening a folder notifies, and whoever holds
/// buffers for the old one closes them on its own. That is what keeps
/// expanding a folder from rebuilding the editor.
class WorkspaceProvider extends ChangeNotifier {
  /// [service] is only passed by tests, which must not touch the real disk.
  WorkspaceProvider({WorkspaceService? service})
    : _service = service ?? WorkspaceService();

  final WorkspaceService _service;

  String? _rootPath;

  /// Directory contents, read when a folder is expanded rather than on every
  /// build. Collapsing keeps the entry, so re-expanding shows it at once while
  /// a fresh read happens behind it.
  final Map<String, List<DirectoryEntry>> _listings = {};

  final Set<String> _expandedPaths = {};

  LspProvider? _lsp;
  SettingsProvider? _settings;

  String? get rootPath => _rootPath;

  /// Every row the explorer should draw, in order, already flattened.
  ///
  /// Rebuilt per read rather than cached: it is list walking with no disk in
  /// it, and a cache here would be one more thing to invalidate.
  List<FileTreeRow> get visibleRows {
    final rows = <FileTreeRow>[];
    if (_rootPath != null) _collectRows(_rootPath!, 0, rows);
    return rows;
  }

  void _collectRows(String directory, int depth, List<FileTreeRow> rows) {
    for (final entry in _listings[directory] ?? const <DirectoryEntry>[]) {
      final isExpanded =
          entry.isDirectory && _expandedPaths.contains(entry.path);

      rows.add(
        FileTreeRow(
          path: entry.path,
          name: p.basename(entry.path),
          isDirectory: entry.isDirectory,
          depth: depth,
          isExpanded: isExpanded,
          isIgnored: entry.isIgnored,
        ),
      );

      if (isExpanded) _collectRows(entry.path, depth + 1, rows);
    }
  }

  /// Called from `ChangeNotifierProxyProvider` on every build, so it must be
  /// idempotent.
  void attachSettings(SettingsProvider settings) {
    if (identical(_settings, settings)) return;
    _settings = settings;
    settings.setWorkspace(_rootPath);
  }

  /// Called from `ChangeNotifierProxyProvider` on every build, so it must be
  /// idempotent. Nothing is listened to here — the language server is told
  /// about a workspace, it does not report one back.
  void attachLsp(LspProvider lsp) => _lsp = lsp;

  bool isExpanded(String path) => _expandedPaths.contains(path);

  /// Completes once an expanded folder's contents are on screen.
  Future<void> toggleExpanded(String path) async {
    if (_expandedPaths.remove(path)) {
      notifyListeners();
      return;
    }
    _expandedPaths.add(path);
    // The chevron turns now; the children follow when the read lands.
    notifyListeners();
    await _readListing(path);
  }

  /// Re-reads [directory], but only if the tree is already showing it.
  ///
  /// Called after a write, so a file saved into an open folder appears without
  /// the user refreshing anything.
  Future<void> refreshListing(String directory) async {
    if (!_listings.containsKey(directory)) return;
    await _readListing(directory);
  }

  Future<void> _readListing(String directory) async {
    final root = _rootPath;
    List<DirectoryEntry> entries;
    try {
      entries = await _service.list(directory);
    } catch (e) {
      // An unreadable directory shows up empty rather than taking the app down.
      debugPrint('Failed to list $directory: $e');
      entries = const [];
    }
    // Another folder opened mid-read: the tree no longer reaches this path,
    // so storing it would only leave the old folder's entries behind.
    if (_rootPath != root) return;
    _listings[directory] = entries;
    notifyListeners();
  }

  /// Asks for a folder and opens it.
  Future<void> pickFolder() async {
    final selectedDirectory = await _service.promptForFolder();
    if (selectedDirectory == null) return;
    await openFolder(selectedDirectory);
  }

  /// Opens [selectedDirectory] as the workspace. Split from [pickFolder] so
  /// opening a folder does not require a file dialog to be on screen.
  Future<void> openFolder(String selectedDirectory) async {
    _rootPath = selectedDirectory;
    _expandedPaths.clear();
    _settings?.setWorkspace(selectedDirectory);

    _listings.clear();
    notifyListeners();

    // The tree and the language server load side by side.
    await Future.wait([
      _readListing(selectedDirectory),
      ?_lsp?.updateWorkspace(selectedDirectory),
    ]);
  }
}
