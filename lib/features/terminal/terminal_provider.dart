import 'dart:convert';
import 'dart:typed_data';
import 'package:bird/features/sdk/flutter_sdk_provider.dart';
import 'package:bird/features/terminal/pty_service.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter_pty/flutter_pty.dart';

class TerminalProvider extends ChangeNotifier {
  /// [service] is only passed by tests.
  TerminalProvider({PtyService? service}) : _service = service ?? PtyService();

  final PtyService _service;

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

  void initializePty({String? workingDirectory}) {
    if (_isInitialized) return;

    _pty = _service.start(
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
      workingDirectory: workingDirectory,
      sdkPath: _sdk?.sdkInfo?.sdkPath,
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
