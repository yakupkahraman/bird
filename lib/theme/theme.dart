import 'package:bird/theme/theme_provider.dart';
import 'package:flutter/material.dart';

ThemeData appTheme(ThemeProvider themeProvider) {
  final primaryColor = themeProvider.foregroundColor;
  final secondaryColor = themeProvider.sidebarColor;
  final bgColor = themeProvider.backgroundColor;
  final isLight = HSLColor.fromColor(bgColor).lightness > 0.5;

  return ThemeData(
    brightness: isLight ? Brightness.light : Brightness.dark,
    scaffoldBackgroundColor: bgColor,
    dividerColor: secondaryColor,
    colorScheme: ColorScheme(
      brightness: isLight ? Brightness.light : Brightness.dark,
      primary: primaryColor,
      onPrimary: bgColor,
      secondary: secondaryColor,
      onSecondary: primaryColor,
      surface: bgColor,
      onSurface: primaryColor,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
  );
}
