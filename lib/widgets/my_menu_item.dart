import 'package:flutter/material.dart';

class MyMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const MyMenuItem({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  State<MyMenuItem> createState() => _MyMenuItemState();
}

class _MyMenuItemState extends State<MyMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).pop();
          widget.onTap?.call();
        },
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _isHovered ? primary : primary.withValues(alpha: 0.70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: _isHovered
                        ? primary
                        : primary.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class MyMenuDivider extends StatelessWidget {
  const MyMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      color: primary.withValues(alpha: 0.12),
    );
  }
}
