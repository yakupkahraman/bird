import 'package:bird/bindings.dart';
import 'package:bird/ui/panels/code_panel.dart';
import 'package:bird/ui/panels/explorer_panel.dart';
import 'package:bird/ui/panels/extensions_panel.dart';
import 'package:bird/ui/panels/terminal_panel.dart';
import 'package:bird/providers/lsp_provider.dart';
import 'package:bird/providers/panes_provider.dart';
import 'package:bird/providers/terminal_provider.dart';
import 'package:bird/ui/bars/bottom_bar.dart';
import 'package:bird/ui/bars/left_bar.dart';
import 'package:bird/ui/bars/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:panes/panes.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> with WindowListener {
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
        body: Column(
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
                                    _panes[panesProvider.selectedSidebarIndex],
                              ),
                            ),
                        centerBuilder: (context, animationProgress) => Padding(
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
      ),
    );
  }
}
