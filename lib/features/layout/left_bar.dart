import 'package:bird/core/ui/my_icon_button.dart';
import 'package:bird/features/layout/panes_provider.dart';
import 'package:bird/features/layout/side_panels.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeftBar extends StatelessWidget {
  const LeftBar({super.key});

  @override
  Widget build(BuildContext context) {
    final panesProvider = context.watch<PanesProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      child: Column(
        spacing: 4,
        children: [
          for (final (index, panel) in SidePanels.all.indexed)
            MyIconButton(
              onPressed: () => panesProvider.onSidebarTabPressed(index),
              icon: panel.icon,
              isSelected:
                  panesProvider.isLeftVisible &&
                  panesProvider.selectedSidebarIndex == index,
              tooltip: panel.title,
            ),
        ],
      ),
    );
  }
}
