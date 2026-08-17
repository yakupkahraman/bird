import 'dart:io';
import 'package:bird/ui/views/internal_views.dart';
import 'package:bird/providers/file_provider.dart';
import 'package:bird/providers/lsp_provider.dart';
import 'package:bird/providers/prog_lang_provider.dart';
import 'package:bird/theme/theme_provider.dart';
import 'package:bird/widgets/file_icon.dart';
import 'package:bird/widgets/my_button.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class CodePanel extends StatefulWidget {
  const CodePanel({super.key});

  @override
  State<CodePanel> createState() => _CodePanelState();
}

class _CodePanelState extends State<CodePanel> {
  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<FileProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<ProgLangProvider>();
    final lspProvider = context.watch<LspProvider>();

    final openPaths = fileProvider.openFilePaths;
    final selectedPath = fileProvider.selectedFilePath;

    if (openPaths.isEmpty || selectedPath == null) {
      final primary = Theme.of(context).colorScheme.primary;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/bird-mono.svg',
                width: 52,
                height: 52,
                colorFilter: ColorFilter.mode(
                  primary.withValues(alpha: 0.75),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fileProvider.rootPath == null ? 'Bird IDE' : 'No File Open',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fileProvider.rootPath == null
                    ? 'Open a folder to start editing'
                    : 'Select a file from the explorer to start editing',
                style: TextStyle(
                  fontSize: 12,
                  color: primary.withValues(alpha: 0.45),
                ),
              ),
              if (fileProvider.rootPath == null) ...[
                const SizedBox(height: 20),
                MyButton(
                  label: 'Open Folder',
                  icon: NfIcons.folder,
                  onPressed: () => context.read<FileProvider>().pickFolder(),
                ),
              ],
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

          // Content Area: Special custom tab or CodeForge editor Area
          if (InternalViews.of(selectedPath) case final internalView?)
            Expanded(child: internalView.view)
          else
            Expanded(
              child: ScrollbarTheme(
                data: ScrollbarThemeData(
                  thumbColor: WidgetStateProperty.all(Colors.transparent),
                  trackColor: WidgetStateProperty.all(Colors.transparent),
                  trackBorderColor: WidgetStateProperty.all(Colors.transparent),
                  thickness: WidgetStateProperty.all(0),
                ),
                child: CodeForge(
                  // The LSP config is part of the key because CodeForge captures
                  // its controller in initState and ignores later swaps.
                  key: ValueKey(
                    '${themeProvider.themeName}-$selectedPath-${languageProvider.currentLanguage.name}-${identityHashCode(lspProvider.dartLspConfig)}',
                  ),
                  filePath: selectedPath,
                  innerPadding: const EdgeInsets.only(top: 8.0),
                  editorTheme: themeProvider.editorTheme,
                  autoFocus: true,
                  controller: fileProvider.currentController,
                  language: languageProvider.currentLanguage.mode,
                  tabSize: 2,
                  useSpaceAsTab: true,
                  enableGuideLines: true,
                  textStyle: const TextStyle(
                    fontFamily: 'FiraCode',
                    fontFamilyFallback: [
                      'Menlo',
                      'Consolas',
                      'Courier New',
                      'monospace',
                    ],
                    fontSize: 13,
                    height: 1.4,
                  ),
                  hoverDetailsStyle: HoverDetailsStyle(
                    elevation: 6.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(
                        color: Color(0xFF454545),
                        width: 1,
                      ),
                    ),
                    backgroundColor: const Color(0xFF252526),
                    focusColor: const Color(0xFF04395E),
                    hoverColor: const Color(0xFF2A2D2E),
                    splashColor: Colors.transparent,
                    textStyle: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12,
                    ),
                  ),
                  suggestionStyle: SuggestionStyle(
                    elevation: 6.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(
                        color: Color(0xFF454545),
                        width: 1,
                      ),
                    ),
                    backgroundColor: const Color(0xFF252526),
                    selectedBackgroundColor: const Color(0xFF04395E),
                    focusColor: const Color(0xFF04395E),
                    hoverColor: const Color(0xFF2A2D2E),
                    splashColor: Colors.transparent,
                    borderColor: const Color(0xFF454545),
                    textStyle: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12,
                    ),
                    labelTextStyle: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12,
                    ),
                    detailTextStyle: const TextStyle(
                      color: Color(0xFF858585),
                      fontSize: 11,
                    ),
                    typeTextStyle: const TextStyle(
                      color: Color(0xFF4EC9B0),
                      fontSize: 11,
                    ),
                    methodIconColor: const Color(0xFFB180D7),
                    propertyIconColor: const Color(0xFF75BEFF),
                    classIconColor: const Color(0xFF4EC9B0),
                    variableIconColor: const Color(0xFF75BEFF),
                    keywordIconColor: const Color(0xFF569CD6),
                  ),
                ),
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

    final internalView = InternalViews.of(widget.path);
    final title =
        internalView?.title ?? widget.path.split(Platform.pathSeparator).last;
    final specialIcon = internalView?.icon;

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
                specialIcon != null
                    ? Icon(
                        specialIcon,
                        size: 14,
                        color: widget.isSelected
                            ? primary
                            : primary.withValues(alpha: 0.65),
                      )
                    : FileIcon(title, size: 14),
                const SizedBox(width: 6),
                Text(
                  title,
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
                        NfIcons.close,
                        size: 13,
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
