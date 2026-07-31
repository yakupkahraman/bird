import 'package:bird/file_provider.dart';
import 'package:bird/theme/theme_provider.dart';
import 'package:bird/widgets/file_tree_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExplorerPane extends StatelessWidget {
  final double minExplorerWidth;

  const ExplorerPane({super.key, this.minExplorerWidth = 150.0});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        if (fileProvider.rootPath == null) {
          return Container(
            width: minExplorerWidth,
            decoration: BoxDecoration(
              color: context.watch<ThemeProvider>().backgroundColor,
              border: const Border(
                right: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No folder opened',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Colors.grey[800]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => context.read<FileProvider>().pickFolder(),
                    icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                    label: const Text(
                      'Open Folder',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final folderName = fileProvider.rootPath!.split('/').last;

        return Container(
          width: minExplorerWidth,
          decoration: BoxDecoration(
            color: context.watch<ThemeProvider>().backgroundColor,
            border: const Border(
              right: BorderSide(color: Colors.white10, width: 0.5),
            ),
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
                child: SingleChildScrollView(
                  child: Consumer<FileProvider>(
                    builder: (context, fileProvider, child) {
                      return Column(
                        children: fileProvider.files
                            .map((e) => FileTreeItem(entity: e))
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
