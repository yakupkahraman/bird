import 'package:bird/app/shell_page.dart';
import 'package:bird/features/theme/theme.dart';
import 'package:bird/features/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bird',
      theme: appTheme(themeProvider),
      home: ShellPage(),
    );
  }
}
