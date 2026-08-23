import 'package:flutter/material.dart';

/// A dark, monospaced pane that tails command output.
///
/// Reversed rather than scrolled: the newest line sits at the bottom and stays
/// there while a long-running command keeps writing.
class LogConsole extends StatelessWidget {
  final List<String> lines;
  final double height;

  const LogConsole({super.key, required this.lines, this.height = 150});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: ListView(
        reverse: true,
        children: [
          for (final line in lines.reversed)
            SelectableText(
              line,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                fontFamily: 'FiraCode',
                color: primary.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}
