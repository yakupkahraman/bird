import 'package:bird/core/fuzzy.dart';
import 'package:bird/core/ui/file_icon.dart';
import 'package:bird/features/editor/tab_opener.dart';
import 'package:bird/features/hawk/hawk.dart';
import 'package:bird/features/search/file_index_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

/// Files of the open folder, matched by name, for Hawk.
class FileSource extends HawkSource {
  const FileSource();

  static const _limit = 50;

  @override
  void onOpen(BuildContext context) =>
      context.read<FileIndexProvider>().refresh();

  @override
  List<HawkItem> search(BuildContext context, String query) {
    final index = context.watch<FileIndexProvider>();
    final root = index.root;
    if (query.isEmpty || root == null) return const [];

    final scored = <(int, String)>[];
    for (final path in index.files) {
      final relative = p.relative(path, from: root);
      final score = fuzzyScore(query, relative);
      if (score == null) continue;
      // A hit in the file name beats the same letters spread over folders.
      final nameScore = fuzzyScore(query, p.basename(relative)) ?? 0;
      scored.add((score + nameScore * 2, relative));
    }
    scored.sort(
      (a, b) => a.$1 != b.$1 ? b.$1 - a.$1 : a.$2.length - b.$2.length,
    );

    return [
      for (final (_, relative) in scored.take(_limit))
        HawkItem(
          title: p.basename(relative),
          detail: p.dirname(relative) == '.' ? null : p.dirname(relative),
          leading: FileIcon(relative, size: 14),
          run: (context) => context.read<TabOpener>()(p.join(root, relative)),
        ),
    ];
  }
}
