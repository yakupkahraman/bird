import 'package:flutter/material.dart';

class ExtensionsPane extends StatelessWidget {
  const ExtensionsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Text(
          'Bird is trying to settle down...\nExtensions page coming soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
