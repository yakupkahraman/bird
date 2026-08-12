import 'dart:io';

import 'package:code_forge/code_forge.dart';
import 'package:flutter/foundation.dart';

/// Owns the Dart language server process for the open workspace.
///
/// `CodeForgeController` never disposes the config it is given, so killing the
/// process is this provider's job.
class LspProvider extends ChangeNotifier {
  String? _currentWorkspacePath;
  LspConfig? _dartLspConfig;
  bool _isDisposed = false;

  /// Discards results of superseded [updateWorkspace] calls.
  int _requestId = 0;

  String? get currentWorkspacePath => _currentWorkspacePath;
  LspConfig? get dartLspConfig => _dartLspConfig;

  /// Starts a server for [workspacePath], replacing any running one. Passing
  /// the current workspace again is a no-op unless the last start failed.
  Future<void> updateWorkspace(String? workspacePath) async {
    final path = (workspacePath?.isEmpty ?? true) ? null : workspacePath;
    if (path == _currentWorkspacePath && _dartLspConfig != null) return;

    final requestId = ++_requestId;
    _currentWorkspacePath = path;
    stopServer();
    _notify();
    if (path == null) return;

    LspConfig? config;
    try {
      config = await LspStdioConfig.start(
        executable: Platform.isWindows ? 'dart.exe' : 'dart',
        args: const ['language-server'],
        workspacePath: path,
        languageId: 'dart',
      );
    } catch (e) {
      debugPrint('Failed to start Dart language server: $e');
    }

    // A newer workspace won the race, or we were disposed: nobody owns this.
    if (_isDisposed || requestId != _requestId) {
      config?.dispose();
      return;
    }

    _dartLspConfig = config;
    _notify();
  }

  LspConfig? getLspConfigForFile(String path) =>
      path.endsWith('.dart') ? _dartLspConfig : null;

  /// Kills the server. There is no LSP shutdown handshake on purpose: the
  /// analyzer has no state to flush, and an unresponsive server must not delay
  /// window close or the next workspace.
  void stopServer() {
    _dartLspConfig?.dispose();
    _dartLspConfig = null;
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Otherwise `dart language-server` lives on as an orphan process.
    stopServer();
    super.dispose();
  }
}
