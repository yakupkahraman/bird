import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter_pty/flutter_pty.dart';

class TerminalProvider extends ChangeNotifier {
  final Terminal terminal = Terminal();
  Pty? _pty;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Pty? get pty => _pty;

  String get shell {
    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['SHELL'] ?? '/bin/bash';
    }
    if (Platform.isWindows) {
      return 'cmd.exe';
    }
    return '/bin/sh';
  }

  void initializePty({String? workingDirectory}) {
    if (_isInitialized) return;

    _pty = Pty.start(
      shell,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
      workingDirectory: workingDirectory,
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
