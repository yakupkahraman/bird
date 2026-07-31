import 'package:bird/providers/terminal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/ui.dart';

class TerminalPane extends StatelessWidget {
  const TerminalPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalProvider>(
      builder: (context, terminalProvider, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).colorScheme.secondary,
          child: TerminalView(
            terminalProvider.terminal,
            backgroundOpacity: 0.0,
          ),
        );
      },
    );
  }
}
