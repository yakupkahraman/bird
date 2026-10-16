import 'dart:async';
import 'dart:ui' show Offset, Rect, Size;

import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/sky/sky.dart';
import 'package:bird/features/sky/sky_service.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:flutter/foundation.dart';

/// Sky's side of the open tabs: where each sits on the canvas, and which one
/// is focused.
///
/// The tabs themselves stay [EditorProvider]'s — a node is a tab drawn
/// somewhere else — so switching between Sky and tabs loses nothing.
class SkyProvider extends ChangeNotifier {
  /// [service] and [saveDelay] are only passed by tests.
  SkyProvider({
    SkyService? service,
    this.saveDelay = const Duration(seconds: 1),
  }) : _service = service ?? SkyService();

  final SkyService _service;

  /// How long the layout must sit still before it is written: a drag moves a
  /// node sixty times a second.
  final Duration saveDelay;

  static const nodeSize = Size(720, 480);

  WorkspaceProvider? _workspace;
  EditorProvider? _editor;
  String? _root;
  SkyLayout _layout = SkyLayout();
  Timer? _save;

  /// Changed since the last write. Not the timer's state: by the time it
  /// fires and calls [_flush], it is no longer active.
  var _dirty = false;

  String? _focused;

  /// [EditorProvider.selections] when last seen: a new one focuses the
  /// selected tab, even the one the user just let go of.
  var _selections = 0;

  /// The focused node, the one live editor; null when all are snapshots.
  String? get focused => _focused;

  SkyView? get view => _layout.view;

  void attachWorkspace(WorkspaceProvider workspace) {
    if (identical(_workspace, workspace)) return;
    _workspace?.removeListener(_onWorkspaceChanged);
    _workspace = workspace..addListener(_onWorkspaceChanged);
    _onWorkspaceChanged();
  }

  void attachEditor(EditorProvider editor) {
    if (identical(_editor, editor)) return;
    _editor?.removeListener(_onEditorChanged);
    _editor = editor..addListener(_onEditorChanged);
    _onEditorChanged();
  }

  // Listeners rather than the proxy's update, which runs mid-build where
  // notifying is not allowed.
  void _onWorkspaceChanged() {
    final root = _workspace!.rootPath;
    if (root == _root) return;
    _flush();
    _root = root;
    _layout = root == null ? SkyLayout() : _service.load(root);
    notifyListeners();
  }

  void _onEditorChanged() {
    final editor = _editor!;
    final open = editor.openFilePaths;
    var changed = false;
    if (editor.selections != _selections) {
      _selections = editor.selections;
      _focused = editor.selectedFilePath;
      changed = true;
    }
    if (_focused != null && !open.contains(_focused)) {
      _focused = null;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// [path]'s node; a tab Sky has not seen yet is placed in [visible], the
  /// canvas area on screen, clear of the nodes already there.
  Rect rectOf(String path, Rect visible) =>
      _layout.nodes[path] ??= _place(visible);

  /// Centred in view if that spot is free, else the free neighbouring slot
  /// nearest the centre — beside or below what is already there, rather than
  /// pushed off screen.
  Rect _place(Rect visible) {
    final open = {...?_editor?.openFilePaths};
    final taken = [
      for (final MapEntry(:key, :value) in _layout.nodes.entries)
        if (open.contains(key)) value,
    ];
    final centre = Rect.fromCenter(
      center: visible.center,
      width: nodeSize.width,
      height: nodeSize.height,
    );
    const gap = 40.0;
    final slots =
        [
          for (var x = -3; x <= 3; x++)
            for (var y = -3; y <= 3; y++)
              centre.shift(
                Offset(x * (nodeSize.width + gap), y * (nodeSize.height + gap)),
              ),
        ]..sort(
          (a, b) => (a.center - visible.center).distance.compareTo(
            (b.center - visible.center).distance,
          ),
        );
    _scheduleSave();
    return slots.firstWhere(
      (slot) => slot.left >= 0 && slot.top >= 0 && !taken.any(slot.overlaps),
      orElse: () => centre,
    );
  }

  /// Makes [path] the live editor and the editor's selection; null leaves
  /// every node a snapshot.
  void focus(String? path) {
    if (path == _focused) return;
    _focused = path;
    if (path != null) _editor?.selectTab(path);
    notifyListeners();
  }

  void move(String path, Offset by) {
    final rect = _layout.nodes[path];
    if (rect == null) return;
    // Kept on the canvas, which starts at zero: past it a node can no longer
    // be grabbed.
    final moved = rect.shift(by);
    _layout.nodes[path] = moved.shift(
      Offset(moved.left < 0 ? -moved.left : 0, moved.top < 0 ? -moved.top : 0),
    );
    _scheduleSave();
    notifyListeners();
  }

  void resize(String path, Size by) {
    final rect = _layout.nodes[path];
    if (rect == null) return;
    _layout.nodes[path] = Rect.fromLTWH(
      rect.left,
      rect.top,
      (rect.width + by.width).clamp(280, 3000),
      (rect.height + by.height).clamp(180, 2400),
    );
    _scheduleSave();
    notifyListeners();
  }

  /// Remembers where the camera is. No notification: the canvas already shows
  /// it, and rebuilding every node per frame of a pan is what made Sky's first
  /// prototype crawl.
  void setView(SkyView view) {
    _layout.view = view;
    _scheduleSave();
  }

  void _scheduleSave() {
    if (_root == null) return;
    _dirty = true;
    _save?.cancel();
    if (saveDelay == Duration.zero) return _flush();
    _save = Timer(saveDelay, _flush);
  }

  /// Writes now if anything changed; also run when the folder changes or the
  /// app closes, so a pending write is not lost.
  void _flush() {
    _save?.cancel();
    final root = _root;
    if (!_dirty || root == null) return;
    _dirty = false;
    // One after another: two writes in flight share a temporary file, and the
    // older one finishing last would put the older layout back.
    final layout = _layout;
    _writing = _writing.then(
      (_) => _service.save(root, layout).catchError((Object e) {
        // A layout that does not save just opens fresh next time.
        debugPrint('Could not save the Sky layout: $e');
      }),
    );
  }

  Future<void> _writing = Future.value();

  @override
  void dispose() {
    _flush();
    _workspace?.removeListener(_onWorkspaceChanged);
    _editor?.removeListener(_onEditorChanged);
    super.dispose();
  }
}
