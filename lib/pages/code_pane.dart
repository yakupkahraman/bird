import 'package:bird/file_provider.dart';
import 'package:bird/planguage_provider.dart';
import 'package:bird/theme/theme_provider.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CodePane extends StatefulWidget {
  const CodePane({super.key});

  @override
  State<CodePane> createState() => _CodePaneState();
}

class _CodePaneState extends State<CodePane> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<ThemeProvider, FileProvider, PlanguageProvider>(
        builder: (context, themeProvider, fileProvider, languageProvider, child) {
          return CodeForge(
            key: ValueKey(
              '${themeProvider.themeName}-${languageProvider.currentLanguage.name}',
            ),
            innerPadding: EdgeInsets.only(top: 8.0),
            editorTheme: themeProvider.editorTheme,
            autoFocus: true,
            controller: fileProvider.controller,
            language: languageProvider.currentLanguage.mode,
          );
        },
      ),
    );
  }
}
