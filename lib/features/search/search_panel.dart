import 'package:bird/core/ui/file_icon.dart';
import 'package:bird/core/ui/my_search.dart';
import 'package:bird/features/editor/tab_opener.dart';
import 'package:bird/features/search/search_provider.dart';
import 'package:dart_ripgrep/dart_ripgrep.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class SearchPanel extends StatefulWidget {
  const SearchPanel({super.key});

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  // Seeded from the provider: the panel is rebuilt from scratch whenever the
  // sidebar switches back to it, and the query should still be there.
  late final _controller = TextEditingController(
    text: context.read<SearchProvider>().query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final openTab = context.read<TabOpener>();
    final primary = Theme.of(context).colorScheme.primary;
    final hint = TextStyle(fontSize: 12, color: primary.withValues(alpha: 0.5));

    // Flattened so only the rows on screen are built: a file header, then
    // its matches.
    final rows = <(String, RgMatch?)>[
      for (final MapEntry(key: path, value: matches)
          in search.results.entries) ...[
        (path, null),
        for (final m in matches) (path, m),
      ],
    ];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          MySearch(
            controller: _controller,
            hintText: 'Search in files',
            padding: const EdgeInsets.all(8),
            autoFocus: true,
            onChanged: search.search,
          ),
          if (search.root == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Open a folder to search it', style: hint),
            )
          else if (search.query.isNotEmpty &&
              !search.isSearching &&
              rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('No results', style: hint),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemExtent: 22,
              itemBuilder: (context, index) {
                final (path, match) = rows[index];
                return InkWell(
                  onTap: () => openTab(path),
                  child: match == null
                      ? _FileHeader(
                          path: p.relative(path, from: search.root),
                          count: search.results[path]!.length,
                        )
                      : _MatchLine(match: match),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FileHeader extends StatelessWidget {
  const _FileHeader({required this.path, required this.count});

  final String path;
  final int count;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dir = p.dirname(path);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        spacing: 6,
        children: [
          FileIcon(path, size: 14),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: p.basename(path),
                style: TextStyle(fontSize: 13, color: primary),
                children: [
                  if (dir != '.')
                    TextSpan(
                      text: '  $dir',
                      style: TextStyle(
                        fontSize: 11,
                        color: primary.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              color: primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchLine extends StatelessWidget {
  const _MatchLine({required this.match});

  final RgMatch match;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final style = TextStyle(
      fontSize: 12,
      color: primary.withValues(alpha: 0.7),
    );
    final highlight = TextStyle(
      fontSize: 12,
      color: primary,
      backgroundColor: primary.withValues(alpha: 0.15),
    );

    // Indentation is dropped for display, so the ranges shift with it.
    final text = match.text;
    final indent = text.length - text.trimLeft().length;
    final spans = <TextSpan>[];
    var at = indent;
    for (final r in match.submatches) {
      final start = r.start.clamp(at, text.length);
      final end = r.end.clamp(start, text.length);
      spans
        ..add(TextSpan(text: text.substring(at, start)))
        ..add(TextSpan(text: text.substring(start, end), style: highlight));
      at = end;
    }
    spans.add(TextSpan(text: text.substring(at)));

    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(style: style, children: spans),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
