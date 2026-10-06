import 'package:bird/core/ui/my_search.dart';
import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/internal_views/internal_views.dart';
import 'package:bird/features/pub/pub_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The sidebar side of pub.dev: search, and the open project's packages.
/// Picking one opens its page as an editor tab.
class PubPanel extends StatefulWidget {
  const PubPanel({super.key});

  @override
  State<PubPanel> createState() => _PubPanelState();
}

class _PubPanelState extends State<PubPanel> {
  // Seeded from the provider: the panel is rebuilt from scratch whenever the
  // sidebar switches back to it, and the query should still be there.
  late final _controller = TextEditingController(
    text: context.read<PubProvider>().query,
  );

  @override
  void initState() {
    super.initState();
    // After the frame: loading notifies, which a build may not do.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PubProvider>().loadDependencies(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pub = context.watch<PubProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final hint = TextStyle(fontSize: 12, color: primary.withValues(alpha: 0.5));
    void open(String name) => context.read<EditorProvider>().openCustomTab(
      InternalViews.pub.pathFor(name),
    );

    final List<Widget> body;
    if (pub.query.isNotEmpty) {
      body = [
        if (pub.results.isEmpty)
          _Note(pub.isSearching ? 'Searching pub.dev...' : 'No packages found'),
        for (final name in pub.results)
          _PackageRow(
            name: name,
            detail: pub.package(name)?.description ?? '',
            trailing: pub.package(name)?.version,
            onTap: () => open(name),
          ),
      ];
    } else if (!pub.hasProject) {
      body = [
        const _Note('Open a Dart or Flutter project to see its packages'),
      ];
    } else {
      final dependencies = pub.dependencies ?? const [];
      body = [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            'INSTALLED',
            style: hint.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (pub.isLoadingDependencies && dependencies.isEmpty)
          const _Note('Reading pubspec...'),
        for (final dependency in dependencies)
          _PackageRow(
            name: dependency.name,
            detail: [
              dependency.current ?? 'not fetched',
              if (dependency.canUpgrade) '→ ${dependency.latest}',
              if (dependency.isDev) 'dev',
              if (dependency.isDiscontinued) 'discontinued',
            ].join('  '),
            onTap: () => open(dependency.name),
          ),
      ];
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          MySearch(
            controller: _controller,
            hintText: 'Search pub.dev',
            padding: const EdgeInsets.all(8),
            onChanged: pub.search,
          ),
          Expanded(child: ListView(children: body)),
        ],
      ),
    );
  }
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({
    required this.name,
    required this.detail,
    required this.onTap,
    this.trailing,
  });

  final String name;
  final String detail;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dim = TextStyle(fontSize: 11, color: primary.withValues(alpha: 0.55));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: primary),
                  ),
                ),
                if (trailing case final trailing?) Text(trailing, style: dim),
              ],
            ),
            if (detail.isNotEmpty)
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: dim,
              ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      ),
    ),
  );
}
