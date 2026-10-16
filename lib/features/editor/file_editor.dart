import 'package:bird/core/ui/my_button.dart';
import 'package:bird/core/ui/nf_icons.dart';
import 'package:bird/features/editor/editor_document.dart';
import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:bird/features/settings/settings_provider.dart';
import 'package:bird/features/theme/theme_provider.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One open file's editor.
///
/// Reads the theme and settings itself so that only this subtree rebuilds when
/// they change. Its own key still forces a remount for the values CodeForge
/// snapshots in initState and never re-reads.
class FileEditor extends StatelessWidget {
  const FileEditor({super.key, required this.document, this.autoFocus = true});

  final EditorDocument document;

  /// Off for the editors Sky keeps mounted behind snapshots: all of them
  /// asking for the keyboard at once would leave it with whichever came last.
  final bool autoFocus;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final lspProvider = context.watch<LspProvider>();
    final settings = context.watch<SettingsProvider>();

    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Colors.transparent),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        thickness: WidgetStateProperty.all(0),
      ),
      child: CodeForge(
        // CodeForge captures the controller, theme and language in initState
        // and ignores later swaps, so anything it will not pick up on its own
        // has to arrive as a new widget. The path is deliberately absent: this
        // editor belongs to one file for its whole life.
        key: ValueKey(
          '${themeProvider.themeName}-${identityHashCode(lspProvider.dartLspConfig)}'
          '-${settings.editorFontSize}-${settings.editorTabSize}'
          '-${settings.editorWordWrap}-${settings.editorLineNumbers}',
        ),
        filePath: document.path,
        innerPadding: const EdgeInsets.only(top: 8.0),
        editorTheme: themeProvider.editorTheme,
        autoFocus: autoFocus,
        controller: document.controller,
        language: document.language?.mode,
        tabSize: settings.editorTabSize,
        useSpaceAsTab: true,
        enableGuideLines: true,
        lineWrap: settings.editorWordWrap,
        enableGutter: settings.editorLineNumbers,
        textStyle: TextStyle(
          fontFamily: 'FiraCode',
          fontFamilyFallback: const [
            'Menlo',
            'Consolas',
            'Courier New',
            'monospace',
          ],
          fontSize: settings.editorFontSize,
          height: 1.4,
        ),
        hoverDetailsStyle: HoverDetailsStyle(
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color(0xFF454545), width: 1),
          ),
          backgroundColor: const Color(0xFF252526),
          focusColor: const Color(0xFF04395E),
          hoverColor: const Color(0xFF2A2D2E),
          splashColor: Colors.transparent,
          textStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
        ),
        suggestionStyle: SuggestionStyle(
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color(0xFF454545), width: 1),
          ),
          backgroundColor: const Color(0xFF252526),
          selectedBackgroundColor: const Color(0xFF04395E),
          focusColor: const Color(0xFF04395E),
          hoverColor: const Color(0xFF2A2D2E),
          splashColor: Colors.transparent,
          borderColor: const Color(0xFF454545),
          textStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
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
    );
  }
}

/// Shown when an open file changed on disk while the buffer held unsaved edits.
///
/// Bird will not choose for the user: reloading loses the edits, saving loses
/// whatever changed the file. Both are one click away, and neither happens on
/// its own.
class DiskConflictBar extends StatelessWidget {
  const DiskConflictBar({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          const Icon(NfIcons.warning, size: 14, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This file changed on disk, and you have unsaved changes.',
              style: TextStyle(
                fontSize: 12,
                color: primary.withValues(alpha: 0.85),
              ),
            ),
          ),
          MyButton(
            label: 'Reload',
            height: 28,
            fontSize: 12,
            variant: MyButtonVariant.outline,
            tooltip: 'Discard your changes and take the version on disk',
            onPressed: () =>
                context.read<EditorProvider>().reloadFromDisk(path),
          ),
          const SizedBox(width: 8),
          MyButton(
            label: 'Keep mine',
            height: 28,
            fontSize: 12,
            variant: MyButtonVariant.outline,
            tooltip: 'Keep your version; saving will overwrite the file',
            onPressed: () => context.read<EditorProvider>().keepMine(path),
          ),
        ],
      ),
    );
  }
}
