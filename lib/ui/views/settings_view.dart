import 'package:bird/providers/settings_provider.dart';
import 'package:bird/providers/tab_opener.dart';
import 'package:bird/widgets/my_button.dart';
import 'package:bird/widgets/mini_button.dart';
import 'package:bird/widgets/my_search.dart';
import 'package:bird/widgets/my_switch.dart';
import 'package:bird/widgets/my_tile.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  // Not persisted: nothing implements these yet, so a stored value would be a
  // setting that silently does nothing. See the Bird issue tracker.
  bool _formatOnSave = true;
  bool _autoSave = true;
  bool _minimap = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Search header
          MySearch(
            controller: _searchController,
            hintText: 'Search settings...',
            onChanged: (val) =>
                setState(() => _filter = val.trim().toLowerCase()),
          ),

          // Settings list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 24.0,
              ),
              children: [
                _buildSectionHeader('Configuration File', primary),
                _buildSettingTile(
                  title: 'Settings: User',
                  description: settings.userFile,
                  trailing: MyButton(
                    label: 'Open',
                    icon: NfIcons.fileCode,
                    width: 110,
                    variant: MyButtonVariant.outline,
                    onPressed: () => _openAsTab(settings.ensureUserFile()),
                  ),
                ),
                if (settings.workspaceFile case final path?)
                  _buildSettingTile(
                    title: 'Settings: Workspace',
                    description:
                        '$path\nCommitted with the project, and wins over your '
                        'own settings.',
                    trailing: MyButton(
                      label: 'Open',
                      icon: NfIcons.fileCode,
                      width: 110,
                      variant: MyButtonVariant.outline,
                      onPressed: () =>
                          _openAsTab(settings.ensureWorkspaceFile()),
                    ),
                  ),

                const SizedBox(height: 24),
                _buildSectionHeader('Editor: Formatting & Behavior', primary),
                _buildSettingTile(
                  title: 'Editor: Format On Save',
                  description:
                      'Automatically format files on save using Dart/Flutter formatter.',
                  trailing: MySwitch(
                    value: _formatOnSave,
                    onChanged: (val) => setState(() => _formatOnSave = val),
                  ),
                ),
                _buildSettingTile(
                  title: 'Editor: Word Wrap',
                  description:
                      'Controls how lines should wrap in the code editor.',
                  trailing: MySwitch(
                    value: settings.editorWordWrap,
                    onChanged: (val) => settings.set('editor.wordWrap', val),
                  ),
                ),
                _buildSettingTile(
                  title: 'Editor: Line Numbers',
                  description:
                      'Controls the display of line numbers in the editor margin.',
                  trailing: MySwitch(
                    value: settings.editorLineNumbers,
                    onChanged: (val) => settings.set('editor.lineNumbers', val),
                  ),
                ),
                _buildSettingTile(
                  title: 'Editor: Minimap',
                  description:
                      'Controls whether the editor minimap is shown on the right side.',
                  trailing: MySwitch(
                    value: _minimap,
                    onChanged: (val) => setState(() => _minimap = val),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Files & Autosave', primary),
                _buildSettingTile(
                  title: 'Files: Auto Save',
                  description:
                      'Automatically save dirty editors after a brief delay or when switching tabs.',
                  trailing: MySwitch(
                    value: _autoSave,
                    onChanged: (val) => setState(() => _autoSave = val),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Font & Typography', primary),
                _buildSettingTile(
                  title: 'Editor: Font Size',
                  description:
                      'Controls the font size in pixels for the code editor area.',
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
                _buildSettingTile(
                  title: 'Editor: Tab Size',
                  description: 'The number of spaces a tab is equal to.',
                  trailing: _buildStepper(
                    label: '${settings.editorTabSize} spaces',
                    primary: primary,
                    onDecrease: settings.editorTabSize > 1
                        ? () => settings.set(
                            'editor.tabSize',
                            settings.editorTabSize - 1,
                          )
                        : null,
                    onIncrease: settings.editorTabSize < 8
                        ? () => settings.set(
                            'editor.tabSize',
                            settings.editorTabSize + 1,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a settings file in Bird itself, the same way the explorer opens any
  /// other file. Providers are read up front, so nothing touches the context
  /// after the file has been created.
  Future<void> _openAsTab(Future<String?> file) async {
    final openTab = context.read<TabOpener>();

    final path = await file;
    if (path == null) return;
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

  Widget _buildSectionHeader(String title, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String description,
    required Widget trailing,
  }) {
    if (_filter.isNotEmpty &&
        !title.toLowerCase().contains(_filter) &&
        !description.toLowerCase().contains(_filter)) {
      return const SizedBox.shrink();
    }

    return MyTile(title: title, subtitle: description, trailing: trailing);
  }
}
