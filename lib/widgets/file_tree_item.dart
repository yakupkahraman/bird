import 'package:bird/providers/file_tree_row.dart';
import 'package:bird/widgets/file_icon.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';

/// One row of the explorer.
///
/// Deliberately dumb: it watches no provider and touches no disk, so the
/// explorer can build it inside a `ListView.builder` and pay only for the rows
/// actually on screen.
class FileTreeItem extends StatelessWidget {
  const FileTreeItem({super.key, required this.row, required this.onTap});

  /// Fixed, so the list can place rows without measuring each one.
  static const double height = 24.0;

  final FileTreeRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 8.0 + row.depth * 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: row.isDirectory
                  ? Icon(
                      row.isExpanded
                          ? NfIcons.chevronDown
                          : NfIcons.chevronRight,
                      size: 14,
                      color: primary.withValues(alpha: 0.54),
                    )
                  : null,
            ),
            row.isDirectory
                ? Icon(
                    row.isExpanded ? NfIcons.folderOpen : NfIcons.folder,
                    size: 16,
                    color: Colors.amber[700],
                  )
                : FileIcon(row.name, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: primary.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
