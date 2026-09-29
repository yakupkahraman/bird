import 'dart:async';

import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:bird/features/search/search_provider.dart';
import 'package:bird/features/search/search_service.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:bird/features/workspace/workspace_service.dart';
import 'package:dart_ripgrep/dart_ripgrep.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hands out one controller per search instead of running ripgrep.
class FakeSearchService extends SearchService {
  final searches = <StreamController<RgMatch>>[];

  @override
  Stream<RgMatch> search(String query, String root, {int limit = 2000}) {
    final controller = StreamController<RgMatch>();
    searches.add(controller);
    return controller.stream;
  }
}

RgMatch match(String path, int line) => RgMatch(path, line, 'x', const []);

void main() {
  late FakeSearchService service;
  late NotificationsProvider notifications;
  late WorkspaceProvider workspace;
  late SearchProvider search;

  setUp(() async {
    final fs = MemoryFileSystem();
    fs.directory('/a').createSync();
    fs.directory('/b').createSync();
    service = FakeSearchService();
    notifications = NotificationsProvider();
    workspace = WorkspaceProvider(service: WorkspaceService(fileSystem: fs));
    await workspace.openFolder('/a');
    search = SearchProvider(service: service)
      ..attachWorkspace(workspace)
      ..attachNotifications(notifications);
  });

  tearDown(() {
    search.dispose();
    workspace.dispose();
    notifications.dispose();
  });

  test('groups matches by file in the order they arrive', () async {
    search.search('x');
    service.searches.single
      ..add(match('/a/one.dart', 1))
      ..add(match('/a/two.dart', 4))
      ..add(match('/a/one.dart', 9));
    await pumpEventQueue();

    expect(search.results.keys, ['/a/one.dart', '/a/two.dart']);
    expect(search.results['/a/one.dart']!.map((m) => m.lineNumber), [1, 9]);
  });

  test('a new query cancels the running search', () async {
    search.search('x');
    search.search('xy');
    await pumpEventQueue();

    // Cancelling is what kills ripgrep; a live listener would mean a process
    // still running for a query nobody sees.
    expect(service.searches.first.hasListener, isFalse);
    expect(service.searches.last.hasListener, isTrue);
  });

  test('an empty query clears without searching', () {
    search.search('');

    expect(service.searches, isEmpty);
    expect(search.isSearching, isFalse);
  });

  test('opening another folder drops the results', () async {
    search.search('x');
    service.searches.single.add(match('/a/one.dart', 1));
    await pumpEventQueue();

    await workspace.openFolder('/b');

    expect(search.results, isEmpty);
    expect(search.query, isEmpty);
    expect(search.root, '/b');
  });

  test('a missing ripgrep is reported, a partial error is not', () async {
    search.search('x');
    service.searches.single
      ..add(match('/a/one.dart', 1))
      ..addError(const RgException(2, 'permission denied'));
    await service.searches.single.close();
    await pumpEventQueue();

    expect(notifications.items, isEmpty);
    expect(search.results, hasLength(1));
    expect(search.isSearching, isFalse);

    search.search('y');
    service.searches.last.addError(StateError('Bundled ripgrep not found'));
    await pumpEventQueue();

    expect(notifications.items.single.message, 'Search failed');
  });
}
