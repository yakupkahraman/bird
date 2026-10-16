import 'dart:io' show Platform;

import 'package:code_forge/code_forge.dart';

/// Starts the Dart language server.
///
/// Owns nothing: the process it hands back is [LspProvider]'s to keep and to
/// kill, which is why there is no state and no `dispose` here.
class LspService {
  /// A server analysing [workspacePath], initialized and ready for editors.
  ///
  /// [dartPath] is the binary from the active SDK; without one, whatever
  /// `dart` is on PATH has to do. Throws if the process will not start.
  Future<LspConfig> start(String workspacePath, {String? dartPath}) async {
    final config = await LspStdioConfig.start(
      executable: dartPath ?? (Platform.isWindows ? 'dart.exe' : 'dart'),
      args: const ['language-server'],
      workspacePath: workspacePath,
      languageId: 'dart',
    );
    // Initialized here, once. Left to code_forge, every editor initializes
    // the server it is given if that has not happened yet, so several created
    // together all try: the later ones fail and never open their file.
    //
    // The server then asks workspace/configuration and holds all analysis
    // until it hears back. Editors answer that, but none exist yet, so answer
    // here — subscribed before initialize, or the question slips past.
    config.responses.listen((message) {
      if (message['method'] == 'workspace/configuration') {
        config.sendResponse(message['id'] as int, [
          config.workspaceConfiguration,
        ]);
      }
    });
    await config.initialize();
    return config;
  }
}
