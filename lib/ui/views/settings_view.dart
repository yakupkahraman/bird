import 'package:bird/providers/settings_provider.dart';
import 'package:bird/providers/tab_opener.dart';
import 'package:bird/ui/views/settings/flutter_sdk_manager.dart';
import 'package:bird/theme/theme_provider.dart';
import 'package:bird/widgets/mini_button.dart';
import 'package:bird/widgets/my_button.dart';
import 'package:bird/widgets/my_switch.dart';
import 'package:bird/widgets/my_tile.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:bird/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_highlight/styles/all.dart';

enum SettingsCategory {
  editor(label: 'Editor', icon: NfIcons.editor),
  appearance(label: 'Appearance', icon: NfIcons.palette),
  flutter(label: 'Flutter SDK', icon: NfIcons.flutter);

  final String label;
  final IconData icon;

  const SettingsCategory({required this.label, required this.icon});
}

/// Settings modal dialog featuring a categorized sidebar and dedicated
/// configuration bodies for Editor, Appearance, and Flutter SDK Management.
class SettingsView extends StatefulWidget {
  final SettingsCategory initialCategory;

  const SettingsView({
    super.key,
    this.initialCategory = SettingsCategory.editor,
  });

  /// Opens the Settings as a modal dialog using showDialog.
  static Future<void> show(
    BuildContext context, {
    SettingsCategory initialCategory = SettingsCategory.editor,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) => SettingsView(initialCategory: initialCategory),
    );
  }

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late SettingsCategory _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _dismissDialog() {
    if (!mounted) return;
    final isModal = ModalRoute.of(context) is PopupRoute;
    if (isModal && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: primary.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 840,
            maxHeight: 560,
            minWidth: 480,
            minHeight: 360,
          ),
          child: SizedBox(
            width: 840,
            height: 560,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Row(
                children: [
                  // Left Sidebar Navigation
                  Container(
                    width: 210,
                    color: secondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sidebar Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Row(
                            children: [
                              Icon(NfIcons.settings, size: 16, color: primary),
                              const SizedBox(width: 8),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Compact Search Input
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: primary.withValues(alpha: 0.15),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Icon(
                                  NfIcons.search,
                                  size: 12,
                                  color: primary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) => setState(
                                      () => _filter = val.trim().toLowerCase(),
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search...',
                                      hintStyle: TextStyle(
                                        fontSize: 12,
                                        color: primary.withValues(alpha: 0.4),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_filter.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _filter = '');
                                    },
                                    child: Icon(
                                      NfIcons.close,
                                      size: 11,
                                      color: primary.withValues(alpha: 0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Category Navigation Items
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              for (final cat in SettingsCategory.values)
                                _buildSidebarItem(cat, primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical Divider
                  Container(width: 1, color: primary.withValues(alpha: 0.12)),

                  // Right Main Content Area
                  Expanded(
                    child: Column(
                      children: [
                        // Header Bar with Title and Close Button
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            border: Border(
                              bottom: BorderSide(
                                color: primary.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _filter.isEmpty
                                    ? _selectedCategory.label
                                    : 'Search results',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                              ),
                              const Spacer(),
                              MiniButton(
                                icon: NfIcons.close,
                                tooltip: 'Close',
                                onPressed: _dismissDialog,
                              ),
                            ],
                          ),
                        ),

                        // Scrollable Category Content
                        Expanded(
                          child: Container(
                            color: theme.scaffoldBackgroundColor,
                            child: _buildCategoryContent(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(SettingsCategory category, Color primary) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openCategory(category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  category.icon,
                  size: 14,
                  color: isSelected ? primary : primary.withValues(alpha: 0.65),
                ),
                const SizedBox(width: 10),
                Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? primary
                        : primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The body under the header bar: one category, or — while searching —
  /// everything that matches, wherever it lives.
  Widget _buildCategoryContent(BuildContext context) {
    if (_filter.isEmpty) {
      // The SDK page brings its own scroll view and does not fit the row shape.
      if (_selectedCategory == SettingsCategory.flutter) {
        return const FlutterSdkManager();
      }
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: _categorySettings(context, _selectedCategory),
      );
    }

    final results = [
      for (final category in SettingsCategory.values)
        ..._categorySettings(context, category),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: results.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'No setting matches "${_searchController.text.trim()}".',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ]
          : results,
    );
  }

  List<Widget> _categorySettings(
    BuildContext context,
    SettingsCategory category,
  ) => switch (category) {
    SettingsCategory.editor => _editorSettings(context),
    SettingsCategory.appearance => _appearanceSettings(context),
    // The SDK page is a workflow rather than a list of rows, so a search offers
    // the way in instead of trying to reproduce it here.
    SettingsCategory.flutter => _section(category, 'Flutter SDK', [
      _tile(
        title: 'Flutter SDK',
        description:
            'Pick the SDK Bird uses, install a bundled one, switch '
            'channel or run doctor.',
        keywords:
            'flutter sdk bundled system custom channel doctor '
            'install upgrade dart version path',
        trailing: MyButton(
          label: 'Open',
          icon: NfIcons.flutter,
          variant: MyButtonVariant.outline,
          onPressed: () => _openCategory(SettingsCategory.flutter),
        ),
      ),
    ]),
  };

  List<Widget> _editorSettings(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final settings = context.watch<SettingsProvider>();
    const category = SettingsCategory.editor;

    return [
      ..._section(category, 'Configuration File', [
        _tile(
          title: 'Settings: User',
          description: settings.userFile,
          keywords: 'json file config',
          trailing: MyButton(
            label: 'Open',
            icon: NfIcons.fileCode,
            variant: MyButtonVariant.outline,
            onPressed: () => _openAsTab(settings.ensureUserFile()),
          ),
        ),
        if (settings.workspaceFile case final path?)
          _tile(
            title: 'Settings: Workspace',
            description:
                '$path\nCommitted with the project and takes priority.',
            keywords: 'json file config project',
            trailing: MyButton(
              label: 'Open',
              icon: NfIcons.fileCode,
              variant: MyButtonVariant.outline,
              onPressed: () => _openAsTab(settings.ensureWorkspaceFile()),
            ),
          ),
      ]),
      ..._section(category, 'Editor Behavior & Formatting', [
        _tile(
          title: 'Editor: Word Wrap',
          description: 'Controls how lines should wrap in the code editor.',
          trailing: MySwitch(
            value: settings.editorWordWrap,
            onChanged: (val) => settings.set('editor.wordWrap', val),
          ),
        ),
        _tile(
          title: 'Editor: Line Numbers',
          description:
              'Controls the display of line numbers in the editor margin.',
          trailing: MySwitch(
            value: settings.editorLineNumbers,
            onChanged: (val) => settings.set('editor.lineNumbers', val),
          ),
        ),
      ]),
      ..._section(category, 'Indentation', [
        _tile(
          title: 'Editor: Tab Size',
          description: 'The number of spaces a tab is equal to.',
          keywords: 'indent spaces',
          trailing: _buildStepper(
            label: '${settings.editorTabSize} spaces',
            primary: primary,
            onDecrease: settings.editorTabSize > 1
                ? () =>
                      settings.set('editor.tabSize', settings.editorTabSize - 1)
                : null,
            onIncrease: settings.editorTabSize < 8
                ? () =>
                      settings.set('editor.tabSize', settings.editorTabSize + 1)
                : null,
          ),
        ),
      ]),
    ];
  }

  List<Widget> _appearanceSettings(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currentTheme = themeProvider.themeName;
    const category = SettingsCategory.appearance;

    final themesList = builtinAllThemes.keys.toList();
    final effectiveTheme = builtinAllThemes.containsKey(currentTheme)
        ? currentTheme
        : (themesList.contains('vs2015') ? 'vs2015' : themesList.first);

    return [
      ..._section(category, 'Color Theme', [
        _tile(
          title: 'Workbench Theme',
          description:
              'Active editor and interface color theme ($currentTheme).',
          keywords: 'colour dark light syntax',
          trailing: Container(
            width: 170,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: primary.withValues(alpha: 0.15)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: effectiveTheme,
                isExpanded: true,
                dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                icon: Icon(NfIcons.chevronDown, size: 12, color: primary),
                style: TextStyle(
                  fontSize: 12,
                  color: primary,
                  fontFamily: 'FiraCode',
                ),
                items: themesList.map((t) {
                  return DropdownMenuItem<String>(
                    value: t,
                    child: Text(t, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newTheme) {
                  if (newTheme != null) themeProvider.setTheme(newTheme);
                },
              ),
            ),
          ),
        ),
      ]),
      ..._section(category, 'Font & Typography', [
        _tile(
          title: 'Editor: Font Size',
          description:
              'Controls the font size in pixels for the code editor area.',
          keywords: 'text zoom',
          trailing: _buildStepper(
            label: '${settings.editorFontSize.toInt()} px',
            primary: primary,
            onDecrease: settings.editorFontSize > 8
                ? () => settings.set(
                    'editor.fontSize',
                    settings.editorFontSize.toInt() - 1,
                  )
                : null,
            onIncrease: settings.editorFontSize < 32
                ? () => settings.set(
                    'editor.fontSize',
                    settings.editorFontSize.toInt() + 1,
                  )
                : null,
          ),
        ),
      ]),
    ];
  }

  /// A group of rows, dropped whole when the search matched none of them. While
  /// searching the heading names the category too, since results from all of
  /// them are on screen at once.
  List<Widget> _section(
    SettingsCategory category,
    String heading,
    List<Widget?> tiles,
  ) {
    final rows = tiles.nonNulls.toList();
    if (rows.isEmpty) return const [];
    return [
      SectionHeader(_filter.isEmpty ? heading : '${category.label} > $heading'),
      ...rows,
      const SizedBox(height: 20),
    ];
  }

  /// One row, or null when the search leaves it out. [keywords] are searched
  /// but not shown, for the words people type that the row does not say.
  Widget? _tile({
    required String title,
    required String description,
    required Widget trailing,
    String keywords = '',
  }) {
    if (_filter.isNotEmpty &&
        !'$title $description $keywords'.toLowerCase().contains(_filter)) {
      return null;
    }
    return MyTile(title: title, subtitle: description, trailing: trailing);
  }

  /// Leaves the search and shows [category] on its own.
  void _openCategory(SettingsCategory category) {
    _searchController.clear();
    setState(() {
      _filter = '';
      _selectedCategory = category;
    });
  }

  Future<void> _openAsTab(Future<String?> file) async {
    final openTab = context.read<TabOpener>();
    final path = await file;
    if (path == null || !mounted) return;
    _dismissDialog();
    await openTab(path);
  }

  Widget _buildStepper({
    required String label,
    required Color primary,
    VoidCallback? onDecrease,
    VoidCallback? onIncrease,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniButton(
          icon: NfIcons.minus,
          tooltip: 'Decrease',
          onPressed: onDecrease,
        ),
        SizedBox(
          width: 76,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ),
        MiniButton(
          icon: NfIcons.add,
          tooltip: 'Increase',
          onPressed: onIncrease,
        ),
      ],
    );
  }
}
