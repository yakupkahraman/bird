import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  double get titleBarHeight {
    if (Platform.isMacOS) {
      return 30.0;
    } else if (Platform.isWindows) {
      return 32.0;
    }
    return 30.0;
  }

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Container(
        height: titleBarHeight,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            if (Platform.isMacOS) const SizedBox(width: 72),

            const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Text(
                'Bird',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Spacer(),

            IconButton(
              icon: PhosphorIcon(
                PhosphorIcons.play(),
                size: 18,
                color: Colors.greenAccent,
              ),
              onPressed: () => print("Kodu çalıştır"),
            ),
            IconButton(
              icon: PhosphorIcon(
                PhosphorIcons.plus(),
                size: 18,
                color: Colors.white70,
              ),
              onPressed: () => print("Paylaş"),
            ),

            if (Platform.isWindows) const SizedBox(width: 140),
          ],
        ),
      ),
    );
  }
}
