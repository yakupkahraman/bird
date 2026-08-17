import 'package:bird/ui/views/account_view.dart';
import 'package:bird/ui/views/keymap_view.dart';
import 'package:bird/ui/views/settings_view.dart';
import 'package:bird/ui/views/themes_view.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';

/// A built-in page that opens as a tab instead of a file, addressed as
/// `bird://<id>` so it can share the tab bar with real files.
class InternalView {
  final String id;
  final String title;
  final IconData icon;

  /// Const widget shown in the editor area; internal views take no arguments.
  final Widget view;

  const InternalView({
    required this.id,
    required this.title,
    required this.icon,
    required this.view,
  });

  String get path => 'bird://$id';
}

/// Registry of every internal view.
///
/// [menuGroups] is the single source of truth: a view added there is picked up
/// by the top bar menu, the tab bar, the editor area and the status bar at
/// once. Nothing else in the app should match on a `bird://` path by hand.
class InternalViews {
  static const account = InternalView(
    id: 'account',
    title: 'Account',
    icon: NfIcons.profile,
    view: AccountView(),
  );

  static const settings = InternalView(
    id: 'settings',
    title: 'Settings',
    icon: NfIcons.settings,
    view: SettingsView(),
  );

  static const keymap = InternalView(
    id: 'keymap',
    title: 'Keymap',
    icon: NfIcons.keyboard,
    view: KeymapView(),
  );

  static const themes = InternalView(
    id: 'themes',
    title: 'Themes',
    icon: NfIcons.palette,
    view: ThemesView(),
  );

  /// Order shown in the top bar menu; groups are separated by a divider.
  static const menuGroups = <List<InternalView>>[
    [account],
    [settings, keymap, themes],
  ];

  static final values = menuGroups.expand((group) => group).toList();

  /// The view a tab path points at, or null for a regular file.
  static InternalView? of(String path) =>
      values.where((view) => view.path == path).firstOrNull;
}
