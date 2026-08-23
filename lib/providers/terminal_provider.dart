import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bird/providers/flutter_sdk_provider.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:xterm/xterm.dart';
import 'package:flutter_pty/flutter_pty.dart';

class TerminalProvider extends ChangeNotifier {
  final Terminal terminal = Terminal();
  Pty? _pty;
  FlutterSdkProvider? _sdk;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Pty? get pty => _pty;

  /// Called from `ChangeNotifierProxyProvider` to link the active Flutter SDK.
  void attachSdk(FlutterSdkProvider sdk) {
    _sdk = sdk;
  }

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

  void initializePty({String? workingDirectory}) {
    if (_isInitialized) return;

    final env = Map<String, String>.from(Platform.environment);
    if (_sdk?.sdkInfo?.sdkPath case final sdkPath?) {
      final flutterBin = p.join(sdkPath, 'bin');
      final pathSep = Platform.isWindows ? ';' : ':';
      final currentPath = env['PATH'] ?? '';
      env['PATH'] = '$flutterBin$pathSep$currentPath';
    }

    _pty = Pty.start(
      shell,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
      workingDirectory: workingDirectory,
      environment: env,
    );

    _pty!.output.listen((data) {
      terminal.write(utf8.decode(data));
    });

    _pty!.exitCode.then((code) {
      terminal.write('\r\n[Process exited with code $code]\r\n');
      _isInitialized = false;
      notifyListeners();
    });

    terminal.onOutput = (data) {
      _pty?.write(Uint8List.fromList(utf8.encode(data)));
    };

    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      _pty?.resize(height, width);
    };

    _isInitialized = true;
    notifyListeners();
  }

  void runCommand(String command) {
    if (!_isInitialized) {
      initializePty();
    }
    _pty?.write(Uint8List.fromList(utf8.encode('$command\n')));
  }

  void clear() {
    terminal.write('\x1B[2J\x1B[H');
  }

  @override
  void dispose() {
    _pty?.kill();
    super.dispose();
  }
}
