import 'package:bird/terminal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/ui.dart';

class TerminalPane extends StatelessWidget {
  final double height;

  const TerminalPane({super.key, this.height = 200.0});

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalProvider>(
      builder: (context, terminalProvider, child) {
        return Container(
          height: height,
          width: double.infinity,
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
