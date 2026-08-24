import 'package:flutter/material.dart';

class MyTile extends StatefulWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  const MyTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 10.0),
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<MyTile> createState() => _MyTileState();
}

class _MyTileState extends State<MyTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final isClickable = widget.onTap != null;

    final defaultBg = secondary.withValues(alpha: 0.3);
    final bg =
        widget.backgroundColor ??
        (isClickable && _isHovered
            ? primary.withValues(alpha: 0.08)
            : defaultBg);

    final border = Border.all(
      color:
          widget.borderColor ??
          (isClickable && _isHovered
              ? primary.withValues(alpha: 0.25)
              : primary.withValues(alpha: 0.08)),
      width: 1.0,
    );

    Widget content = Row(
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 14),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: primary.withValues(alpha: 0.8)),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primary,
                ),
              ),
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: primary.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 12),
          widget.trailing!,
        ],
      ],
    );

    Widget container = Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
        border: border,
      ),
      child: content,
    );

    if (isClickable) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: container,
        ),
      );
    }

    return container;
  }
}
