import 'package:bird_ce/theme/theme_provider.dart';
import 'package:flutter/material.dart';

ThemeData appTheme(ThemeProvider themeProvider) {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: themeProvider.backgroundColor,
    colorScheme: ColorScheme.dark(
      primary: themeProvider.foregroundColor,
      secondary: themeProvider.sidebarColor,
    ),
  );
}
