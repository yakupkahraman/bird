import 'dart:async';

import 'package:bird/core/result.dart';
import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:bird/features/pub/pub_package.dart';
import 'package:bird/features/pub/pub_service.dart';
import 'package:bird/features/sdk/flutter_sdk_provider.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:flutter/foundation.dart';

/// pub.dev search, package details, and the open project's dependencies.
class PubProvider extends ChangeNotifier {
  /// [service] and [debounce] are only passed by tests.
  PubProvider({
    PubService? service,
    this.debounce = const Duration(milliseconds: 300),
  }) : _service = service ?? PubService();

  final PubService _service;

  /// How long typing has to pause before pub.dev is asked.
  final Duration debounce;

  WorkspaceProvider? _workspace;
  FlutterSdkProvider? _sdk;
  NotificationsProvider? _notifications;
  String? _root;

  String _query = '';
  List<String> _results = const [];
  bool _isSearching = false;
  Timer? _typing;

  /// Bumped per search, so an answer that arrives after a newer query is
  /// dropped instead of replacing that query's results.
  int _searchId = 0;

  final Map<String, PubPackage> _packages = {};
  final Set<String> _fetching = {};

  /// Fetched documents; a key with a null value is one the package lacks.
  final Map<(String, PubDoc), String?> _documents = {};
  final Set<(String, PubDoc)> _fetchingDocuments = {};

  List<Dependency>? _dependencies;
  bool _isLoadingDependencies = false;
  final Set<String> _busy = {};

  String get query => _query;
  List<String> get results => _results;
  bool get isSearching => _isSearching;

  /// Null while not loaded, or when the folder is not a Dart project.
  List<Dependency>? get dependencies => _dependencies;
  bool get isLoadingDependencies => _isLoadingDependencies;
  bool get hasProject => _root != null && _service.hasPubspec(_root!);

  /// True while a `pub` command runs for [name].
  bool isBusy(String name) => _busy.contains(name);

  Dependency? dependency(String name) =>
      _dependencies?.where((d) => d.name == name).firstOrNull;

  void attachNotifications(NotificationsProvider notifications) =>
      _notifications = notifications;

  void attachSdk(FlutterSdkProvider sdk) => _sdk = sdk;

  void attachWorkspace(WorkspaceProvider workspace) {
    if (identical(_workspace, workspace)) return;
    _workspace?.removeListener(_onWorkspaceChanged);
    _workspace = workspace..addListener(_onWorkspaceChanged);
    _root = workspace.rootPath;
  }

  // A listener rather than the proxy's update, which runs mid-build where
  // notifying is not allowed.
  void _onWorkspaceChanged() {
    if (_workspace!.rootPath == _root) return;
    _root = _workspace!.rootPath;
    _dependencies = null;
    notifyListeners();
  }

  /// [name]'s details, fetched on first ask; null until they arrive.
  PubPackage? package(String name) {
    final cached = _packages[name];
    if (cached == null && _fetching.add(name)) _fetch(name);
    return cached;
  }

  Future<void> _fetch(String name) async {
    try {
      _packages[name] = await _service.package(name);
      _fetching.remove(name);
      notifyListeners();
    } catch (e) {
      // Left in _fetching, so it is not retried on every rebuild while
      // offline. The row keeps showing just the name.
      debugPrint('Could not fetch $name from pub.dev: $e');
    }
  }

  /// One of [name]'s documents as markdown, fetched on first ask once its
  /// version is known. Asked for by the package tab alone: search rows would
  /// download an archive each.
  String? document(String name, PubDoc doc) {
    final version = _packages[name]?.version;
    final key = (name, doc);
    if (version != null &&
        !_documents.containsKey(key) &&
        _fetchingDocuments.add(key)) {
      _fetchDocument(name, version, doc);
    }
    return _documents[key];
  }

