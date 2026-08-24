import 'package:flutter/material.dart';

class MyIconButton extends StatefulWidget {
  const MyIconButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.isSelected = false,
    this.size = 22,
    this.fontWeight = FontWeight.w300,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final bool isSelected;
  final double size;
  final FontWeight? fontWeight;
  final String? tooltip;

  @override
  State<MyIconButton> createState() => _MyIconButtonState();
}

class _MyIconButtonState extends State<MyIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    Color backgroundColor;
    if (widget.isSelected) {
      backgroundColor = primary.withValues(alpha: 0.15);
    } else if (_isHovered) {
      backgroundColor = primary.withValues(alpha: 0.08);
    } else {
      backgroundColor = Colors.transparent;
    }

    Color iconColor;
    if (widget.isSelected) {
      iconColor = primary;
    } else if (_isHovered) {
      iconColor = primary.withValues(alpha: 0.95);
    } else {
      iconColor = primary.withValues(alpha: 0.60);
    }

    Widget button = MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.size,
              color: iconColor,
              fontWeight: widget.fontWeight,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      final theme = Theme.of(context);
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 300),
        preferBelow: false,
        verticalOffset: -12,
        margin: const EdgeInsets.only(left: 34),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border.all(
            color: primary.withValues(alpha: 0.22),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        textStyle: TextStyle(
          color: primary.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        child: button,
      );
    }

    return button;
  }
}
