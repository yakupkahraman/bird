import 'dart:io';

import 'package:bird/providers/file_provider.dart';
import 'package:bird/ui/panels/explorer_panel.dart';
import 'package:bird/widgets/file_tree_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// A root holding [folders] folders of [perFolder] files each.
Directory makeTree(int folders, int perFolder) {
  final root = Directory.systemTemp.createTempSync('bird_tree');
  for (var i = 0; i < folders; i++) {
    final directory = Directory('${root.path}/folder_$i')..createSync();
    for (var j = 0; j < perFolder; j++) {
      File('${directory.path}/file_$j.dart').writeAsStringSync('// x');
    }
  }
  return root;
}

Widget explorer(FileProvider files) => ChangeNotifierProvider.value(
  value: files,
  child: const MaterialApp(home: Scaffold(body: ExplorerPanel())),
);

void main() {
  late Directory root;
  late FileProvider files;

  Future<void> open(
    int folders,
    int perFolder, {
    bool expandAll = false,
  }) async {
    root = makeTree(folders, perFolder);
    files = FileProvider();
    await files.openFolder(root.path);
    if (expandAll) {
      for (final entity in Directory(root.path).listSync()) {
        if (entity is Directory) files.toggleExpanded(entity.path);
      }
    }
  }

  tearDown(() {
    files.dispose();
    root.deleteSync(recursive: true);
  });

  test('a collapsed root only contributes its own children', () async {
    await open(3, 5);

    expect(files.visibleRows, hasLength(3));
    expect(files.visibleRows.every((row) => row.isDirectory), isTrue);
    expect(files.visibleRows.every((row) => row.depth == 0), isTrue);
  });

  test('expanding a folder inserts its children below it', () async {
    await open(2, 4);
    final folder = files.visibleRows.first;

    files.toggleExpanded(folder.path);

    final rows = files.visibleRows;
    expect(rows, hasLength(2 + 4));
    expect(rows.first.isExpanded, isTrue);
    expect(rows[1].depth, 1);
    expect(rows[1].isDirectory, isFalse);
    // The second folder stays put, after the expanded one's children.
    expect(rows.last.depth, 0);
  });

  test('collapsing removes them again', () async {
    await open(2, 4);
    final folder = files.visibleRows.first.path;

    files.toggleExpanded(folder);
    files.toggleExpanded(folder);

    expect(files.visibleRows, hasLength(2));
  });

  testWidgets('the work does not grow with the tree', (tester) async {
    await open(20, 30, expandAll: true);
    expect(files.visibleRows, hasLength(620));

    await tester.pumpWidget(explorer(files));
    final small = tester.widgetList(find.byType(FileTreeItem)).length;

    // tearDown only sees the last tree, so retire this one by hand.
    files.dispose();
    root.deleteSync(recursive: true);

    await open(200, 30, expandAll: true);
    expect(files.visibleRows, hasLength(6200));

    await tester.pumpWidget(explorer(files));
    final large = tester.widgetList(find.byType(FileTreeItem)).length;

    // Ten times the tree, the same number of rows built: the list pays for
    // the viewport, not the file count. Building all of them is what used to
    // cost ~84ms per rebuild and grew from there.
    expect(large, small);
    expect(small, lessThan(60));
  });
}
