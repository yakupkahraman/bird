import 'dart:async';
import 'dart:io';

import 'package:bird/core/result.dart';
import 'package:bird/features/internal_views/internal_views.dart';
import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:bird/features/pub/pub_package.dart';
import 'package:bird/features/pub/pub_provider.dart';
import 'package:bird/features/pub/pub_service.dart';
import 'package:bird/features/pub/pub_view.dart';
import 'package:bird/features/sdk/flutter_sdk.dart';
import 'package:bird/features/sdk/flutter_sdk_provider.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// pub.dev and `flutter pub` without the network or a real project.
class FakePubService extends PubService {
  final searches = <String, Completer<List<String>>>{};
  final commands = <String>[];
  var dependencyList = <Dependency>[];
  Object? failWith;

  @override
  Future<List<String>> search(String query) =>
      (searches[query] = Completer()).future;

  final readmeRequests = <String>[];

  @override
  Future<PubPackage> package(String name) async =>
      PubPackage(name: name, version: '1.0.0', description: '');

  @override
  Future<({String path, String text})?> document(
    String name,
    String version,
    PubDoc doc,
  ) async {
    readmeRequests.add('$name@$version ${doc.name}');
    return switch (doc) {
      PubDoc.readme => (path: 'readme.md', text: '# $name'),
      PubDoc.example => (path: 'example/main.dart', text: 'void main() {}'),
      PubDoc.changelog => null,
    };
  }

  @override
  bool hasPubspec(String root) => true;

  @override
  Future<List<Dependency>> dependencies(String root, String sdkPath) async =>
      dependencyList;

  @override
  Future<void> add(
    String root,
    String sdkPath,
    String name, {
    bool dev = false,
  }) async {
    if (failWith case final error?) throw error;
    commands.add('add ${dev ? 'dev:' : ''}$name');
    dependencyList = [...dependencyList, Dependency(name: name, isDev: dev)];
  }
}

/// An SDK provider that has already found an SDK and looks nowhere else.
class FoundSdk extends FlutterSdkProvider {
  FoundSdk(String emptyRoot) : super(bundledRoot: emptyRoot);

  @override
  FlutterSdkInfo? get sdkInfo => const FlutterSdkInfo(
    flutterVersion: '3.47.5',
    dartVersion: '3.13.4',
    channel: 'stable',
    sdkPath: '/sdk',
    dartSdkPath: '/sdk/bin/cache/dart-sdk',
    location: FlutterSdkLocation.system,
  );
}

void main() {
  late FakePubService service;
  late NotificationsProvider notifications;
  late WorkspaceProvider workspace;
  late FlutterSdkProvider sdk;
  late PubProvider pub;

  setUp(() async {
    final temp = Directory.systemTemp.createTempSync('bird_pub');
    addTearDown(() => temp.deleteSync(recursive: true));
    service = FakePubService();
    notifications = NotificationsProvider();
    workspace = WorkspaceProvider();
    await workspace.openFolder(temp.path);
    sdk = FoundSdk(temp.path);
    while (sdk.isDetecting) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    pub = PubProvider(service: service, debounce: Duration.zero)
      ..attachWorkspace(workspace)
      ..attachSdk(sdk)
      ..attachNotifications(notifications);
  });

  tearDown(() {
    pub.dispose();
    sdk.dispose();
    workspace.dispose();
    notifications.dispose();
  });

  test('a slow answer to an old query cannot replace a newer one', () async {
    pub.search('ht');
    await pumpEventQueue();
    pub.search('http');
    await pumpEventQueue();

    service.searches['http']!.complete(['http', 'dio']);
    service.searches['ht']!.complete(['hive']);
    await pumpEventQueue();

    expect(pub.results, ['http', 'dio']);
    expect(pub.isSearching, isFalse);
  });

  test('clearing the query clears the results without asking', () async {
    pub.search('http');
    await pumpEventQueue();
    service.searches['http']!.complete(['http']);
    await pumpEventQueue();

    pub.search('');

    expect(pub.results, isEmpty);
    expect(service.searches.keys, ['http']);
  });

  test('adding runs pub, says so, and reloads the dependencies', () async {
    await pub.loadDependencies();
    expect(pub.dependency('http'), isNull);

    final result = await pub.add('http', dev: true);

    expect(result, isA<Ok<void>>());
    expect(service.commands, ['add dev:http']);
    expect(notifications.items.single.message, 'Added http');
    expect(pub.dependency('http')?.isDev, isTrue);
    expect(pub.isBusy('http'), isFalse);
  });

  test('a pub failure reaches the user and the caller', () async {
    service.failWith = const ProcessException('flutter', [], 'no resolve', 1);

    final result = await pub.add('http');

    expect(result, isA<Failed<void>>());
    expect(notifications.items.single.message, 'Could not add http');
    expect(notifications.items.single.detail, contains('no resolve'));
  });

  test('details alone never download a README', () async {
    // Search rows ask for details; a README is an archive download each.
    pub.package('http');
    await pumpEventQueue();
    expect(pub.package('http')?.version, '1.0.0');
    expect(service.readmeRequests, isEmpty);

    // The package tab asks, once the version is known.
    pub.document('http', PubDoc.readme);
    await pumpEventQueue();
    expect(pub.document('http', PubDoc.readme), '# http');
    expect(service.readmeRequests, ['http@1.0.0 readme']);
  });

  test('a Dart example is fenced, a missing document is told apart', () async {
    pub.package('http');
    await pumpEventQueue();
    pub.document('http', PubDoc.example);
    pub.document('http', PubDoc.changelog);
    await pumpEventQueue();

    expect(
      pub.document('http', PubDoc.example),
      '```dart\nvoid main() {}\n```',
    );
    expect(pub.hasDocument('http', PubDoc.changelog), isTrue);
    expect(pub.document('http', PubDoc.changelog), isNull);
  });

  test('a package tab is addressed by name and titled with it', () {
    final path = InternalViews.pub.pathFor('http');
    final view = InternalViews.of(path)!;

    expect(path, 'bird://pub/http');
    expect(view.title, 'http');
    expect(view.path, path);
    expect((view.view as PubView).name, 'http');
    // Menu views still resolve exactly, and unknown paths still do not.
    expect(InternalViews.of('bird://settings'), same(InternalViews.settings));
    expect(InternalViews.of('bird://nope/x'), isNull);
  });
}
