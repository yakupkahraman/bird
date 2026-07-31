import 'package:bird/bindings.dart';
import 'package:bird/pages/code_pane.dart';
import 'package:bird/pages/explorer_pane.dart';
import 'package:bird/pages/extensions_pane.dart';
import 'package:bird/pages/terminal_pane.dart';
import 'package:bird/pages/theme_picker_pane.dart';
import 'package:bird/terminal_provider.dart';
import 'package:bird/widgets/custom_titlebar.dart';
import 'package:bird/widgets/my_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:panes/panes.dart';
import 'package:provider/provider.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _selectedIndex = 0;
  late final IdeController _ideController;

  final List<Widget> _panes = const [
    ExplorerPane(),
    ExtensionsPane(),
    ThemePickerPane(),
  ];

  @override
  void initState() {
    super.initState();
    _ideController = IdeController(
      leftSize: PaneSize.pixel(200),
      leftMinSize: PaneSize.pixel(120),
      leftMaxSize: PaneSize.pixel(500),
      leftVisible: true,
      bottomSize: PaneSize.pixel(200),
      bottomMinSize: PaneSize.pixel(80),
      bottomMaxSize: PaneSize.pixel(500),
      bottomVisible: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TerminalProvider>().initializePty();
    });
  }

  @override
  void dispose() {
    _ideController.dispose();
    super.dispose();
  }

  void _onSidebarTabPressed(int index) {
    final isLeftVisible = _ideController.rootController.isVisible(
      IdePane.left.id,
    );
    setState(() {
      if (_selectedIndex == index && isLeftVisible) {
        _ideController.rootController.hide(IdePane.left.id);
      } else {
        _selectedIndex = index;
        if (!isLeftVisible) {
          _ideController.rootController.show(IdePane.left.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: getAppShortcuts(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        body: Column(
          children: [
            const CustomTitleBar(),
            Expanded(
              child: Row(
                children: [
                  _sideBar(context),
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
                        controller: _ideController,
                        leftPanelBuilder: (context, animationProgress) =>
                            Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _panes[_selectedIndex],
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

  Widget _sideBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            spacing: 4,
            children: [
              MyIconButton(
                onPressed: () => _onSidebarTabPressed(0),
                icon: Icons.folder_outlined,
              ),
              MyIconButton(
                onPressed: () => _onSidebarTabPressed(1),
                icon: Icons.extension_outlined,
              ),
            ],
          ),
          Column(
            spacing: 4,
            children: [
              MyIconButton(
                onPressed: () => _onSidebarTabPressed(2),
                icon: Icons.palette_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
