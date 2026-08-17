import 'package:flutter/material.dart';

class MiniButton extends StatefulWidget {
  final IconData? icon;
  final IconData? trailingIcon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isSelected;
  final Color? trailingIconColor;

  const MiniButton({
    super.key,
    this.icon,
    this.trailingIcon,
    required this.tooltip,
    this.onPressed,
    this.isSelected = false,
    this.trailingIconColor,
  });

  @override
  State<MiniButton> createState() => _MiniButtonState();
}

class _MiniButtonState extends State<MiniButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
      iconColor = primary.withValues(alpha: 0.65);
    }

    final effectiveTrailingColor = widget.trailingIconColor ?? iconColor;

    Widget content;
    if (widget.icon != null && widget.trailingIcon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 14, color: iconColor),
          const SizedBox(width: 2),
          Icon(widget.trailingIcon, size: 11, color: effectiveTrailingColor),
        ],
      );
    } else if (widget.icon != null) {
      content = Icon(widget.icon, size: 15, color: iconColor);
    } else {
      content = const SizedBox.shrink();
    }

    final hasMultipleIcons = widget.icon != null && widget.trailingIcon != null;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      preferBelow: true,
      verticalOffset: 14,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border.all(color: primary.withValues(alpha: 0.22), width: 0.8),
        borderRadius: BorderRadius.circular(5),
      ),
      textStyle: TextStyle(
        color: primary.withValues(alpha: 0.9),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 24,
            width: hasMultipleIcons ? null : 24,
            padding: hasMultipleIcons
                ? const EdgeInsets.symmetric(horizontal: 4.0)
                : null,
            margin: const EdgeInsets.symmetric(horizontal: 1.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
