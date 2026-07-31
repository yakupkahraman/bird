import 'package:flutter/material.dart';

class ExtensionsPane extends StatelessWidget {
  const ExtensionsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text(
        'Bird is trying to settle down...\nExtensions page coming soon!',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
        ),
      ),
    );
  }
}
