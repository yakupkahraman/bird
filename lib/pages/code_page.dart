import 'package:bird_ce/theme/theme_provider.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CodePage extends StatelessWidget {
  const CodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return CodeForge(
            innerPadding: EdgeInsets.only(top: 8.0),
            key: ValueKey(themeProvider.themeName),
            editorTheme: themeProvider.editorTheme,
            autoFocus: true,
          );
        },
      ),
    );
  }
}
