import 'package:bird/core/ui/my_button.dart';
import 'package:bird/core/ui/nf_icons.dart';
import 'package:bird/features/pub/pub_package.dart';
import 'package:bird/features/pub/pub_provider.dart';
import 'package:bird/features/pub/readme_view.dart';
import 'package:bird/features/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One pub.dev package in an editor tab, with what can be done to it.
class PubView extends StatefulWidget {
  const PubView(this.name, {super.key});

  final String name;

  @override
  State<PubView> createState() => _PubViewState();
}

/// What the page shows below the actions, as on pub.dev.
enum _Tab {
  readme('Readme', PubDoc.readme),
  changelog('Changelog', PubDoc.changelog),
  example('Example', PubDoc.example),
  installing('Installing'),
  versions('Versions');

  const _Tab(this.label, [this.doc]);

  final String label;

  /// The archive document behind the tab; null for the ones built here.
  final PubDoc? doc;
}

class _PubViewState extends State<PubView> {
  var _tab = _Tab.readme;

  @override
  void initState() {
    super.initState();
    // After the frame: loading notifies, which a build may not do.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PubProvider>().loadDependencies(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pub = context.watch<PubProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dim = TextStyle(fontSize: 12, color: primary.withValues(alpha: 0.55));
    final package = pub.package(widget.name);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              // A README reads badly as one line across a wide window.
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(name: widget.name, package: package),
                  if (package == null) ...[
                    const SizedBox(height: 16),
                    Text('Loading from pub.dev...', style: dim),
                  ] else ...[
                    if (package.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        package.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: primary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        _Stat(
                          NfIcons.heart,
                          _compact(package.likes),
                          'likes',
                          tint: 'string',
                        ),
                        _Stat(
                          NfIcons.check,
                          '${package.points}/${package.maxPoints}',
                          'pub points',
                          tint: 'number',
                        ),
                        _Stat(
                          NfIcons.download,
                          _compact(package.downloads),
                          'downloads in the last 30 days',
                          tint: 'built_in',
                        ),
                      ],
                    ),
                    if (package.platforms.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final platform in package.platforms)
                            _Pill(platform, color: theme.colorScheme.tertiary),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  _ActionBar(name: widget.name, package: package, pub: pub),
                  if (package != null) ...[
                    const SizedBox(height: 16),
                    _TabBar(
                      selected: _tab,
                      onSelected: (tab) => setState(() => _tab = tab),
                    ),
                    const SizedBox(height: 16),
                    _tabContent(pub, package, theme, dim),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on _PubViewState {
  Widget _tabContent(
    PubProvider pub,
    PubPackage package,
    ThemeData theme,
    TextStyle dim,
  ) {
    if (_tab == _Tab.versions) return _Versions(package: package);

    final String? data;
    if (_tab.doc case final doc?) {
      if (!pub.hasDocument(widget.name, doc)) {
        pub.document(widget.name, doc);
        return Text('Loading ${_tab.label.toLowerCase()}...', style: dim);
      }
      data = pub.document(widget.name, doc);
    } else {
      data = _installing(package);
    }
    if (data == null) {
      return Text(
        'This package has no ${_tab.label.toLowerCase()}.',
        style: dim,
      );
    }
    return ReadmeView(
      data: data,
      repository: package.repository ?? package.homepage,
      onOpenLink: pub.openInBrowser,
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelected});

  final _Tab selected;
  final ValueChanged<_Tab> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.tertiary;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: primary.withValues(alpha: 0.12)),
        ),
      ),
      child: Wrap(
        children: [
          for (final tab in _Tab.values)
            InkWell(
              onTap: () => onSelected(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color: tab == selected ? accent : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: tab == selected
                        ? accent
                        : primary.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Every published version, newest first, with when it came out.
class _Versions extends StatelessWidget {
  const _Versions({required this.package});

  final PubPackage package;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dim = TextStyle(fontSize: 12, color: primary.withValues(alpha: 0.55));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (:version, :published) in package.versions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    version,
                    style: TextStyle(fontSize: 13, color: primary),
                  ),
                ),
                if (published != null)
                  Text(
                    published.toIso8601String().substring(0, 10),
                    style: dim,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// pub.dev's Installing tab, which needs nothing but the name and version.
String _installing(PubPackage package) =>
    '''
Run this command in your project:

```
flutter pub add ${package.name}
```

It adds a line like this to `pubspec.yaml`:

```yaml
dependencies:
  ${package.name}: ^${package.version}
```

Then import it in your Dart code:

```dart
import 'package:${package.name}/${package.name}.dart';
```
''';

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.package});

  final String name;
  final PubPackage? package;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final accent = theme.colorScheme.tertiary;
    final dim = TextStyle(fontSize: 12, color: primary.withValues(alpha: 0.6));
    final package = this.package;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(NfIcons.package, size: 28, color: accent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  if (package != null) _Pill(package.version, color: accent),
                  if (package?.isDiscontinued ?? false)
                    _Pill('discontinued', color: theme.colorScheme.error),
                ],
              ),
              if (package != null) ...[
                const SizedBox(height: 4),
                Row(
                  spacing: 6,
                  children: [
                    if (package.publisher case final publisher?) ...[
                      Icon(
                        NfIcons.verified,
                        size: 12,
                        color: context.watch<ThemeProvider>().syntax(
                          'built_in',
                        ),
                      ),
                      Text(publisher, style: dim),
                    ],
                    if (package.publisher != null && package.license != null)
                      Text('·', style: dim),
                    if (package.license case final license?)
                      Text(license, style: dim),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Add, upgrade or remove on the left, where to read more on the right.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.name,
    required this.package,
    required this.pub,
  });

  final String name;
  final PubPackage? package;
  final PubProvider pub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final package = this.package;

    return Container(
      // Full width, so the links sit at the far end rather than beside the
      // buttons.
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Actions(name: name, pub: pub),
          if (package != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, link) in [
                  ('pub.dev', package.pubUri.toString()),
                  ('Repository', package.repository),
                  ('Homepage', package.homepage),
                ])
                  if (link != null && link.isNotEmpty)
                    MyButton.outline(
                      label: label,
                      height: 30,
                      fontSize: 12,
                      onPressed: () => pub.openInBrowser(Uri.parse(link)),
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

/// What can be done to the package, depending on where it stands in the
/// open project.
class _Actions extends StatelessWidget {
  const _Actions({required this.name, required this.pub});

  final String name;
  final PubProvider pub;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final note = TextStyle(fontSize: 12, color: primary.withValues(alpha: 0.6));

    if (!pub.hasProject) {
      return Text(
        'Open a Dart or Flutter project to add packages.',
        style: note,
      );
    }
    if (pub.isBusy(name)) return Text('Running flutter pub...', style: note);
    if (pub.dependencies == null) {
      return Text(
        pub.isLoadingDependencies ? 'Checking the project...' : '',
        style: note,
      );
    }

    final Dependency? dependency = pub.dependency(name);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: dependency == null
          ? [
              MyButton(
                label: 'Add',
                icon: NfIcons.add,
                height: 32,
                onPressed: () => pub.add(name),
              ),
              MyButton.secondary(
                label: 'Add as dev',
                height: 32,
                onPressed: () => pub.add(name, dev: true),
              ),
            ]
          : [
              if (dependency.canUpgrade)
                MyButton(
                  label: 'Upgrade to ${dependency.latest}',
                  height: 32,
                  onPressed: () => pub.upgrade(name),
                ),
              MyButton.outline(
                label: 'Remove',
                icon: NfIcons.trash,
                height: 32,
                onPressed: () => pub.remove(name),
              ),
            ],
    );
  }
}

/// An icon and a number; what it counts is in the tooltip.
class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.meaning, {required this.tint});

  final IconData icon;
  final String value;
  final String meaning;

  /// The syntax colour the icon takes, so each stat has its own.
  final String tint;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: meaning,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(
            icon,
            size: 14,
            color: context.watch<ThemeProvider>().syntax(tint),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: primary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.color});

  final String text;

  /// Defaults to the theme's text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

/// 12497778 as `12.5M`, the way pub.dev itself shortens counts.
String _compact(int n) => switch (n) {
  >= 1000000 => '${(n / 1000000).toStringAsFixed(1)}M',
  >= 1000 => '${(n / 1000).toStringAsFixed(1)}K',
  _ => '$n',
};
