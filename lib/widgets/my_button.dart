import 'package:flutter/material.dart';

enum MyButtonVariant { primary, secondary, outline }

class MyButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final MyButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double iconSize;
  final double fontSize;
  final String? tooltip;

  const MyButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = MyButtonVariant.primary,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 36,
    this.borderRadius,
    this.padding,
    this.iconSize = 16,
    this.fontSize = 13,
    this.tooltip,
  });

  const MyButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 36,
    this.borderRadius,
    this.padding,
    this.iconSize = 16,
    this.fontSize = 13,
    this.tooltip,
  }) : variant = MyButtonVariant.secondary;

  const MyButton.outline({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 36,
    this.borderRadius,
    this.padding,
    this.iconSize = 16,
    this.fontSize = 13,
    this.tooltip,
  }) : variant = MyButtonVariant.outline;

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final radius = widget.borderRadius ?? BorderRadius.circular(6);

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case MyButtonVariant.primary:
        final base = widget.backgroundColor ?? const Color(0xFF027DFD);
        bg = _isHovered
            ? Color.alphaBlend(Colors.white.withValues(alpha: 0.12), base)
            : base;
        fg = widget.foregroundColor ?? Colors.white;
        break;

      case MyButtonVariant.secondary:
        final base =
            widget.backgroundColor ?? primaryColor.withValues(alpha: 0.10);
        bg = _isHovered ? primaryColor.withValues(alpha: 0.16) : base;
        fg = widget.foregroundColor ?? primaryColor;
        break;

      case MyButtonVariant.outline:
        bg = _isHovered
            ? primaryColor.withValues(alpha: 0.08)
            : (widget.backgroundColor ?? Colors.transparent);
        fg = widget.foregroundColor ?? primaryColor;
        border = Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 1,
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: widget.iconSize, color: fg),
          const SizedBox(width: 8),
        ],
        // With no width the row hugs the label, so nothing is cut off; a
        // caller that does pin a width gets an ellipsis instead of an overflow.
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );

    Widget button = MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
          // An alignment makes a width-less Container fill whatever it is given,
          // which would stretch every button across its parent. The row already
          // centres itself, so this is only needed when a width is pinned.
          alignment: widget.width == null ? null : Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: border,
          ),
          child: content,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
