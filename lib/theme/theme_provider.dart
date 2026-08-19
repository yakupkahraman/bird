import 'package:bird/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:re_highlight/styles/all.dart';

class ThemeProvider extends ChangeNotifier {
  static const String fallbackTheme = 'obsidian';

  SettingsProvider? _settings;

  /// Called from `ChangeNotifierProxyProvider` on every build, so it must be
  /// idempotent.
  void attachSettings(SettingsProvider settings) {
    if (identical(_settings, settings)) return;
    _settings?.removeListener(notifyListeners);
    _settings = settings;
    // The theme name lives in the settings file, so a change there — including
    // a hand edit — has to repaint the app.
    settings.addListener(notifyListeners);
  }

  String get themeName {
    final name =
        _settings?.colorTheme ??
        SettingsProvider.defaults['workbench.colorTheme'] as String;
    return builtinAllThemes.containsKey(name) ? name : fallbackTheme;
  }

  Map<String, TextStyle> get editorTheme =>
      builtinAllThemes[themeName] ?? builtinAllThemes[fallbackTheme]!;

  /// Returns once the choice has reached disk, so a caller can wait for it.
  Future<void> setTheme(String themeName) async {
    if (!builtinAllThemes.containsKey(themeName)) return;
    await _settings?.set('workbench.colorTheme', themeName);
  }

  Color get backgroundColor =>
      editorTheme['root']?.backgroundColor ?? const Color(0xFF1E1E1E);

  Color get foregroundColor => editorTheme['root']?.color ?? Colors.white70;

  Color get sidebarColor => HSLColor.fromColor(backgroundColor)
      .withLightness(
        (HSLColor.fromColor(backgroundColor).lightness - 0.02).clamp(0, 1),
      )
      .toColor();

  @override
  void dispose() {
    _settings?.removeListener(notifyListeners);
    super.dispose();
  }
}
