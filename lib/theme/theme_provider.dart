import 'package:flutter/material.dart';
import 'package:re_highlight/styles/all.dart';

class ThemeProvider extends ChangeNotifier {
  String _themeName = 'obsidian'; // Mevcut tema adı
  Map<String, TextStyle> _editorTheme = builtinAllThemes['obsidian']!;

  Map<String, TextStyle> get editorTheme => _editorTheme;
  String get themeName => _themeName; // Dışarıya açtık

  void setTheme(String themeName) {
    if (builtinAllThemes.containsKey(themeName)) {
      _themeName = themeName;
      _editorTheme = builtinAllThemes[themeName]!;
      notifyListeners();
    }
  }

  Color get backgroundColor =>
      _editorTheme['root']?.backgroundColor ?? const Color(0xFF1E1E1E);

  Color get foregroundColor => _editorTheme['root']?.color ?? Colors.white70;

  Color get sidebarColor => HSLColor.fromColor(backgroundColor)
      .withLightness(
        (HSLColor.fromColor(backgroundColor).lightness - 0.02).clamp(0, 1),
      )
      .toColor();
}
