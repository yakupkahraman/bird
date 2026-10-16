import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:bird/core/ui/file_icon.dart';
import 'package:bird/core/ui/mini_button.dart';
import 'package:bird/core/ui/nf_icons.dart';
import 'package:bird/features/editor/code_panel.dart';
import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/editor/file_editor.dart';
import 'package:bird/features/internal_views/internal_views.dart';
import 'package:bird/features/sky/sky.dart';
import 'package:bird/features/sky/sky_node.dart';
import 'package:bird/features/sky/sky_provider.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

/// The editor area as an infinite canvas: every open tab a node on it.
///
/// Only the focused node is live. The rest show a snapshot of themselves,
/// which is what keeps a canvas of dozens of editors smooth to pan.
class SkyCanvas extends StatefulWidget {
  const SkyCanvas({super.key});

  /// Wide enough that nobody reaches the edge; nodes cannot go left or above
  /// its origin.
  static const extent = 20000.0;

  @override
  State<SkyCanvas> createState() => _SkyCanvasState();
}

class _SkyCanvasState extends State<SkyCanvas> {
  late final SkyProvider _sky = context.read<SkyProvider>();
  late final _view = TransformationController(_matrix(_sky.view));
  final _boundaries = <String, GlobalKey>{};
  final _snapshots = <String, ui.Image>{};
  var _size = Size.zero;

  /// Holds the keyboard after a press on a node or the canvas, so Escape
  /// reaches this canvas: keys travel up from whatever has focus, and a press
  /// on a snapshot or empty space gives focus to nothing inside it.
  final _keyboard = FocusNode(debugLabel: 'Sky');

  /// The focus as this canvas last drew it, to tell a focus change made here
  /// from one made elsewhere — a file opened from the explorer or Hawk.
  String? _drawnFocus;

  double get _scale => _view.value.getMaxScaleOnAxis();

  Rect get _visible =>
      MatrixUtils.inverseTransformRect(_view.value, Offset.zero & _size);

  static Matrix4 _matrix(SkyView? view) => view == null
      ? Matrix4.identity()
      : (Matrix4.identity()
          ..translateByDouble(view.x, view.y, 0, 1)
          ..scaleByDouble(view.scale, view.scale, 1, 1));

  @override
  void initState() {
    super.initState();
    _drawnFocus = _sky.focused;
    _sky.addListener(_onSky);
    // Remembered, not rebuilt on: panning must not rebuild the nodes.
    _view.addListener(() {
      final m = _view.value;
      _sky.setView((
        scale: m.getMaxScaleOnAxis(),
        x: m.getTranslation().x,
        y: m.getTranslation().y,
      ));
    });
    // Late enough for the editors to have highlighted what they show.
    Future.delayed(const Duration(milliseconds: 800), _shootUnshot);
  }

  @override
  void dispose() {
    _sky.removeListener(_onSky);
    _view.dispose();
    _keyboard.dispose();
    for (final image in _snapshots.values) {
      image.dispose();
    }
    super.dispose();
  }

  /// Focus moved elsewhere: photograph the node being left while it is still
  /// live, and bring the new one into view.
  void _onSky() {
    final focused = _sky.focused;
    if (focused == _drawnFocus) return;
    if (_drawnFocus case final left?) _shoot(left);
    _drawnFocus = focused;
    if (focused != null) _reveal(focused);
  }

  /// A press on the canvas: no panning, the user is looking at it already.
  void _focus(String? path) {
    // An editor pressed into takes the keyboard back right after.
    _keyboard.requestFocus();
    if (path == _drawnFocus) return;
    if (_drawnFocus case final left?) _shoot(left);
    _drawnFocus = path;
    _sky.focus(path);
  }

