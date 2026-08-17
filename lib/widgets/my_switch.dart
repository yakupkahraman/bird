import 'package:flutter/material.dart';

class MySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final double width;
  final double height;

  const MySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.width = 34.0,
    this.height = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    final thumbSize = height - 4.0;
    final activeBg = activeColor ?? primary;
    final inactiveBg = inactiveColor ?? secondary.withValues(alpha: 0.8);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          width: width,
          height: height,
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: value ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: value ? activeBg : primary.withValues(alpha: 0.22),
              width: 1.0,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? theme.scaffoldBackgroundColor
                    : primary.withValues(alpha: 0.65),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
