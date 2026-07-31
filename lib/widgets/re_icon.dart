import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

class ReIcon extends StatelessWidget {
  final String path;
  final double size;
  final Color? color;

  const ReIcon(
    this.path, {
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = IconTheme.of(context).color;
    final effectiveColor = color ?? defaultColor;

    return SvgPicture.string(
      reiconSvg(path, size: size.toInt()),
      width: size,
      height: size,
      colorFilter: effectiveColor != null
          ? ColorFilter.mode(effectiveColor, BlendMode.srcIn)
          : null,
    );
  }
}