  Future<void> _shoot(String path) async {
    final boundary =
        _boundaries[path]?.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || !mounted) return;
    try {
      // At the zoom it is seen at, so a snapshot is as sharp as the editor.
      final image = await boundary.toImage(
        pixelRatio: (MediaQuery.devicePixelRatioOf(context) * _scale).clamp(
          1,
          4,
        ),
      );
      if (!mounted) return image.dispose();
      _snapshots.remove(path)?.dispose();
      _snapshots[path] = image;
      setState(() {});
    } catch (e) {
      // An offstage node has nothing painted to photograph; it keeps its
      // last snapshot.
      debugPrint('Sky could not snapshot $path: $e');
    }
  }

  void _shootUnshot() {
    if (!mounted) return;
    for (final path in context.read<EditorProvider>().openFilePaths) {
      if (path != _sky.focused && !_snapshots.containsKey(path)) _shoot(path);
    }
  }

  /// Centres [path]'s node in view, keeping the zoom.
  void _reveal(String path) {
    if (_size.isEmpty) return;
    final rect = _sky.rectOf(path, _visible);
    final scale = _scale;
    _view.value = Matrix4.identity()
      ..translateByDouble(
        _size.width / 2 - rect.center.dx * scale,
        _size.height / 2 - rect.center.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// Zooms by [factor] about [focal], a point in the viewport.
  void _zoomAt(Offset focal, double factor) {
    final scale = _scale;
    final next = (scale * factor).clamp(0.1, 3.0);
    if (next == scale) return;
    final by = next / scale;
    _view.value = Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(by, by, 1, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1)
      ..multiply(_view.value);
  }

  /// The trackpad pinch so far, which arrives as a running total.
  var _pinch = 1.0;

  /// Zooms and pans so every open node is in view.
  void _fitAll(List<String> paths) {
    if (paths.isEmpty || _size.isEmpty) return;
    final bounds = paths
        .map((path) => _sky.rectOf(path, _visible))
        .reduce((a, b) => a.expandToInclude(b))
        .inflate(40);
    final scale = math
        .min(_size.width / bounds.width, _size.height / bounds.height)
        .clamp(0.1, 1.0);
    _view.value = Matrix4.identity()
      ..translateByDouble(
        _size.width / 2 - bounds.center.dx * scale,
        _size.height / 2 - bounds.center.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    final sky = context.watch<SkyProvider>();
    final paths = editor.openFilePaths;
    final hasFolder = context.select<WorkspaceProvider, bool>(
      (workspace) => workspace.rootPath != null,
    );
    if (!hasFolder && paths.isEmpty) return const CodePanel();

    _boundaries.removeWhere((path, _) => !paths.contains(path));
    for (final path in [..._snapshots.keys]) {
      if (!paths.contains(path)) _snapshots.remove(path)!.dispose();
    }
    final focused = sky.focused;
    // The focused node is drawn last, so it sits on top.
    final order = [...paths.where((path) => path != focused), ?focused];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _focus(null),
      },
      child: Focus(
        focusNode: _keyboard,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _size = constraints.biggest;
            final visible = _visible;
            return Stack(
              children: [
                // Zoom is handled here rather than by InteractiveViewer, which
                // competes for it in the gesture arena — and loses to any
                // scrollable under the pointer, the live editor included, so
                // a pinch over a node did nothing. A Listener sees every event.
                Listener(
                  onPointerPanZoomStart: (_) => _pinch = 1,
                  onPointerPanZoomUpdate: (event) {
                    _zoomAt(event.localPosition, event.scale / _pinch);
                    _pinch = event.scale;
                  },
                  // A mouse wheel still zooms, except over something that
                  // scrolls: the resolver hands the event to the innermost
                  // claimant, so an editor keeps its wheel.
                  onPointerSignal: (event) {
                    if (event is! PointerScrollEvent ||
                        event.kind == PointerDeviceKind.trackpad) {
                      return;
                    }
                    GestureBinding.instance.pointerSignalResolver.register(
                      event,
                      (_) => _zoomAt(
                        event.localPosition,
                        math.exp(-event.scrollDelta.dy / 200),
                      ),
                    );
                  },
                  child: InteractiveViewer(
                    transformationController: _view,
                    scaleEnabled: false,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: SizedBox.square(
                      dimension: SkyCanvas.extent,
                      child: Stack(
                        children: [
                          // A press on empty canvas lets go of the focused
                          // node.
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _focus(null),
                            ),
                          ),
                          for (final path in order)
                            Positioned.fromRect(
                              // Keyed: reordering must move each node's state
                              // with it, not hand it to whichever sits there
                              // now.
                              key: ValueKey(path),
                              rect: sky.rectOf(path, visible),
                              child: _node(editor, path, path == focused),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Row(
                    spacing: 6,
                    children: [
                      AnimatedBuilder(
                        animation: _view,
                        builder: (context, _) => Text(
                          '${(_scale * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      MiniButton(
                        tooltip: 'Fit all',
                        icon: NfIcons.layout,
                        onPressed: () => _fitAll(paths),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _node(EditorProvider editor, String path, bool isFocused) {
    final view = InternalViews.of(path);
    final document = editor.documentFor(path);
    return SkyNode(
      title: view?.title ?? p.basename(path),
      icon: view == null
          ? FileIcon(path, size: 13)
          : Icon(
              view.icon,
              size: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
      content: switch ((view, document)) {
        (final view?, _) => view.view,
        (_, final document?) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (editor.hasConflict(path)) DiskConflictBar(path: path),
            Expanded(
              child: FileEditor(
                key: ValueKey(path),
                document: document,
                autoFocus: false,
              ),
            ),
          ],
        ),
        _ => const SizedBox.shrink(),
      },
      boundary: _boundaries.putIfAbsent(path, GlobalKey.new),
      snapshot: _snapshots[path],
      isFocused: isFocused,
      isDirty: editor.isDirty(path),
      scale: () => _scale,
      onFocus: () => _focus(path),
      onMove: (by) => _sky.move(path, by),
      onResize: (by) => _sky.resize(path, by),
      onClose: () => editor.closeTab(path),
    );
  }
}
