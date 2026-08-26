import 'package:bird/core/ui/my_search.dart';
import 'package:bird/core/ui/nf_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows and clears the clear button correctly', ((tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MySearch())),
    );

    //Initially there is not text, so the clear button should not exist
    expect(find.byIcon(NfIcons.close), findsNothing);

    // Simulate typing into the search field
    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump();

    //The clear button should now be visible
    expect(find.byIcon(NfIcons.close), findsOneWidget);

    // Press the clear button
    await tester.tap(find.byIcon(NfIcons.close));
    await tester.pump();

    // The button disappears because the text is empty
    expect(find.byIcon(NfIcons.close), findsNothing);

    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller!.text, isEmpty);
  }));

  testWidgets('uses external controller when provided', (tester) async {
    //Create an external controller with initial text
    final controller = TextEditingController(text: "hello");

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MySearch(controller: controller)),
      ),
    );

    //Get the textField instance of the widget
    final textField = tester.widget<TextField>(find.byType(TextField));

    // Expect MySearch to use the exact external controller
    // and preserve its initial text.
    expect(textField.controller, same(controller));
    expect(textField.controller!.text, 'hello');
  });

  testWidgets('updates controller when widget controller changes', (
    tester,
  ) async {
    final firstController = TextEditingController(text: 'first');
    final secondController = TextEditingController(text: 'second');

    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);

    Widget buildSearch(TextEditingController controller) {
      return MaterialApp(
        home: Scaffold(body: MySearch(controller: controller)),
      );
    }

    await tester.pumpWidget(buildSearch(firstController));

    //Text field should point to the first controller
    TextField textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller, same(firstController));
    expect(textField.controller!.text, 'first');

    //Text field should now be updated
    await tester.pumpWidget(buildSearch(secondController));
    textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller, same(secondController));
    expect(textField.controller!.text, 'second');

    firstController.clear();
    await tester.pump();

    // Clearing the first controller should not affect MySearch.
    expect(find.byIcon(NfIcons.close), findsOneWidget);

    secondController.clear();
    await tester.pump();

    //Clearing the active controller should remove the text
    expect(find.byIcon(NfIcons.close), findsNothing);
  });
}
