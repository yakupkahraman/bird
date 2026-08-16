import 'dart:io';
import 'package:bird/providers/file_provider.dart';
import 'package:bird/providers/panes_provider.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  double get titleBarHeight {
    if (Platform.isMacOS) {
      return 30.0;
    } else if (Platform.isWindows) {
      return 32.0;
    }
    return 30.0;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final panesProvider = context.watch<PanesProvider>();

    return Container(
      height: titleBarHeight,
      color: Theme.of(context).colorScheme.secondary,
      child: Row(
        children: [
          if (Platform.isMacOS) const SizedBox(width: 78),

          Expanded(
            child: DragToMoveArea(
              child: Container(
                height: titleBarHeight,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    'Bird',
                    style: TextStyle(
                      color: primary.withAlpha(200),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          _TopBarButton(
            icon: NfIcons.save,
            tooltip: "Save (Ctrl+S)",
            onPressed: () => context.read<FileProvider>().saveFile(),
          ),

          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: primary.withValues(alpha: 0.18),
          ),

          _TopBarButton(
            icon: NfIcons.layoutSidebarLeft,
            tooltip: 'Toggle Left Panel (Ctrl+B)',
            isSelected: panesProvider.isLeftVisible,
            onPressed: () => panesProvider.toggleLeft(),
          ),
          _TopBarButton(
            icon: NfIcons.layoutPanelBottom,
            tooltip: 'Toggle Bottom Panel (Ctrl+J)',
            isSelected: panesProvider.isBottomVisible,
            onPressed: () => panesProvider.toggleBottom(),
          ),
          _TopBarButton(
            icon: NfIcons.layoutSidebarRight,
            tooltip: 'Toggle Right Panel',
            isSelected: panesProvider.isRightVisible,
            onPressed: () => panesProvider.toggleRight(),
          ),

          const SizedBox(width: 4),

          if (Platform.isWindows || Platform.isLinux)
            const WindowCaptionButtons(),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isSelected;

  const _TopBarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isSelected = false,
  });

  @override
  State<_TopBarButton> createState() => _TopBarButtonState();
}

class _TopBarButtonState extends State<_TopBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    Color backgroundColor;
    if (widget.isSelected) {
      backgroundColor = primary.withValues(alpha: 0.15);
    } else if (_isHovered) {
      backgroundColor = primary.withValues(alpha: 0.08);
    } else {
      backgroundColor = Colors.transparent;
    }

    Color iconColor;
    if (widget.isSelected) {
      iconColor = primary;
    } else if (_isHovered) {
      iconColor = primary.withValues(alpha: 0.95);
    } else {
      iconColor = primary.withValues(alpha: 0.65);
    }

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      preferBelow: true,
      verticalOffset: 14,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border.all(color: primary.withValues(alpha: 0.22), width: 0.8),
        borderRadius: BorderRadius.circular(5),
      ),
      textStyle: TextStyle(
        color: primary.withValues(alpha: 0.9),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 1.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(widget.icon, size: 15, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class WindowCaptionButtons extends StatefulWidget {
  const WindowCaptionButtons({super.key});

  @override
  State<WindowCaptionButtons> createState() => _WindowCaptionButtonsState();
}

class _WindowCaptionButtonsState extends State<WindowCaptionButtons>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  Future<void> _checkMaximized() async {
    final max = await windowManager.isMaximized();
    if (mounted) {
      setState(() => _isMaximized = max);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WindowCaptionButton.minimize(
          brightness: brightness,
          onPressed: () async {
            bool isMinimized = await windowManager.isMinimized();
            if (isMinimized) {
              windowManager.restore();
            } else {
              windowManager.minimize();
            }
          },
        ),
        if (_isMaximized)
          WindowCaptionButton.unmaximize(
            brightness: brightness,
            onPressed: () => windowManager.unmaximize(),
          )
        else
          WindowCaptionButton.maximize(
            brightness: brightness,
            onPressed: () => windowManager.maximize(),
          ),
        WindowCaptionButton.close(
          brightness: brightness,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}
