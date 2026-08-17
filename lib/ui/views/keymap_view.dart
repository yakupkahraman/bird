import 'package:bird/widgets/my_search.dart';
import 'package:flutter/material.dart';

class KeymapView extends StatefulWidget {
  const KeymapView({super.key});

  @override
  State<KeymapView> createState() => _KeymapViewState();
}

class _KeymapViewState extends State<KeymapView> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  final List<Map<String, String>> _shortcuts = const [
    {'command': 'Save File', 'keys': 'Ctrl+S / Cmd+S', 'category': 'File'},
    {
      'command': 'Open Folder / Project',
      'keys': 'Ctrl+O / Cmd+O',
      'category': 'File',
    },
    {
      'command': 'Toggle Left Sidebar (Explorer)',
      'keys': 'Ctrl+B',
      'category': 'View',
    },
    {
      'command': 'Toggle Bottom Panel (Terminal)',
      'keys': 'Ctrl+J',
      'category': 'View',
    },
    {
      'command': 'Toggle Right Sidebar',
      'keys': 'Ctrl+Alt+B',
      'category': 'View',
    },
    {
      'command': 'Close Active Editor Tab',
      'keys': 'Ctrl+W / Cmd+W',
      'category': 'Editor',
    },
    {'command': 'Format Document', 'keys': 'Shift+Alt+F', 'category': 'Editor'},
    {
      'command': 'Quick Open / Find File',
      'keys': 'Ctrl+P / Cmd+P',
      'category': 'Navigation',
    },
    {
      'command': 'Command Palette',
      'keys': 'Ctrl+Shift+P / Cmd+Shift+P',
      'category': 'General',
    },
    {
      'command': 'New Integrated Terminal',
      'keys': 'Ctrl+Shift+`',
      'category': 'Terminal',
    },
    {
      'command': 'Zoom In / Out Editor',
      'keys': 'Ctrl+= / Ctrl+-',
      'category': 'View',
    },
  ];

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

    final filteredList = _shortcuts.where((s) {
      if (_filter.isEmpty) return true;
      return s['command']!.toLowerCase().contains(_filter) ||
          s['keys']!.toLowerCase().contains(_filter) ||
          s['category']!.toLowerCase().contains(_filter);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Search Header
          MySearch(
            controller: _searchController,
            hintText: 'Type to search keyboard shortcuts...',
            onChanged: (val) =>
                setState(() => _filter = val.trim().toLowerCase()),
          ),

          // Shortcut Table
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 16.0,
              ),
              itemCount: filteredList.length,
              separatorBuilder: (_, _) =>
                  Divider(color: primary.withValues(alpha: 0.06), height: 1),
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 8.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['command']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: secondary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.18),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          item['keys']!,
                          style: TextStyle(
                            fontFamily: 'FiraCode',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: primary.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 90,
                        child: Text(
                          item['category']!,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: primary.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ],
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
