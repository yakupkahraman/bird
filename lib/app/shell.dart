import 'package:bird/app/bindings.dart';
import 'package:bird/features/editor/code_panel.dart';
import 'package:bird/features/workspace/explorer_panel.dart';
import 'package:bird/features/extensions/extensions_panel.dart';
import 'package:bird/features/terminal/terminal_panel.dart';
import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:bird/features/layout/panes_provider.dart';
import 'package:bird/features/terminal/terminal_provider.dart';
import 'package:bird/features/layout/bottom_bar.dart';
import 'package:bird/features/notifications/notification_overlay.dart';
import 'package:bird/features/layout/left_bar.dart';
import 'package:bird/features/layout/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:panes/panes.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WindowListener {
  final List<Widget> _panes = const [ExplorerPanel(), ExtensionsPanel()];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TerminalProvider>().initializePty();
    });
  }

  @override
  void onWindowClose() async {
    try {
      context.read<LspProvider>().stopServer();
    } finally {
      // Must always run, or setPreventClose(true) leaves the app unclosable.
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panesProvider = context.watch<PanesProvider>();

    return CallbackShortcuts(
      bindings: getAppShortcuts(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        body: Stack(
          children: [
            Column(
              children: [
                const TopBar(),
                Expanded(
                  child: Row(
                    children: [
                      const LeftBar(),
                      Expanded(
                        child: PaneTheme(
                          data: const PaneThemeData(
                            resizerColor: Colors.transparent,
                            resizerHoverColor: Colors.transparent,
                            resizerThickness: 0.0,
                            resizerHitTestThickness: 8.0,
                          ),
                          child: IdeLayout(
                            controller: panesProvider.ideController,
                            onPaneStateChanged:
                                panesProvider.onPaneVisibilityChanged,
                            leftPanelBuilder: (context, animationProgress) =>
                                Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        _panes[panesProvider
                                            .selectedSidebarIndex],
                                  ),
                                ),
                            centerBuilder: (context, animationProgress) =>
                                Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const CodePanel(),
                                  ),
                                ),
                            bottomPanelBuilder: (context, animationProgress) =>
                                Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const TerminalPanel(),
                                  ),
                                ),
                            rightPanelBuilder: (context, animationProgress) =>
                                Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      child: Center(
                                        child: Text(
                                          'Right Panel',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const BottomBar(),
              ],
            ),
            // Above the status bar and clear of the right edge, where VS Code
            // puts them. Outside the Column so it floats over the panes
            // instead of taking layout space from them.
            const Positioned(
              right: 12,
              bottom: BottomBar.bottomBarHeight + 12,
              child: NotificationOverlay(),
            ),
          ],
        ),
      ),
    );
  }
}
