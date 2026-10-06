import 'package:bird/core/ui/nf_icons.dart';
import 'package:bird/features/extensions/extensions_panel.dart';
import 'package:bird/features/pub/pub_panel.dart';
import 'package:bird/features/search/search_panel.dart';
import 'package:bird/features/workspace/explorer_panel.dart';
import 'package:flutter/widgets.dart';

/// A panel that can occupy the left sidebar, with the button that selects it.
class SidePanel {
  const SidePanel({
    required this.id,
    required this.title,
    required this.icon,
    required this.view,
  });

  final String id;

  /// What the left bar shows on hover.
  final String title;

  final IconData icon;

  /// Const widget shown in the sidebar; side panels take no arguments.
  final Widget view;
}

/// Registry of every sidebar panel.
///
/// [all] is the single source of truth: a panel added there gets its button in
/// the left bar and its slot in the shell at once. Before this the two lived in
/// two files and lined up only by position — inserting a panel in the middle
/// silently gave every one after it the wrong icon.
class SidePanels {
  const SidePanels._();

  static const explorer = SidePanel(
    id: 'explorer',
    title: 'Explorer',
    icon: NfIcons.folder,
    view: ExplorerPanel(),
  );

  static const search = SidePanel(
    id: 'search',
    title: 'Search',
    icon: NfIcons.search,
    view: SearchPanel(),
  );

  static const pub = SidePanel(
    id: 'pub',
    title: 'Packages (pub.dev)',
    icon: NfIcons.package,
    view: PubPanel(),
  );

  static const extensions = SidePanel(
    id: 'extensions',
    title: 'Extensions',
    icon: NfIcons.extensions,
    view: ExtensionsPanel(),
  );

  /// Order shown in the left bar.
  static const all = <SidePanel>[explorer, search, pub, extensions];

  /// The panel at [index], falling back to the nearest real one.
  ///
  /// The selected index outlives the list it points into — a panel removed in
  /// a later version would otherwise take the window down on the next launch.
  static SidePanel at(int index) => all[index.clamp(0, all.length - 1)];
}
