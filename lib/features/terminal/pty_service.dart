import 'dart:io';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:path/path.dart' as p;

/// Starts the shell behind the terminal panel.
///
/// Owns nothing: the PTY it hands back is [TerminalProvider]'s to keep and to
/// kill.
class PtyService {
  /// The user's shell, or the first fallback that is actually installed.
  String get shell {
    if (Platform.isWindows) {
      return 'cmd.exe';
    }
    final envShell = Platform.environment['SHELL'];
    if (envShell != null &&
        envShell.isNotEmpty &&
        File(envShell).existsSync()) {
      return envShell;
    }
    if (File('/bin/bash').existsSync()) {
      return '/bin/bash';
    }
    if (File('/bin/zsh').existsSync()) {
      return '/bin/zsh';
    }
    return '/bin/sh';
  }

  /// The inherited environment, with [sdkPath]'s `bin` put ahead of PATH so
  /// `flutter` in the terminal means the SDK Bird is using.
  Map<String, String> environment({String? sdkPath}) {
    final env = Map<String, String>.from(Platform.environment);
    if (sdkPath != null) {
      final flutterBin = p.join(sdkPath, 'bin');
      final pathSep = Platform.isWindows ? ';' : ':';
      env['PATH'] = '$flutterBin$pathSep${env['PATH'] ?? ''}';
    }
    return env;
  }

  Pty start({
    required int columns,
    required int rows,
    String? workingDirectory,
    String? sdkPath,
  }) => Pty.start(
    shell,
    columns: columns,
    rows: rows,
    workingDirectory: workingDirectory,
    environment: environment(sdkPath: sdkPath),
  );
}
