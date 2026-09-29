import 'package:bird/features/hawk/hawk.dart';
import 'package:bird/features/hawk/hawk_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A source that knows three words and records what Hawk did with it.
class WordSource extends HawkSource {
  WordSource(this.picked);

  final List<String> picked;
  var opened = 0;

  @override
  void onOpen(BuildContext context) => opened++;

  @override
  List<HawkItem> search(BuildContext context, String query) => [
    for (final word in const ['alpha', 'alpine', 'beta'])
      if (query.isNotEmpty && word.startsWith(query))
        HawkItem(title: word, run: (_) => picked.add(word)),
  ];
}

void main() {
  late List<String> picked;
  late WordSource source;

  Future<void> open(WidgetTester tester) async {
    picked = [];
    source = WordSource(picked);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => HawkView.show(context, sources: [source]),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('opening tells every source', (tester) async {
    await open(tester);

    expect(source.opened, 1);
  });

  testWidgets('typing lists what the sources return', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'al');
    await tester.pump();

    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('alpine'), findsOneWidget);
    expect(find.text('beta'), findsNothing);
  });

  testWidgets('arrows and enter pick an item, then Hawk closes', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'al');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(picked, ['alpine']);
    expect(find.byType(HawkView), findsNothing);
  });

  testWidgets('clicking an item picks it', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'b');
    await tester.pump();
    await tester.tap(find.text('beta'));
    await tester.pumpAndSettle();

    expect(picked, ['beta']);
  });

  testWidgets('escape closes without picking', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(HawkView), findsNothing);
    expect(picked, isEmpty);
  });
}
