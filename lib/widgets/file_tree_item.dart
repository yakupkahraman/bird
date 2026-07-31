import 'dart:io';

import 'package:bird/providers/file_provider.dart';
import 'package:bird/providers/prog_lang_provider.dart';
import 'package:bird/widgets/re_icon.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

class FileTreeItem extends StatelessWidget {
  final FileSystemEntity entity;
  final int depth;

  const FileTreeItem({super.key, required this.entity, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<FileProvider>();
    final languageProvider = context.read<ProgLangProvider>();
    final name = entity.path.split(Platform.pathSeparator).last;
    final isDirectory = entity is Directory;
    final isExpanded = fileProvider.isExpanded(entity.path);
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (isDirectory) {
              fileProvider.toggleExpanded(entity.path);
            } else {
              fileProvider.openFile(entity.path, languageProvider);
              final isSupported =
                  languageProvider.getLanguageNameByFilePath(entity.path) !=
                  null;
              if (!isSupported) {
                final extension = name.contains('.')
                    ? name.substring(name.lastIndexOf('.'))
                    : 'unknown';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unsupported file type: $extension\nUsing ${languageProvider.currentLanguage.displayName} highlighting.',
                    ),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
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
                      ? ReIcon(
                          isExpanded
                              ? Reicon.outline.chevronDown
                              : Reicon.outline.chevronRight,
                          size: 16,
                          color: primary.withValues(alpha: 0.54),
                        )
                      : null,
                ),
                isDirectory
                    ? ReIcon(
                        Reicon.filled.folder,
                        size: 18,
                        color: Colors.amber[700],
                      )
                    : FileIcon(name, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: primary.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isDirectory && isExpanded)
          ...Directory(
            entity.path,
          ).listSync().map((e) => FileTreeItem(entity: e, depth: depth + 1)),
      ],
    );
  }
}
