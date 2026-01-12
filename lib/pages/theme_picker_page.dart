import 'package:bird_ce/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_highlight/styles/all.dart';

class ThemePickerPage extends StatelessWidget {
  const ThemePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.watch<ThemeProvider>().themeName;

    return Scaffold(
      body: ListView(
        children: builtinAllThemes.keys.map((themeName) {
          final isSelected = themeName == currentTheme;
          return ListTile(
            selected: isSelected,
            selectedTileColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            title: Text(
              themeName,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            onTap: () {
              context.read<ThemeProvider>().setTheme(themeName);
            },
          );
        }).toList(),
      ),
    );
  }
}
