import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MyIconButton extends StatelessWidget {
  const MyIconButton({super.key, this.onPressed, required this.icon});

  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      mouseCursor: SystemMouseCursors.basic,
      onTap: onPressed,
      splashColor: Colors.white10,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[900]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: PhosphorIcon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
