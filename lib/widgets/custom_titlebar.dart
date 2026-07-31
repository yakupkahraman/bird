import 'dart:io';
import 'package:bird/providers/file_provider.dart';
import 'package:bird/providers/terminal_provider.dart';
import 'package:bird/widgets/re_icon.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  double get titleBarHeight {
    if (Platform.isMacOS) {
      return 30.0;
    } else if (Platform.isWindows) {
      return 32.0;
    }
    return 30.0;
  }

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Container(
        height: titleBarHeight,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            if (Platform.isMacOS) const SizedBox(width: 72),

            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                'Bird',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary.withAlpha(200),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Spacer(),
            IconButton(
              icon: ReIcon(
                Reicon.outline.save,
                size: 18,
                color: Colors.orangeAccent,
              ),
              onPressed: () => context.read<FileProvider>().saveFile(),
              tooltip: "Save (Ctrl+S)",
            ),
            IconButton(
              icon: ReIcon(
                Reicon.outline.play,
                size: 18,
                color: Colors.greenAccent,
              ),
              onPressed: () {
                final fileProvider = context.read<FileProvider>();
                final terminalProvider = context.read<TerminalProvider>();
                final path = fileProvider.selectedFilePath;

                if (path != null && path.toLowerCase().endsWith('.c')) {
                  final exeName = p.basenameWithoutExtension(path);
                  final isWin = Platform.isWindows;
                  final tempDir = Directory.systemTemp.path;
                  final exeFileName = isWin ? '$exeName.exe' : exeName;
                  final exePath = p.join(tempDir, exeFileName);

                  final cmd = isWin
                      ? 'gcc "$path" -o "$exePath" && "$exePath"'
                      : 'gcc "${path.replaceAll('"', '\\"')}" -o "${exePath.replaceAll('"', '\\"')}" && "$exePath"';
                  terminalProvider.runCommand(cmd);
                } else {
                  terminalProvider.runCommand('echo "No C file open to run"');
                }
              },
              tooltip: 'Run (compile+run open .c file)',
            ),
            IconButton(
              icon: ReIcon(
                Reicon.outline.folderPlus,
                size: 18,
                color: Colors.blueAccent,
              ),
              onPressed: () => context.read<FileProvider>().pickFolder(),
              tooltip: 'Open Folder (Ctrl+O)',
            ),

            if (Platform.isWindows || Platform.isLinux)
              const WindowCaptionButtons(),
          ],
        ),
      ),
    );
  }
}

class WindowCaptionButtons extends StatefulWidget {
  const WindowCaptionButtons({super.key});

  @override
  State<WindowCaptionButtons> createState() => _WindowCaptionButtonsState();
}

class _WindowCaptionButtonsState extends State<WindowCaptionButtons>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  Future<void> _checkMaximized() async {
    final max = await windowManager.isMaximized();
    if (mounted) {
      setState(() => _isMaximized = max);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WindowCaptionButton.minimize(
          brightness: brightness,
          onPressed: () async {
            bool isMinimized = await windowManager.isMinimized();
            if (isMinimized) {
              windowManager.restore();
            } else {
              windowManager.minimize();
            }
          },
        ),
        if (_isMaximized)
          WindowCaptionButton.unmaximize(
            brightness: brightness,
            onPressed: () => windowManager.unmaximize(),
          )
        else
          WindowCaptionButton.maximize(
            brightness: brightness,
            onPressed: () => windowManager.maximize(),
          ),
        WindowCaptionButton.close(
          brightness: brightness,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}
