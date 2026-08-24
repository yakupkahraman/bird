import 'dart:io' show Platform;

import 'package:code_forge/code_forge.dart';

/// Starts the Dart language server.
///
/// Owns nothing: the process it hands back is [LspProvider]'s to keep and to
/// kill, which is why there is no state and no `dispose` here.
class LspService {
  /// A server analysing [workspacePath].
  ///
  /// [dartPath] is the binary from the active SDK; without one, whatever
  /// `dart` is on PATH has to do. Throws if the process will not start.
  Future<LspConfig> start(String workspacePath, {String? dartPath}) =>
      LspStdioConfig.start(
        executable: dartPath ?? (Platform.isWindows ? 'dart.exe' : 'dart'),
        args: const ['language-server'],
        workspacePath: workspacePath,
        languageId: 'dart',
      );
}
