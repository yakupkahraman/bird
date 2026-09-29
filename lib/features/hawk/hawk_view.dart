import 'package:bird/core/ui/my_search.dart';
import 'package:bird/features/hawk/hawk.dart';
import 'package:bird/features/hawk/hawk_sources.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hawk: the search box at the top of the window. Type, pick, go.
///
/// Knows nothing about what it lists; see [HawkSource].
class HawkView extends StatefulWidget {
  const HawkView({super.key, this.sources = HawkSources.all});

  final List<HawkSource> sources;

  static const _rowHeight = 28.0;

  /// Opens Hawk and runs whatever the user picks.
  static Future<void> show(
    BuildContext context, {
    List<HawkSource> sources = HawkSources.all,
  }) async {
    final item = await showDialog<HawkItem>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (_) => HawkView(sources: sources),
    );
    // Run from the caller's context, not Hawk's: Hawk is gone
    // by now, and an item may open a dialog of its own.
    if (item != null && context.mounted) item.run(context);
  }

  @override
  State<HawkView> createState() => _HawkViewState();
}

class _HawkViewState extends State<HawkView> {
  final _scroll = ScrollController();
  String _query = '';
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    for (final source in widget.sources) {
      source.onOpen(context);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(int delta, int count) {
    if (count == 0) return;
    setState(() => _selected = (_selected + delta).clamp(0, count - 1));
    if (!_scroll.hasClients) return;
    // Keep the selected row in view as the arrows walk past the edge.
    const height = HawkView._rowHeight;
    final top = _selected * height;
    final viewport = _scroll.position.viewportDimension;
    if (top < _scroll.offset) {
      _scroll.jumpTo(top);
    } else if (top + height > _scroll.offset + viewport) {
      _scroll.jumpTo(top + height - viewport);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final items = [
      for (final source in widget.sources) ...source.search(context, _query),
    ];
    final selected = items.isEmpty ? -1 : _selected.clamp(0, items.length - 1);
    void choose(int index) => Navigator.pop(context, items[index]);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            color: theme.scaffoldBackgroundColor,
            elevation: 12,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                        _move(1, items.length),
                    const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                        _move(-1, items.length),
                  },
                  child: MySearch(
                    hintText: 'Search with Hawk',
                    padding: const EdgeInsets.all(8),
                    autoFocus: true,
                    onChanged: (query) => setState(() {
                      _query = query;
                      _selected = 0;
                    }),
                    // From state, not the build's copy: an arrow press and
                    // enter can both land before the next frame.
                    onSubmitted: (_) {
                      if (items.isNotEmpty) {
                        choose(_selected.clamp(0, items.length - 1));
                      }
                    },
                  ),
                ),
                if (items.isEmpty && _query.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No results',
                      style: TextStyle(
                        fontSize: 12,
                        color: primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                if (items.isNotEmpty)
                  // Flexible so a short window shrinks the list rather than
                  // overflowing it; 360 is the cap when there is room.
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.builder(
                        controller: _scroll,
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: items.length,
                        itemExtent: HawkView._rowHeight,
                        itemBuilder: (context, index) => _HawkRow(
                          item: items[index],
                          isSelected: index == selected,
                          onTap: () => choose(index),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HawkRow extends StatelessWidget {
  const _HawkRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final HawkItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? primary.withValues(alpha: 0.12) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          spacing: 8,
          children: [
            ?item.leading,
            Flexible(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: primary),
              ),
            ),
            if (item.detail case final detail?)
              Expanded(
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
