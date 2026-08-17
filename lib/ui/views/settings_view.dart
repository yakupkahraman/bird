import 'package:bird/widgets/my_search.dart';
import 'package:bird/widgets/my_switch.dart';
import 'package:bird/widgets/my_tile.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  bool _formatOnSave = true;
  bool _autoSave = true;
  bool _wordWrap = false;
  bool _lineNumbers = true;
  bool _minimap = false;
  final int _tabSize = 2;
  final double _fontSize = 13.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
                    value: _wordWrap,
                    onChanged: (val) => setState(() => _wordWrap = val),
                  ),
                ),
                _buildSettingTile(
                  title: 'Editor: Line Numbers',
                  description:
                      'Controls the display of line numbers in the editor margin.',
                  trailing: MySwitch(
                    value: _lineNumbers,
                    onChanged: (val) => setState(() => _lineNumbers = val),
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
                  trailing: Text(
                    '${_fontSize.toInt()} px',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
                _buildSettingTile(
                  title: 'Editor: Tab Size',
                  description: 'The number of spaces a tab is equal to.',
                  trailing: Text(
                    '$_tabSize spaces',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
