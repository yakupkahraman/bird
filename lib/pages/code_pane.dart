import 'dart:io';
import 'package:bird/file_provider.dart';
import 'package:bird/planguage_provider.dart';
import 'package:bird/theme/theme_provider.dart';
import 'package:code_forge/code_forge.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CodePane extends StatefulWidget {
  const CodePane({super.key});

  @override
  State<CodePane> createState() => _CodePaneState();
}

class _CodePaneState extends State<CodePane> {
  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<FileProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<PlanguageProvider>();

    final openPaths = fileProvider.openFilePaths;
    final selectedPath = fileProvider.selectedFilePath;

    if (openPaths.isEmpty || selectedPath == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withAlpha(90),
              ),
              const SizedBox(height: 12),
              Text(
                'No File Open',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary.withAlpha(180),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a file from the explorer to start editing',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Tab Header Bar
          Container(
            height: 38,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            color: Theme.of(context).colorScheme.secondary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: openPaths.map((path) {
                  return _TabItem(
                    key: ValueKey(path),
                    path: path,
                    isSelected: path == selectedPath,
                    onTap: () {
                      context.read<FileProvider>().selectTab(
                        path,
                        languageProvider,
                      );
                    },
                    onClose: () {
                      context.read<FileProvider>().closeTab(path);
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          // Code Editor Area
          Expanded(
            child: CodeForge(
              key: ValueKey(
                '${themeProvider.themeName}-$selectedPath-${languageProvider.currentLanguage.name}',
              ),
              innerPadding: const EdgeInsets.only(top: 8.0),
              editorTheme: themeProvider.editorTheme,
              autoFocus: true,
              controller: fileProvider.currentController,
              language: languageProvider.currentLanguage.mode,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final String path;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    super.key,
    required this.path,
    required this.isSelected,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;
  bool _isCloseHovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final fileName = widget.path.split(Platform.pathSeparator).last;

    Color bg;
    if (widget.isSelected) {
      bg = Theme.of(context).scaffoldBackgroundColor;
    } else if (_isHovered) {
      bg = primary.withValues(alpha: 0.08);
    } else {
      bg = primary.withValues(alpha: 0.03);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6.0),
              border: widget.isSelected
                  ? Border.all(
                      color: primary.withValues(alpha: 0.2),
                      width: 1.0,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FileIcon(fileName, size: 14),
                const SizedBox(width: 6),
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: widget.isSelected
                        ? primary
                        : primary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _isCloseHovered = true),
                  onExit: (_) => setState(() => _isCloseHovered = false),
                  child: GestureDetector(
                    onTap: widget.onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: _isCloseHovered
                            ? primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: widget.isSelected
                            ? primary.withValues(alpha: 0.8)
                            : primary.withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
