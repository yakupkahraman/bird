import 'dart:async';

import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:bird/features/search/search_service.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:dart_ripgrep/dart_ripgrep.dart';
import 'package:flutter/foundation.dart';

/// The search panel's query and what it found in the open folder.
class SearchProvider extends ChangeNotifier {
  /// [service] is only passed by tests.
  SearchProvider({SearchService? service})
    : _service = service ?? SearchService();

  final SearchService _service;
  NotificationsProvider? _notifications;
  WorkspaceProvider? _workspace;
  String? _root;
  StreamSubscription<RgMatch>? _search;

  String _query = '';
  final Map<String, List<RgMatch>> _results = {};
  bool _isSearching = false;

  String get query => _query;
  String? get root => _root;
  bool get isSearching => _isSearching;

  /// Matches grouped by file, in the order ripgrep found them.
  Map<String, List<RgMatch>> get results => _results;

  void attachNotifications(NotificationsProvider notifications) =>
      _notifications = notifications;

  void attachWorkspace(WorkspaceProvider workspace) {
    if (identical(_workspace, workspace)) return;
    _workspace?.removeListener(_onWorkspaceChanged);
    _workspace = workspace..addListener(_onWorkspaceChanged);
    _root = workspace.rootPath;
  }

  // A listener rather than the proxy's update, which runs mid-build where
  // notifying is not allowed. Results belong to one folder, so they go when
  // the folder does.
  void _onWorkspaceChanged() {
    if (_workspace!.rootPath == _root) return;
    _root = _workspace!.rootPath;
    search('');
  }

  /// Replaces the current search with one for [query].
  void search(String query) {
    _query = query;
    // Cancelling kills the previous ripgrep, so fast typing never piles up
    // processes.
    _search?.cancel();
    _search = null;
    _results.clear();
    _isSearching = query.isNotEmpty && _root != null;
    if (_isSearching) {
      _search = _service
          .search(query, _root!)
          .listen(
            (match) {
              _results.putIfAbsent(match.path, () => []).add(match);
              notifyListeners();
            },
            onError: (Object e) {
              // An unreadable file is ripgrep's exit code 2; every match it
              // could read has already arrived and is worth keeping.
              if (e is RgException) {
                debugPrint('Search finished with errors: $e');
              } else {
                _notifications?.error('Search failed', detail: '$e');
              }
            },
            onDone: () {
              _isSearching = false;
              notifyListeners();
            },
          );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _workspace?.removeListener(_onWorkspaceChanged);
    _search?.cancel();
    super.dispose();
  }
}
