import 'package:bird/core/ui/my_search.dart';
import 'package:bird/features/commands/commands.dart';
import 'package:flutter/material.dart';

class KeymapView extends StatefulWidget {
  const KeymapView({super.key});

  @override
  State<KeymapView> createState() => _KeymapViewState();
}

class _KeymapViewState extends State<KeymapView> {
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

    // Straight off the registry, so what is listed here and what is actually
    // bound cannot disagree.
    final filteredList = Commands.all.where((command) {
      if (_filter.isEmpty) return true;
      return command.title.toLowerCase().contains(_filter) ||
          (command.key?.label.toLowerCase().contains(_filter) ?? false) ||
          command.category.toLowerCase().contains(_filter);
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
                final command = filteredList[index];
                // A command with no implementation is listed but dimmed: the
                // shortcut is documented, not working.
                final isLive = command.isImplemented;

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
                          command.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primary.withValues(alpha: isLive ? 1 : 0.45),
                          ),
                        ),
                      ),
                      if (!isLive)
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Text(
                            'not bound yet',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      if (command.key case final key?)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: secondary.withValues(
                              alpha: isLive ? 0.6 : 0.3,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: primary.withValues(
                                alpha: isLive ? 0.18 : 0.09,
                              ),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            key.label,
                            style: TextStyle(
                              fontFamily: 'FiraCode',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: primary.withValues(
                                alpha: isLive ? 0.85 : 0.4,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 90,
                        child: Text(
                          command.category,
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
