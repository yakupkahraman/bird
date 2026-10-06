import 'package:bird/features/internal_views/account_view.dart';
import 'package:bird/features/commands/keymap_view.dart';
import 'package:bird/features/pub/pub_view.dart';
import 'package:bird/features/settings/settings_view.dart';
import 'package:bird/features/theme/themes_view.dart';
import 'package:bird/core/ui/nf_icons.dart';
import 'package:flutter/material.dart';

/// A built-in page that opens as a tab instead of a file, addressed as
/// `bird://<id>` so it can share the tab bar with real files.
class InternalView {
  final String id;
  final String title;
  final IconData icon;

  /// Const widget shown in the editor area. Unused by a view with a [builder].
  final Widget view;

  /// Set on a view opened on something, at `bird://<id>/<argument>`: one tab
  /// per argument, named after it, such as a pub.dev package.
  final Widget Function(String argument)? builder;

  const InternalView({
    required this.id,
    required this.title,
    required this.icon,
    this.view = const SizedBox.shrink(),
    this.builder,
  });

  String get path => 'bird://$id';

  /// Where a view with a [builder] opens on [argument].
  String pathFor(String argument) => '$path/$argument';
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

  static const pub = InternalView(
    id: 'pub',
    title: 'Package',
    icon: NfIcons.package,
    builder: PubView.new,
  );

  /// Order shown in the top bar menu; groups are separated by a divider.
  static const menuGroups = <List<InternalView>>[
    [account],
    [settings, keymap, themes],
  ];

  static final values = menuGroups.expand((group) => group).toList();

  /// Views opened on something rather than from the menu; see
  /// [InternalView.builder].
  static const withArgument = <InternalView>[pub];

  /// The view a tab path points at, or null for a regular file. A view with an
  /// argument comes back built for it, titled with the argument.
  static InternalView? of(String path) {
    if (values.where((view) => view.path == path).firstOrNull
        case final view?) {
      return view;
    }
    for (final view in withArgument) {
      if (!path.startsWith('${view.path}/')) continue;
      final argument = path.substring(view.path.length + 1);
      return InternalView(
        id: '${view.id}/$argument',
        title: argument,
        icon: view.icon,
        view: view.builder!(argument),
      );
    }
    return null;
  }
}
