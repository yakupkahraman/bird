import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';

class MySearch extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry padding;
  final double height;
  final bool autoFocus;

  const MySearch({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.padding = const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
    this.height = 36.0,
    this.autoFocus = false,
  });

  @override
  State<MySearch> createState() => _MySearchState();
}

class _MySearchState extends State<MySearch> {
  late TextEditingController _effectiveController;
  bool _isInternalController = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _effectiveController = TextEditingController();
      _isInternalController = true;
    } else {
      _effectiveController = widget.controller!;
    }
    _hasText = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(MySearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      if (widget.controller == null) {
        _effectiveController = TextEditingController();
        _isInternalController = true;
      } else {
        if (_isInternalController) {
          _effectiveController.dispose();
          _isInternalController = false;
        }
        _effectiveController = widget.controller!;
      }
      _hasText = _effectiveController.text.isNotEmpty;
      _effectiveController.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onTextChanged);
    if (_isInternalController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _effectiveController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleClear() {
    _effectiveController.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: secondary.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: primary.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: primary.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Icon(
                    NfIcons.search,
                    size: 14,
                    color: primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _effectiveController,
                      autofocus: widget.autoFocus,
                      onChanged: widget.onChanged,
                      style: TextStyle(
                        fontSize: 13,
                        color: primary,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: primary.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_hasText)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _handleClear,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            NfIcons.close,
                            size: 13,
                            color: primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
