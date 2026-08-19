import 'package:bird/providers/file_provider.dart';
import 'package:bird/widgets/file_tree_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExplorerPanel extends StatelessWidget {
  const ExplorerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        if (fileProvider.rootPath == null) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Center(
              child: Text(
                'No folder opened',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }

        final folderName = fileProvider.rootPath!.split('/').last;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  folderName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.primary.withAlpha(180),
                  ),
                ),
              ),
              Expanded(
                // Only the rows on screen are built. The tree used to be a
                // Column of recursive widgets, which built every row in the
                // whole expanded tree — and read the disk for each folder —
                // on every rebuild.
                child: Builder(
                  builder: (context) {
                    final rows = fileProvider.visibleRows;
                    return ListView.builder(
                      itemCount: rows.length,
                      itemExtent: FileTreeItem.height,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return FileTreeItem(
                          row: row,
                          onTap: () => row.isDirectory
                              ? fileProvider.toggleExpanded(row.path)
                              : fileProvider.openFile(row.path),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
