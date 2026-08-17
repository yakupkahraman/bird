import 'package:bird/providers/file_provider.dart';
import 'package:bird/providers/lsp_provider.dart';
import 'package:bird/widgets/file_icon.dart';
import 'package:bird/widgets/mini_button.dart';
import 'package:bird/widgets/my_menu_item.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  static const double bottomBarHeight = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fileProvider = context.watch<FileProvider>();
    final lspProvider = context.watch<LspProvider>();
    final selectedPath = fileProvider.selectedFilePath;
    final isLspRunning = lspProvider.isRunning;

    return Container(
      height: bottomBarHeight,
      color: theme.colorScheme.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Builder(
            builder: (btnContext) {
              return MiniButton(
                icon: NfIcons.dart,
                trailingIcon: NfIcons.dot,
                tooltip: isLspRunning
                    ? 'Dart Language Server: Running'
                    : 'Dart Language Server: Stopped',
                trailingIconColor: isLspRunning
                    ? const Color(0xFF4CAF50)
                    : primary.withValues(alpha: 0.35),
                onPressed: () => _showLspMenu(btnContext),
              );
            },
          ),
          if (selectedPath != null && selectedPath.isNotEmpty) ...[
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 12,
              color: primary.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 6),
            Flexible(child: _buildPathDisplay(selectedPath, primary)),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  void _showLspMenu(BuildContext buttonContext) {
    final RenderBox? button = buttonContext.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox? overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final Offset buttonOffset = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final theme = Theme.of(buttonContext);
    final primary = theme.colorScheme.primary;
    final lspProvider = buttonContext.read<LspProvider>();
    const double menuWidth = 180.0;
    final double bottom = overlay.size.height - buttonOffset.dy + 4;
    final double left = buttonOffset.dx;

    showGeneralDialog(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss LSP Menu',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, _) {
        final isRunning = lspProvider.isRunning;

        return Stack(
          children: [
            Positioned(
              left: left,
              bottom: bottom,
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
                      MyMenuItem(
                        icon: NfIcons.dart,
                        title: isRunning
                            ? 'Dart LSP: Running'
                            : 'Dart LSP: Stopped',
                        trailing: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRunning
                                ? const Color(0xFF4CAF50)
                                : Colors.redAccent,
                          ),
                        ),
                        onTap: () {},
                      ),
                      const MyMenuDivider(),
                      MyMenuItem(
                        icon: NfIcons.restart,
                        title: 'Restart Server',
                        onTap: () => lspProvider.restartServer(),
                      ),
                      MyMenuItem(
                        icon: isRunning ? NfIcons.stop : NfIcons.play,
                        title: isRunning ? 'Stop Server' : 'Start Server',
                        onTap: () => isRunning
                            ? lspProvider.stopServer()
                            : lspProvider.startServer(),
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

  Widget _buildPathDisplay(String path, Color primary) {
    IconData? specialIcon;
    String displayPath = path;

    if (path.startsWith('bird://')) {
      final name = path.replaceFirst('bird://', '');
      switch (name) {
        case 'account':
          specialIcon = NfIcons.profile;
          displayPath = 'Bird > Account';
          break;
        case 'settings':
          specialIcon = NfIcons.settings;
          displayPath = 'Bird > Settings';
          break;
        case 'keymap':
          specialIcon = NfIcons.keyboard;
          displayPath = 'Bird > Keymap';
          break;
        case 'themes':
          specialIcon = NfIcons.palette;
          displayPath = 'Bird > Themes';
          break;
        default:
          specialIcon = NfIcons.info;
          displayPath = 'Bird > $name';
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (specialIcon != null)
          Icon(specialIcon, size: 13, color: primary.withValues(alpha: 0.7))
        else
          FileIcon(path, size: 13),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            displayPath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
