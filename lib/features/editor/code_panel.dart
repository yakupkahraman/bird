import 'package:bird/features/internal_views/internal_views.dart';
import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/editor/file_editor.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:bird/core/ui/file_icon.dart';
import 'package:bird/core/ui/my_button.dart';
import 'package:bird/core/ui/nf_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class CodePanel extends StatefulWidget {
  const CodePanel({super.key});

  @override
  State<CodePanel> createState() => _CodePanelState();
}

class _CodePanelState extends State<CodePanel> {
  @override
  Widget build(BuildContext context) {
    // The editors read the theme, settings and LSP state themselves, so a
    // change there rebuilds only the editor subtree, not the whole panel.
    final editor = context.watch<EditorProvider>();

    final openPaths = editor.openFilePaths;
    final selectedPath = editor.selectedFilePath;

    if (openPaths.isEmpty || selectedPath == null) {
      final primary = Theme.of(context).colorScheme.primary;
      // Watched inside this branch on purpose: once a file is open the editor
      // must not rebuild every time a folder in the tree is expanded.
      final hasFolder = context.watch<WorkspaceProvider>().rootPath != null;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            Expanded(
              child: Center(
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
                      hasFolder ? 'No File Open' : 'Bird IDE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasFolder
                          ? 'Select a file from the explorer to start editing'
                          : 'Open a folder to start editing',
                      style: TextStyle(
                        fontSize: 12,
                        color: primary.withValues(alpha: 0.45),
                      ),
                    ),
                    if (!hasFolder) ...[
                      const SizedBox(height: 20),
                      MyButton(
                        label: 'Open Folder',
                        icon: NfIcons.folder,
                        onPressed: () =>
                            context.read<WorkspaceProvider>().pickFolder(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
                      context.read<EditorProvider>().selectTab(path);
                    },
                    onClose: () {
                      context.read<EditorProvider>().closeTab(path);
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          if (editor.hasConflict(selectedPath))
            DiskConflictBar(path: selectedPath),

          // Every open tab is built and kept alive, and switching tabs only
          // changes which one is painted. Rebuilding the editor instead would
          // remount CodeForge, and re_highlight recolours the whole document
          // on mount — that is the lag you see when flipping between files.
          Expanded(
            child: IndexedStack(
              sizing: StackFit.expand,
              index: openPaths
                  .indexOf(selectedPath)
                  .clamp(0, openPaths.length - 1),
              children: [
                for (final path in openPaths)
                  if (InternalViews.of(path) case final internalView?)
                    KeyedSubtree(key: ValueKey(path), child: internalView.view)
                  else if (editor.documentFor(path) case final document?)
                    FileEditor(key: ValueKey(path), document: document)
                  else
                    SizedBox.shrink(key: ValueKey(path)),
              ],
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
    final title = internalView?.title ?? p.basename(widget.path);
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
