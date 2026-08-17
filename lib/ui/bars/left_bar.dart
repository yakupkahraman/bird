import 'package:bird/providers/panes_provider.dart';
import 'package:bird/widgets/my_icon_button.dart';
import 'package:bird/widgets/nf_icons.dart';
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
          MyIconButton(
            onPressed: () => panesProvider.onSidebarTabPressed(0),
            icon: NfIcons.folder,
            isSelected:
                panesProvider.isLeftVisible &&
                panesProvider.selectedSidebarIndex == 0,
            tooltip: 'Explorer',
          ),
          MyIconButton(
            onPressed: () => panesProvider.onSidebarTabPressed(1),
            icon: NfIcons.extensions,
            isSelected:
                panesProvider.isLeftVisible &&
                panesProvider.selectedSidebarIndex == 1,
            tooltip: 'Extensions',
          ),
        ],
      ),
    );
  }
}
