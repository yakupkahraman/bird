import 'package:bird/features/lsp/lsp_service.dart';
import 'package:bird/features/sdk/flutter_sdk_provider.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/foundation.dart';

/// Owns the Dart language server process for the open workspace.
///
/// `CodeForgeController` never disposes the config it is given, so killing the
/// process is this provider's job.
class LspProvider extends ChangeNotifier {
  /// [service] is only passed by tests.
  LspProvider({LspService? service}) : _service = service ?? LspService();

  final LspService _service;

  String? _currentWorkspacePath;
  LspConfig? _dartLspConfig;
  FlutterSdkProvider? _sdk;
  bool _isDisposed = false;

  /// Discards results of superseded [updateWorkspace] calls.
  int _requestId = 0;

  String? get currentWorkspacePath => _currentWorkspacePath;
  LspConfig? get dartLspConfig => _dartLspConfig;
  bool get isRunning => _dartLspConfig != null;

  /// Called from `ChangeNotifierProxyProvider` to link the active Flutter SDK.
  void attachSdk(FlutterSdkProvider sdk) {
    if (identical(_sdk, sdk)) return;
    _sdk?.removeListener(_onSdkChanged);
    _sdk = sdk;
    sdk.addListener(_onSdkChanged);
  }

  void _onSdkChanged() {
    if (_currentWorkspacePath != null && _dartLspConfig != null) {
      restartServer();
    }
  }

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
      config = await _service.start(path, dartPath: _sdk?.sdkInfo?.dartSdkPath);
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

  /// Restarts the LSP server for the current workspace.
  Future<void> restartServer() async {
    final path = _currentWorkspacePath;
    stopServer();
    if (path != null) {
      await updateWorkspace(path);
    }
  }

  /// Starts the LSP server if not currently running.
  Future<void> startServer() async {
    if (_currentWorkspacePath != null && _dartLspConfig == null) {
      await updateWorkspace(_currentWorkspacePath);
    }
  }

  LspConfig? getLspConfigForFile(String path) =>
      path.endsWith('.dart') ? _dartLspConfig : null;

  /// Kills the server. There is no LSP shutdown handshake on purpose: the
  /// analyzer has no state to flush, and an unresponsive server must not delay
  /// window close or the next workspace.
  void stopServer() {
    _dartLspConfig?.dispose();
    _dartLspConfig = null;
    _notify();
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