  /// Whether [document] has its answer, so "none" can be told from "not yet".
  bool hasDocument(String name, PubDoc doc) =>
      _documents.containsKey((name, doc));

  Future<void> _fetchDocument(String name, String version, PubDoc doc) async {
    try {
      final found = await _service.document(name, version, doc);
      // An example may be plain Dart; fenced, it renders as code.
      _documents[(name, doc)] = switch (found) {
        null => null,
        (:final path, :final text) when path.endsWith('.dart') =>
          '```dart\n$text\n```',
        (:final text, path: _) => text,
      };
      _fetchingDocuments.remove((name, doc));
      notifyListeners();
    } catch (e) {
      // Left in the set, as with details: no retry on every rebuild.
      debugPrint('Could not fetch the ${doc.name} of $name: $e');
    }
  }

  void search(String query) {
    _query = query;
    _typing?.cancel();
    final id = ++_searchId;
    _isSearching = query.isNotEmpty;
    if (query.isEmpty) _results = const [];
    notifyListeners();
    if (query.isEmpty) return;

    _typing = Timer(debounce, () async {
      try {
        final names = await _service.search(query);
        if (id != _searchId) return;
        _results = names;
      } catch (e) {
        if (id != _searchId) return;
        _results = const [];
        _notifications?.error('Could not search pub.dev', detail: '$e');
      }
      _isSearching = false;
      notifyListeners();
    });
  }

  /// Loads the dependency list once per folder; [force] reloads it.
  Future<void> loadDependencies({bool force = false}) async {
    final root = _root;
    final sdkPath = _sdk?.sdkInfo?.sdkPath;
    if (root == null || sdkPath == null || !_service.hasPubspec(root)) return;
    if (_isLoadingDependencies || (_dependencies != null && !force)) return;

    _isLoadingDependencies = true;
    notifyListeners();
    try {
      final dependencies = await _service.dependencies(root, sdkPath);
      if (root == _root) _dependencies = dependencies;
    } catch (e) {
      // Usually a pubspec that does not resolve; the list stays as it was.
      debugPrint('pub outdated failed in $root: $e');
    } finally {
      _isLoadingDependencies = false;
      notifyListeners();
    }
  }

  Future<Result<void>> add(String name, {bool dev = false}) => _run(
    name,
    'Added $name',
    'Could not add $name',
    (root, sdk) => _service.add(root, sdk, name, dev: dev),
  );

  Future<Result<void>> remove(String name) => _run(
    name,
    'Removed $name',
    'Could not remove $name',
    (root, sdk) => _service.remove(root, sdk, name),
  );

  Future<Result<void>> upgrade(String name) => _run(
    name,
    'Upgraded $name',
    'Could not upgrade $name',
    (root, sdk) => _service.upgrade(root, sdk, name),
  );

  Future<Result<void>> _run(
    String name,
    String done,
    String failed,
    Future<void> Function(String root, String sdkPath) command,
  ) async {
    final root = _root;
    final sdkPath = _sdk?.sdkInfo?.sdkPath;
    if (root == null || sdkPath == null) {
      final reason = root == null
          ? 'No folder is open'
          : 'No Flutter SDK found';
      _notifications?.error(failed, detail: reason);
      return Failed('$failed: $reason');
    }

    _busy.add(name);
    notifyListeners();
    try {
      await command(root, sdkPath);
      _notifications?.info(done);
      // pubspec.lock may be new, and the list has changed either way.
      await _workspace?.refreshListing(root);
      await loadDependencies(force: true);
      return const Ok(null);
    } catch (e) {
      _notifications?.error(failed, detail: '$e');
      return Failed('$failed: $e');
    } finally {
      _busy.remove(name);
      notifyListeners();
    }
  }

  Future<void> openInBrowser(Uri uri) => _service.openInBrowser(uri);

  @override
  void dispose() {
    _typing?.cancel();
    _workspace?.removeListener(_onWorkspaceChanged);
    super.dispose();
  }
}
