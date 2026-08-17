import 'package:bird/theme/theme_provider.dart';
import 'package:bird/widgets/my_search.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_highlight/styles/all.dart';

class ThemesView extends StatefulWidget {
  const ThemesView({super.key});

  @override
  State<ThemesView> createState() => _ThemesViewState();
}

class _ThemesViewState extends State<ThemesView> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final themeProvider = context.watch<ThemeProvider>();
    final currentTheme = themeProvider.themeName;

    final allThemes = builtinAllThemes.keys.where((t) {
      if (_filter.isEmpty) return true;
      return t.toLowerCase().contains(_filter);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Search header
          MySearch(
            controller: _searchController,
            hintText: 'Search color themes...',
            onChanged: (val) =>
                setState(() => _filter = val.trim().toLowerCase()),
          ),

          // Themes Grid / List
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(32.0),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 64,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: allThemes.length,
              itemBuilder: (context, index) {
                final name = allThemes[index];
                final isSelected = name == currentTheme;

                return InkWell(
                  onTap: () => context.read<ThemeProvider>().setTheme(name),
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary.withValues(alpha: 0.12)
                          : secondary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isSelected
                            ? primary.withValues(alpha: 0.6)
                            : primary.withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          NfIcons.palette,
                          size: 16,
                          color: isSelected
                              ? primary
                              : primary.withValues(alpha: 0.65),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? primary
                                  : primary.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(NfIcons.check, size: 14, color: primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
