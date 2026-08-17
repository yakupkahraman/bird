import 'package:flutter/widgets.dart';

/// Nerd Font (Codicons, Octicons, FontAwesome, Seti/Devicons) icon definitions.
///
/// Uses 'NerdFont' (FiraCodeNerdFontPropo) font family configured in pubspec.yaml.
class NfIcons {
  static const String _fontFamily = 'NerdFont';

  // --- Explorer / Navigation (Codicons) ---
  /// Chevron right (arrow pointing right)
  static const IconData chevronRight = IconData(
    0xeab6,
    fontFamily: _fontFamily,
  );

  /// Chevron down (arrow pointing down)
  static const IconData chevronDown = IconData(0xeab4, fontFamily: _fontFamily);

  /// Chevron up (arrow pointing up)
  static const IconData chevronUp = IconData(0xeab7, fontFamily: _fontFamily);

  /// Chevron left (arrow pointing left)
  static const IconData chevronLeft = IconData(0xeab5, fontFamily: _fontFamily);

  // --- Folders & Files ---
  /// Folder (closed)
  static const IconData folder = IconData(0xea83, fontFamily: _fontFamily);

  /// Folder (open)
  static const IconData folderOpen = IconData(0xeaf7, fontFamily: _fontFamily);

  /// Folder with plus sign (New folder / Open folder)
  static const IconData folderPlus = IconData(0xea85, fontFamily: _fontFamily);

  /// Generic file
  static const IconData file = IconData(0xea7b, fontFamily: _fontFamily);

  /// File with code symbol
  static const IconData fileCode = IconData(0xea80, fontFamily: _fontFamily);

  /// File with text lines
  static const IconData fileText = IconData(0xeae0, fontFamily: _fontFamily);

  /// File with plus sign (New file)
  static const IconData filePlus = IconData(0xea7f, fontFamily: _fontFamily);

  /// File with binary / media
  static const IconData fileMedia = IconData(0xea7e, fontFamily: _fontFamily);

  // --- Actions & Controls ---
  /// Save / disk icon
  static const IconData save = IconData(0xeb4b, fontFamily: _fontFamily);

  /// Play / run icon
  static const IconData play = IconData(0xeb2c, fontFamily: _fontFamily);

  /// Stop / square icon
  static const IconData stop = IconData(0xf467, fontFamily: _fontFamily);

  /// Refresh / reload icon
  static const IconData refresh = IconData(0xeb37, fontFamily: _fontFamily);

  /// Close / X icon
  static const IconData close = IconData(0xea76, fontFamily: _fontFamily);

  /// Plus / add icon
  static const IconData add = IconData(0xea60, fontFamily: _fontFamily);

  /// Trash / delete icon
  static const IconData trash = IconData(0xea81, fontFamily: _fontFamily);

  /// Search / magnifying glass
  static const IconData search = IconData(0xea6d, fontFamily: _fontFamily);

  /// Settings / gear icon
  static const IconData settings = IconData(0xeaf8, fontFamily: _fontFamily);
  static const IconData gear = IconData(0xeaf8, fontFamily: _fontFamily);

  /// Extensions
  static const IconData extensions = IconData(0xeae6, fontFamily: _fontFamily);

  /// Theme / color palette / color mode (FontAwesome palette)
  static const IconData palette = IconData(0xf0e0c, fontFamily: _fontFamily);

  /// Profile / user account icon (FontAwesome user-circle)
  static const IconData profile = IconData(0xf2be, fontFamily: _fontFamily);

  /// GitHub brand icon
  static const IconData github = IconData(0xea84, fontFamily: _fontFamily);

  /// Dart programming language logo icon
  static const IconData dart = IconData(0xe64c, fontFamily: _fontFamily);

  /// Dot / status point icon
  static const IconData dot = IconData(0xf444, fontFamily: _fontFamily);

  /// Keymap / keyboard icon
  static const IconData keyboard = IconData(0xf11c, fontFamily: _fontFamily);

  /// Help Bird / heart icon
  static const IconData heart = IconData(0xeb05, fontFamily: _fontFamily);
  static const IconData help = IconData(0xeb05, fontFamily: _fontFamily);

  /// Terminal prompt icon
  static const IconData terminal = IconData(0xeb8d, fontFamily: _fontFamily);

  /// Split editor horizontal
  static const IconData splitHorizontal = IconData(
    0xeb56,
    fontFamily: _fontFamily,
  );

  /// Split editor vertical
  static const IconData splitVertical = IconData(
    0xeb57,
    fontFamily: _fontFamily,
  );

  /// Toggle primary sidebar (left) - Codicon layout-sidebar-left
  static const IconData layoutSidebarLeft = IconData(
    0xebf3,
    fontFamily: _fontFamily,
  );

  /// Toggle bottom panel - Codicon layout-panel
  static const IconData layoutPanelBottom = IconData(
    0xebf2,
    fontFamily: _fontFamily,
  );

  /// Toggle secondary sidebar (right) - Codicon layout-sidebar-right
  static const IconData layoutSidebarRight = IconData(
    0xebf4,
    fontFamily: _fontFamily,
  );

  /// Layout grid / panels
  static const IconData layout = IconData(0xea69, fontFamily: _fontFamily);

  /// Git branch / Source control
  static const IconData gitBranch = IconData(0xea68, fontFamily: _fontFamily);

  /// Debug / bug icon
  static const IconData debug = IconData(0xea86, fontFamily: _fontFamily);

  /// Check / checkmark
  static const IconData check = IconData(0xea6e, fontFamily: _fontFamily);

  /// Warning / triangle exclamation
  static const IconData warning = IconData(0xea6c, fontFamily: _fontFamily);

  /// Error / circle cross
  static const IconData error = IconData(0xeb11, fontFamily: _fontFamily);

  /// Info / circle info
  static const IconData info = IconData(0xea7a, fontFamily: _fontFamily);

  /// Restart / reload / sync
  static const IconData restart = IconData(0xea77, fontFamily: _fontFamily);

  // --- FontAwesome Fallback Alternatives (Thin / Crisp) ---
  static const IconData faFolder = IconData(0xf07b, fontFamily: _fontFamily);
  static const IconData faFolderOpen = IconData(
    0xf07c,
    fontFamily: _fontFamily,
  );
  static const IconData faSave = IconData(0xf0c7, fontFamily: _fontFamily);
  static const IconData faPlay = IconData(0xf04b, fontFamily: _fontFamily);
  static const IconData faClose = IconData(0xf00d, fontFamily: _fontFamily);
  static const IconData faChevronRight = IconData(
    0xf054,
    fontFamily: _fontFamily,
  );
  static const IconData faChevronDown = IconData(
    0xf078,
    fontFamily: _fontFamily,
  );
  static const IconData faPuzzlePiece = IconData(
    0xf12e,
    fontFamily: _fontFamily,
  );
  static const IconData faPalette = IconData(0xf53f, fontFamily: _fontFamily);
  static const IconData faTerminal = IconData(0xf120, fontFamily: _fontFamily);
  static const IconData faCode = IconData(0xf121, fontFamily: _fontFamily);
}
