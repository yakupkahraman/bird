import 'dart:io';
import 'package:bird/providers/file_provider.dart';
import 'package:bird/providers/panes_provider.dart';
import 'package:bird/ui/views/internal_views.dart';
import 'package:bird/widgets/mini_button.dart';
import 'package:bird/widgets/my_menu_item.dart';
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

          MiniButton(
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

          MiniButton(
            icon: NfIcons.layoutSidebarLeft,
            tooltip: 'Toggle Left Panel (Ctrl+B)',
            isSelected: panesProvider.isLeftVisible,
            onPressed: () => panesProvider.toggleLeft(),
          ),
          MiniButton(
            icon: NfIcons.layoutPanelBottom,
            tooltip: 'Toggle Bottom Panel (Ctrl+J)',
            isSelected: panesProvider.isBottomVisible,
            onPressed: () => panesProvider.toggleBottom(),
          ),
          MiniButton(
            icon: NfIcons.layoutSidebarRight,
            tooltip: 'Toggle Right Panel',
            isSelected: panesProvider.isRightVisible,
            onPressed: () => panesProvider.toggleRight(),
          ),
          Builder(
            builder: (btnContext) {
              return MiniButton(
                icon: NfIcons.profile,
                trailingIcon: NfIcons.chevronDown,
                tooltip: 'Menu',
                onPressed: () => _showProfileMenu(btnContext),
              );
            },
          ),

          const SizedBox(width: 4),

          if (Platform.isWindows || Platform.isLinux)
            const WindowCaptionButtons(),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext buttonContext) {
    final RenderBox? button = buttonContext.findRenderObject() as RenderBox?;
    if (button == null) return;

    final Offset buttonOffset = button.localToGlobal(Offset.zero);
    final Size buttonSize = button.size;
    final theme = Theme.of(buttonContext);
    final primary = theme.colorScheme.primary;
    const double menuWidth = 160.0;

    final double top = buttonOffset.dy + buttonSize.height + 4;
    final double left = buttonOffset.dx + buttonSize.width - menuWidth;

    showGeneralDialog(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Profile Menu',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, _) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final group in InternalViews.menuGroups) ...[
                        for (final view in group)
                          MyMenuItem(
                            title: view.title,
                            icon: view.icon,
                            onTap: () {
                              buttonContext.read<FileProvider>().openCustomTab(
                                view.path,
                              );
                            },
                          ),
                        const MyMenuDivider(),
                      ],
                      MyMenuItem(
                        title: 'Help Bird',
                        icon: NfIcons.help,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
