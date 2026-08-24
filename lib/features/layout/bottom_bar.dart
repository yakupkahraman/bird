import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/sdk/flutter_sdk_provider.dart';
import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:bird/features/settings/settings_view.dart';
import 'package:bird/core/ui/file_icon.dart';
import 'package:bird/core/ui/mini_button.dart';
import 'package:bird/features/internal_views/internal_views.dart';
import 'package:bird/core/ui/my_menu_item.dart';
import 'package:bird/core/ui/nf_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  static const double bottomBarHeight = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final editor = context.watch<EditorProvider>();
    final lspProvider = context.watch<LspProvider>();
    final sdkProvider = context.watch<FlutterSdkProvider>();
    final selectedPath = editor.selectedFilePath;
    final isLspRunning = lspProvider.isRunning;
    final sdk = sdkProvider.sdkInfo;

    return Container(
      height: bottomBarHeight,
      color: theme.colorScheme.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          // Everything on the left, in one slot that takes the whole width.
          // A Spacer beside the path would only get half the free space, and
          // the SDK button would stop short of the right edge.
          Expanded(
            child: Row(
              children: [
                // Dart LSP button
                Builder(
                  builder: (btnContext) {
                    // Silence means healthy — the badge only shows up when
                    // the server is down, which is what VS Code does too.
                    return MiniButton(
                      icon: isLspRunning ? NfIcons.braces : NfIcons.bracesError,
                      label: 'Dart',
                      tooltip: isLspRunning
                          ? 'Dart Language Server: Running'
                          : 'Dart Language Server: Stopped',
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
              ],
            ),
          ),

          // Flutter SDK — far right, showing which version is in use.
          Builder(
            builder: (btnContext) {
              if (sdkProvider.isBusy) {
                return MiniButton(
                  icon: NfIcons.flutter,
                  label: sdkProvider.phase.label,
                  tooltip:
                      '${sdkProvider.phase.label}: ${sdkProvider.statusMessage}',
                  onPressed: () => SettingsView.show(
                    btnContext,
                    initialCategory: SettingsCategory.flutter,
                  ),
                );
              }
              if (sdk == null) {
                return MiniButton(
                  icon: NfIcons.warning,
                  label: 'No SDK',
                  tooltip: 'No Flutter SDK detected. Click to install.',
                  onPressed: () => SettingsView.show(
                    btnContext,
                    initialCategory: SettingsCategory.flutter,
                  ),
                );
              }
              return MiniButton(
                icon: NfIcons.flutter,
                label: sdk.flutterVersion,
                tooltip:
                    'Flutter ${sdk.flutterVersion} (${sdk.channel}) • ${sdk.isBundled ? "Bundled" : "System"}',
                onPressed: () => _showFlutterMenu(btnContext),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFlutterMenu(BuildContext buttonContext) async {
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
    final sdkProvider = buttonContext.read<FlutterSdkProvider>();
    final sdk = sdkProvider.sdkInfo;
    if (sdk == null) return;

    const double menuWidth = 220.0;
    final double bottom = overlay.size.height - buttonOffset.dy + 4;
    // Right edges lined up, so the menu opens inwards: this button sits at the
    // far right and a left-aligned menu would run off the window.
    final double left = buttonOffset.dx + button.size.width - menuWidth;

    final action = await showGeneralDialog<String>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Flutter Menu',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) {
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
                        icon: NfIcons.flutter,
                        title: 'Flutter ${sdk.flutterVersion}',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            sdk.channel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                      const MyMenuDivider(),
                      MyMenuItem(
                        icon: NfIcons.info,
                        title: 'Run Flutter Doctor',
                        result: 'doctor',
                      ),
                      MyMenuItem(
                        icon: NfIcons.settings,
                        title: 'Manage Flutter SDK...',
                        result: 'manage_sdk',
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

    if (action == null || !buttonContext.mounted) return;

    if (action == 'doctor') {
      SettingsView.show(
        buttonContext,
        initialCategory: SettingsCategory.flutter,
      );
      buttonContext.read<FlutterSdkProvider>().runDoctor();
    } else if (action == 'manage_sdk') {
      SettingsView.show(
        buttonContext,
        initialCategory: SettingsCategory.flutter,
      );
    }
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
      final internalView = InternalViews.of(path);
      specialIcon = internalView?.icon ?? NfIcons.info;
      displayPath =
          'Bird > ${internalView?.title ?? path.replaceFirst('bird://', '')}';
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
