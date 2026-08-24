import 'package:flutter/material.dart';

class MiniButton extends StatefulWidget {
  final IconData? icon;
  final IconData? trailingIcon;

  /// Text beside the icon, for a button whose value is worth reading without
  /// hovering — the active Flutter version, say.
  final String? label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isSelected;
  final Color? trailingIconColor;

  const MiniButton({
    super.key,
    this.icon,
    this.trailingIcon,
    this.label,
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

    // A lone icon sits in a square; anything else grows to fit its content.
    final isWide = widget.trailingIcon != null || widget.label != null;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.icon != null)
          Icon(widget.icon, size: isWide ? 14 : 15, color: iconColor),
        if (widget.label case final label?) ...[
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: iconColor)),
        ],
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 2),
          Icon(widget.trailingIcon, size: 11, color: effectiveTrailingColor),
        ],
      ],
    );

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
            width: isWide ? null : 24,
            padding: isWide
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
