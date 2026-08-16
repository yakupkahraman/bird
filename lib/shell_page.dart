import 'package:bird/bindings.dart';
import 'package:bird/panes/code_pane.dart';
import 'package:bird/panes/explorer_pane.dart';
import 'package:bird/panes/extensions_pane.dart';
import 'package:bird/panes/terminal_pane.dart';
import 'package:bird/panes/theme_picker_pane.dart';
import 'package:bird/providers/lsp_provider.dart';
import 'package:bird/providers/panes_provider.dart';
import 'package:bird/providers/terminal_provider.dart';
import 'package:bird/widgets/my_icon_button.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:bird/widgets/top_bar.dart';
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
  final List<Widget> _panes = const [
    ExplorerPane(),
    ExtensionsPane(),
    ThemePickerPane(),
  ];

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
                  _sideBar(context, panesProvider),
                  Expanded(
                    child: PaneTheme(
                      data: PaneThemeData(
                        resizerColor: Theme.of(context).dividerColor,
                        resizerHoverColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        resizerThickness: 1.0,
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
                            child: const CodePane(),
                          ),
                        ),
                        bottomPanelBuilder: (context, animationProgress) =>
                            Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const TerminalPane(),
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
          ],
        ),
      ),
    );
  }

  Widget _sideBar(BuildContext context, PanesProvider panesProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            spacing: 4,
            children: [
              MyIconButton(
                onPressed: () => panesProvider.onSidebarTabPressed(0),
                icon: NfIcons.folder,
                isSelected:
                    panesProvider.isLeftVisible &&
                    panesProvider.selectedSidebarIndex == 0,
                tooltip: 'Explorer',
              ),
              MyIconButton(
                onPressed: () => panesProvider.onSidebarTabPressed(1),
                icon: NfIcons.extensions,
                isSelected:
                    panesProvider.isLeftVisible &&
                    panesProvider.selectedSidebarIndex == 1,
                tooltip: 'Extensions',
              ),
            ],
          ),
          Column(
            spacing: 4,
            children: [
              MyIconButton(
                onPressed: () => panesProvider.onSidebarTabPressed(2),
                icon: NfIcons.palette,
                isSelected:
                    panesProvider.isLeftVisible &&
                    panesProvider.selectedSidebarIndex == 2,
                tooltip: 'Themes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
