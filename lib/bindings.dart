import 'package:bird_ce/file_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

Map<ShortcutActivator, VoidCallback> getAppShortcuts(BuildContext context) {
  return {
    // Save shortcuts (Ctrl+S for Windows/Linux, Cmd+S for macOS)
    const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
      context.read<FileProvider>().saveFile();
    },
    const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
      context.read<FileProvider>().saveFile();
    },

    // Open folder shortcuts (Ctrl+O for Windows/Linux, Cmd+O for macOS)
    const SingleActivator(LogicalKeyboardKey.keyO, control: true): () {
      context.read<FileProvider>().pickFolder();
    },
    const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () {
      context.read<FileProvider>().pickFolder();
    },
  };
}
