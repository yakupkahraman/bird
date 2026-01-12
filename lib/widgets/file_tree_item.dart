import 'dart:io';

import 'package:bird_ce/file_provider.dart';
import 'package:bird_ce/theme/theme_provider.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FileTreeItem extends StatelessWidget {
  final FileSystemEntity entity;
  final int depth;

  const FileTreeItem({super.key, required this.entity, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<FileProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final name = entity.path.split(Platform.pathSeparator).last;
    final isDirectory = entity is Directory;
    final isExpanded = fileProvider.isExpanded(entity.path);

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (isDirectory) {
              fileProvider.toggleExpanded(entity.path);
            } else {
              fileProvider.openFile(entity.path);
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: 8.0 + (depth * 12.0),
              top: 4,
              bottom: 4,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: isDirectory
                      ? Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 16,
                          color: Colors.white54,
                        )
                      : null,
                ),
                isDirectory
                    ? Icon(Icons.folder, size: 18, color: Colors.amber[700])
                    : FileIcon(name, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: themeProvider.editorTheme['root']?.color
                          ?.withAlpha(200),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isDirectory && isExpanded)
          ...Directory(entity.path)
              .listSync()
              .map((e) => FileTreeItem(entity: e, depth: depth + 1))
              .toList(),
      ],
    );
  }
}
