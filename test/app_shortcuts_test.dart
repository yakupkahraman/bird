import 'package:bird/app/bindings.dart';
import 'package:bird/features/hawk/hawk_view.dart';
import 'package:bird/features/search/file_index_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> pressCtrlK(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

/// The app's bindings around [body], with what Hawk reads.
Widget app(Widget body) => ChangeNotifierProvider(
  create: (_) => FileIndexProvider(),
  child: MaterialApp(
    home: AppShortcuts(child: Scaffold(body: body)),
  ),
);

void main() {
  testWidgets('shortcuts work with nothing focused', (tester) async {
    await tester.pumpWidget(app(const Text('no editor open')));

    await pressCtrlK(tester);

    expect(find.byType(HawkView), findsOneWidget);
  });

  testWidgets('shortcuts survive the focused editor going away', (
    tester,
  ) async {
    // A text field stands in for the editor; replacing it is closing its tab.
    await tester.pumpWidget(app(const TextField(autofocus: true)));
    await tester.pump();
    await tester.pumpWidget(app(const Text('tab closed')));

    await pressCtrlK(tester);

    expect(find.byType(HawkView), findsOneWidget);
  });
}
