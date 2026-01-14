import 'package:bird_ce/file_provider.dart';
import 'package:bird_ce/planguage_provider.dart';
import 'package:bird_ce/theme/theme_provider.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CodePage extends StatefulWidget {
  const CodePage({super.key});

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
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
