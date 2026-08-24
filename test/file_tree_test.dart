import 'package:bird/features/editor/tab_opener.dart';
import 'package:bird/features/workspace/explorer_panel.dart';
import 'package:bird/features/workspace/file_tree_item.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:bird/features/workspace/workspace_service.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// A root holding [folders] folders of [perFolder] files each.
///
/// In memory: the largest tree here is 6200 entries, and creating those for
/// real spent the test's time on the disk rather than on the question.
Directory makeTree(FileSystem fs, int folders, int perFolder) {
  final root = fs.directory('/workspace')..createSync();
  for (var i = 0; i < folders; i++) {
    final directory = fs.directory('${root.path}/folder_$i')..createSync();
    for (var j = 0; j < perFolder; j++) {
      fs.file('${directory.path}/file_$j.dart').writeAsStringSync('// x');
    }
  }
  return root;
}

Future<void> ignoreOpen(String path) async {}

Widget explorer(WorkspaceProvider workspace) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: workspace),
    Provider<TabOpener>.value(value: ignoreOpen),
  ],
  child: const MaterialApp(home: Scaffold(body: ExplorerPanel())),
);

void main() {
  late MemoryFileSystem fs;
  late Directory root;
  late WorkspaceProvider files;

  Future<void> open(
    int folders,
    int perFolder, {
    bool expandAll = false,
  }) async {
    fs = MemoryFileSystem();
    root = makeTree(fs, folders, perFolder);
    files = WorkspaceProvider(service: WorkspaceService(fileSystem: fs));
    await files.openFolder(root.path);
    if (expandAll) {
      for (final entity in fs.directory(root.path).listSync()) {
        if (entity is Directory) files.toggleExpanded(entity.path);
      }
    }
  }

  tearDown(() => files.dispose());

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

  test('a folder that cannot be read shows up empty', () async {
    await open(1, 1);

    files.toggleExpanded('${root.path}/nowhere');

    // The listing throws, and the tree answers with no children rather than
    // taking the app down with it.
    expect(files.visibleRows, hasLength(1));
  });

  testWidgets('the work does not grow with the tree', (tester) async {
    await open(20, 30, expandAll: true);
    expect(files.visibleRows, hasLength(620));

    await tester.pumpWidget(explorer(files));
    final small = tester.widgetList(find.byType(FileTreeItem)).length;

    // tearDown only sees the last tree, so retire this one by hand.
    files.dispose();

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
