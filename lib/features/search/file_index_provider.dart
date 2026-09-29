import 'dart:async';

import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:bird/features/search/search_service.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:dart_ripgrep/dart_ripgrep.dart';
import 'package:flutter/foundation.dart';

/// Every file in the open folder, for anything that picks one by name.
///
/// Re-listed on demand rather than watched: ripgrep lists a large project in
/// a fraction of a second, and a stale entry only costs a failed open.
class FileIndexProvider extends ChangeNotifier {
  /// [service] is only passed by tests.
  FileIndexProvider({SearchService? service})
    : _service = service ?? SearchService();

  final SearchService _service;
  NotificationsProvider? _notifications;
  WorkspaceProvider? _workspace;
  String? _root;
  StreamSubscription<String>? _listing;
  List<String> _files = const [];

  String? get root => _root;

  /// Absolute paths, in the order ripgrep listed them.
  List<String> get files => _files;

  void attachNotifications(NotificationsProvider notifications) =>
      _notifications = notifications;

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
    _listing?.cancel();
    _files = const [];
    notifyListeners();
  }

  /// Lists the folder again. The old list stays up until the new one is
  /// complete, so a picker never flickers empty while it waits.
  void refresh() {
    final root = _root;
    if (root == null) return;
    _listing?.cancel();
    final next = <String>[];
    _listing = _service
        .files(root)
        .listen(
          next.add,
          onError: (Object e) {
            // Exit code 2 is an unreadable folder somewhere; the rest listed.
            if (e is RgException) {
              debugPrint('File listing finished with errors: $e');
            } else {
              _notifications?.error('Could not list files', detail: '$e');
            }
          },
          onDone: () {
            _files = next;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _workspace?.removeListener(_onWorkspaceChanged);
    _listing?.cancel();
    super.dispose();
  }
}
