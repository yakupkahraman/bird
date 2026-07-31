import 'package:bird/bindings.dart';
import 'package:bird/pages/code_pane.dart';
import 'package:bird/pages/explorer_pane.dart';
import 'package:bird/pages/theme_picker_pane.dart';
import 'package:bird/pages/terminal_pane.dart';
import 'package:bird/widgets/custom_titlebar.dart';
import 'package:bird/pages/extensions_pane.dart';
import 'package:bird/widgets/my_icon_button.dart';
import 'package:bird/terminal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int selectedIndex = 0;
  double _explorerWidth = 150.0;
  double _lastWidth = 150.0;
  double _dragTargetWidth = 150.0;
  bool _isDragging = false;

  static const double _minExplorerWidth = 150.0;
  static const double _maxExplorerWidth = 500.0;

  final pages = <Widget>[
    const ExplorerPane(),
    const ExtensionsPane(),
    const ThemePickerPane(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TerminalProvider>().initializePty();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: getAppShortcuts(context),
      child: MouseRegion(
        cursor: _isDragging
            ? SystemMouseCursors.resizeColumn
            : MouseCursor.defer,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          body: Column(
            children: [
              CustomTitleBar(),
              Divider(height: 1, color: Colors.grey[900]),
              Expanded(
                child: Row(
                  children: [
                    sideBar(context),
                    VerticalDivider(width: 1, color: Colors.grey[900]),
                    SizedBox(
                      width: _explorerWidth,
                      child: pages[selectedIndex],
                    ),

                    MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        onHorizontalDragStart: (_) {
                          setState(() {
                            _isDragging = true;
                            _dragTargetWidth = _explorerWidth;
                          });
                        },
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragTargetWidth += details.delta.dx;

                            if (_dragTargetWidth <= _minExplorerWidth / 2) {
                              if (_explorerWidth > 0) {
                                _lastWidth = _explorerWidth > _minExplorerWidth
                                    ? _explorerWidth
                                    : _lastWidth;
                              }
                              _explorerWidth = 0;
                            } else if (_explorerWidth == 0 &&
                                _dragTargetWidth > _minExplorerWidth / 2) {
                              _explorerWidth = _minExplorerWidth;
                            } else if (_dragTargetWidth > _maxExplorerWidth) {
                              _explorerWidth = _maxExplorerWidth;
                            } else if (_dragTargetWidth < _minExplorerWidth) {
                              _explorerWidth = _minExplorerWidth;
                            } else {
                              _explorerWidth = _dragTargetWidth;
                            }
                          });
                        },
                        onHorizontalDragEnd: (_) {
                          setState(() {
                            _isDragging = false;
                          });
                        },
                        child: Container(
                          width: 4,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Row(
                            children: [
                              VerticalDivider(
                                width: 1,
                                color: Colors.grey[900],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: CodePane()),
                          const TerminalPane(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Padding sideBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            spacing: 4,
            children: [
              MyIconButton(
                onPressed: () {
                  setState(() {
                    if (selectedIndex == 0 && _explorerWidth > 0) {
                      _lastWidth = _explorerWidth;
                      _explorerWidth = 0;
                    } else {
                      selectedIndex = 0;
                      if (_explorerWidth == 0) {
                        _explorerWidth = _lastWidth;
                      }
                    }
                  });
                },
                icon: Icons.folder_outlined,
              ),
              MyIconButton(
                onPressed: () {
                  setState(() {
                    if (selectedIndex == 1 && _explorerWidth > 0) {
                      _lastWidth = _explorerWidth;
                      _explorerWidth = 0;
                    } else {
                      selectedIndex = 1;
                      if (_explorerWidth == 0) {
                        _explorerWidth = _lastWidth;
                      }
                    }
                  });
                },
                icon: Icons.extension_outlined,
              ),
            ],
          ),
          Column(
            spacing: 4,
            children: [
              MyIconButton(
                icon: Icons.palette_outlined,
                onPressed: () {
                  setState(() {
                    if (selectedIndex == 2 && _explorerWidth > 0) {
                      _lastWidth = _explorerWidth;
                      _explorerWidth = 0;
                    } else {
                      selectedIndex = 2;
                      if (_explorerWidth == 0) {
                        _explorerWidth = _lastWidth;
                      }
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
