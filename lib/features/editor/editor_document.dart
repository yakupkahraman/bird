import 'package:bird/features/editor/languages.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/widgets.dart';

/// One open file's state.
///
/// Everything that has to outlive a tab switch — or the editor remount that a
/// theme, font or language change forces — lives here. `EditorProvider` owns
/// these and notifies for them; the widget keeps only what is genuinely
/// throwaway, like hover.
///
/// A document exists for file-backed tabs only. `bird://` views are in the tab
/// order with no document behind them, which is why looking one up answers
/// "does this tab have a buffer?" without matching on the path.
class EditorDocument {
  EditorDocument({
    required this.path,
    required String text,
    this.language,
    LspConfig? lspConfig,
  }) : controller = CodeForgeController(lspConfig: lspConfig)..text = text,
       savedText = text;

  final String path;

  /// Null for an extension Bird has no highlighter for, which renders as plain
  /// text. Per file, so switching tabs cannot recolour anything.
  final ProgrammingLanguage? language;

  /// Swapped rather than mutated when the language server appears: `lspConfig`
  /// is final on the controller.
  CodeForgeController controller;

  /// What the file looked like on disk when it was last read or written.
  /// Anything else in the buffer is unsaved work.
  String savedText;

  /// Set while the file changed on disk underneath unsaved edits.
  bool hasConflict = false;

  bool get isDirty => controller.text != savedText;

  /// Puts the cursor at [line] and [column], 1-based as in [TabOpener], and
  /// scrolls it into view. Out-of-range values land on the nearest valid spot.
  ///
  /// After the next frame: a tab opened just now has no editor on screen yet,
  /// and code_forge cannot scroll one it has not laid out.
  void reveal(int line, {int column = 1}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = (line - 1).clamp(0, controller.lineCount - 1);
      final text = controller.getLineText(index);
      // code_forge offsets count Unicode scalars, not UTF-16 code units.
      final character = CodeForgeController.utf16ToScalarOffset(
        text,
        (column - 1).clamp(0, text.length),
      );
      controller.selection = TextSelection.collapsed(
        offset: controller.getLineStartOffset(index) + character,
      );
      try {
        controller.scrollToLine(index);
      } on StateError catch (e) {
        // The editor was closed before the frame; the cursor still moved.
        debugPrint('Could not scroll to line $line: $e');
      }
    });
  }

  void dispose() {
    // dispose() does not send didClose, so the server would keep the file and
    // its unsaved edits in its analysis set.
    controller.lspConfig?.closeDocument(path);
    controller.dispose();
  }
}
