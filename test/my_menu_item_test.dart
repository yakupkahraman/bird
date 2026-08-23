import 'package:bird/widgets/my_menu_item.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a menu item closes its own route once and returns its result', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: Text('shell'));
          },
        ),
      ),
    );

    final selected = showDialog<String>(
      context: pageContext,
      builder: (_) => const MyMenuItem(
        title: 'Settings',
        icon: NfIcons.settings,
        result: 'bird://settings',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(await selected, 'bird://settings');
    // The route below the menu must survive: a second pop would blank the app.
    expect(find.text('shell'), findsOneWidget);
  });
}
