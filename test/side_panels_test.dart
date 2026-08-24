import 'package:bird/core/ui/my_icon_button.dart';
import 'package:bird/features/layout/left_bar.dart';
import 'package:bird/features/layout/panes_provider.dart';
import 'package:bird/features/layout/side_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('no two panels share an id', () {
    final ids = SidePanels.all.map((panel) => panel.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every panel has a button label', () {
    // The left bar is icons only, so the title is the only thing telling the
    // user what a button does.
    expect(SidePanels.all.every((panel) => panel.title.isNotEmpty), isTrue);
  });

  test('a stale index falls back instead of throwing', () {
    // The selected index outlives the list it points into.
    expect(SidePanels.at(99), SidePanels.all.last);
    expect(SidePanels.at(-1), SidePanels.all.first);
  });

  testWidgets('the left bar draws one button per registered panel', (
    tester,
  ) async {
    final panes = PanesProvider();
    addTearDown(panes.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: panes,
        child: const MaterialApp(home: Scaffold(body: LeftBar())),
      ),
    );

    expect(find.byType(MyIconButton), findsNWidgets(SidePanels.all.length));
    // Icons and labels come from the same entry, so they cannot disagree.
    for (final panel in SidePanels.all) {
      expect(find.byIcon(panel.icon), findsOneWidget);
      expect(find.byTooltip(panel.title), findsOneWidget);
    }
  });

  testWidgets('tapping a button selects that panel', (tester) async {
    final panes = PanesProvider();
    addTearDown(panes.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: panes,
        child: const MaterialApp(home: Scaffold(body: LeftBar())),
      ),
    );

    await tester.tap(find.byIcon(SidePanels.extensions.icon));
    await tester.pump();

    expect(SidePanels.at(panes.selectedSidebarIndex), SidePanels.extensions);
  });
}
