import 'package:bird_ce/file_provider.dart';
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
      body: Consumer2<ThemeProvider, FileProvider>(
        builder: (context, themeProvider, fileProvider, child) {
          return CodeForge(
            key: ValueKey(themeProvider.themeName),
            innerPadding: EdgeInsets.only(top: 8.0),
            editorTheme: themeProvider.editorTheme,
            autoFocus: true,
            controller: fileProvider.controller,
          );
        },
      ),
    );
  }
}
