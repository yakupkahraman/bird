import 'package:bird_ce/file_provider.dart';
import 'package:bird_ce/pages/code_page.dart';
import 'package:bird_ce/pages/languages_page.dart';
import 'package:bird_ce/pages/theme_picker_page.dart';
import 'package:bird_ce/widgets/custom_titlebar.dart';
import 'package:bird_ce/pages/extensions_page.dart';
import 'package:bird_ce/widgets/file_tree_item.dart';
import 'package:bird_ce/widgets/my_icon_button.dart';
import 'package:bird_ce/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
    Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        if (fileProvider.rootPath == null) return const SizedBox.shrink();

        final folderName = fileProvider.rootPath!.split('/').last;

        return Container(
          width: _minExplorerWidth,
          decoration: BoxDecoration(
            color: context.watch<ThemeProvider>().backgroundColor,
            border: const Border(
              right: BorderSide(color: Colors.white10, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  folderName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white54,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Consumer<FileProvider>(
                    builder: (context, fileProvider, child) {
                      return Column(
                        children: fileProvider.files
                            .map((e) => FileTreeItem(entity: e))
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
    const ExtensionsPage(),
    const LanguagesPage(),
    const ThemePickerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isDragging ? SystemMouseCursors.resizeColumn : MouseCursor.defer,
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
                  Consumer<FileProvider>(
                    builder: (context, fileProvider, child) {
                      if (fileProvider.rootPath == null && selectedIndex == 0) {
                        return const SizedBox.shrink();
                      }

                      return SizedBox(
                        width: _explorerWidth,
                        child: pages[selectedIndex],
                      );
                    },
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

                          print(
                            "Target Width: $_dragTargetWidth ${details.delta.dx}",
                          );

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
                            print("Set Width: $_explorerWidth");
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
                            VerticalDivider(width: 1, color: Colors.grey[900]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: CodePage()),
                ],
              ),
            ),
          ],
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
                icon: PhosphorIcons.bird(PhosphorIconsStyle.thin),
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
                icon: PhosphorIcons.feather(PhosphorIconsStyle.thin),
              ),
            ],
          ),
          Column(
            spacing: 4,
            children: [
              MyIconButton(
                icon: PhosphorIcons.code(PhosphorIconsStyle.thin),
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
              MyIconButton(
                icon: PhosphorIcons.palette(PhosphorIconsStyle.thin),
                onPressed: () {
                  setState(() {
                    if (selectedIndex == 3 && _explorerWidth > 0) {
                      _lastWidth = _explorerWidth;
                      _explorerWidth = 0;
                    } else {
                      selectedIndex = 3;
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
