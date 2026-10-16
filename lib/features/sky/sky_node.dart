import 'dart:ui' as ui;

import 'package:bird/core/ui/nf_icons.dart';
import 'package:flutter/material.dart';

/// One tab on Sky's canvas: a header to drag it by, and its content — live
/// when focused, a snapshot of itself otherwise.
class SkyNode extends StatelessWidget {
  const SkyNode({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    required this.boundary,
    required this.snapshot,
    required this.isFocused,
    required this.isDirty,
    required this.scale,
    required this.onFocus,
    required this.onMove,
    required this.onResize,
    required this.onClose,
  });

  final String title;
  final Widget icon;
  final Widget content;

  /// Wraps [content], so the canvas can photograph it.
  final GlobalKey boundary;

  /// Shown in place of [content] while not focused; until one exists the
  /// content itself is shown.
  final ui.Image? snapshot;

  final bool isFocused;
  final bool isDirty;

  /// The canvas zoom when asked: a drag arrives in screen pixels.
  final double Function() scale;
  final VoidCallback onFocus;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Size> onResize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isLive = isFocused || snapshot == null;

    return Listener(
      // Any press makes a node the focused one, snapshot or not.
      onPointerDown: (_) {
        if (!isFocused) onFocus();
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Colors.black26)],
        ),
        // In front of the content: a border in the decoration is painted
        // first, and the header's square corners covered its rounded ones.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused
                ? theme.colorScheme.tertiary.withValues(alpha: 0.45)
                : primary.withValues(alpha: 0.08),
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onPanUpdate: (d) => onMove(d.delta / scale()),
                  child: Container(
                    height: 28,
                    color: theme.colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      spacing: 6,
                      children: [
                        icon,
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: primary.withValues(
                                alpha: isFocused ? 0.9 : 0.6,
                              ),
                            ),
                          ),
                        ),
                        if (isDirty)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        GestureDetector(
                          onTap: onClose,
                          child: Icon(
                            NfIcons.close,
                            size: 13,
                            color: primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Kept mounted under its snapshot, so focusing it again
                      // finds it scrolled where it was, still on the language
                      // server. Offstage and with tickers off, it paints
                      // nothing and costs nothing per frame.
                      Visibility(
                        visible: isLive,
                        maintainState: true,
                        child: RepaintBoundary(key: boundary, child: content),
                      ),
                      if (!isLive) RawImage(image: snapshot, fit: BoxFit.fill),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (d) {
                  final by = d.delta / scale();
                  onResize(Size(by.dx, by.dy));
                },
                child: const MouseRegion(
                  cursor: SystemMouseCursors.resizeDownRight,
                  child: SizedBox(width: 16, height: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
