import 'dart:ui';

import 'package:bird/core/ui/mini_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses square layout for icon-only button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniButton(tooltip: 'Add', icon: Icons.add),
        ),
      ),
    );

    final containerFinder = find.descendant(
      of: find.byType(MiniButton),
      matching: find.byType(Container),
    );

    final container = tester.widget<Container>(containerFinder);

    expect(container.constraints?.minHeight, 24);
    expect(container.constraints?.maxHeight, 24);
    expect(container.constraints?.minWidth, 24);
    expect(container.constraints?.maxWidth, 24);
  });

  testWidgets('uses wide layout when label is provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MiniButton(
            tooltip: "Add",
            label: "Flutter",
            icon: Icons.add,
          ), // isWide is true
        ),
      ),
    );

    final containerFinder = find.descendant(
      of: find.byType(MiniButton),
      matching: find.byType(Container),
    );

    final container = tester.widget<Container>(containerFinder);

    // Padding appears only when isWide is true
    expect(container.padding, const EdgeInsets.symmetric(horizontal: 4.0));
  });

  testWidgets('should change color when hovered', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: MiniButton(tooltip: 'Add', icon: Icons.add),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(MiniButton));
    final primary = Theme.of(context).colorScheme.primary;

    final containerFinder = find.descendant(
      of: find.byType(MiniButton),
      matching: find.byType(Container),
    );

    var container = tester.widget<Container>(containerFinder);

    final decoration = container.decoration as BoxDecoration;

    expect(decoration.color, Colors.transparent);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);

    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.byType(MiniButton)));

    await tester.pump();

    // Widget was rebuilt after onEnter -> setState()
    container = tester.widget<Container>(containerFinder);

    final hoveredDecoration = container.decoration as BoxDecoration;

    expect(hoveredDecoration.color, primary.withValues(alpha: 0.08));
  });

  testWidgets('use selected colors when selected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MiniButton(tooltip: "Add", icon: Icons.add, isSelected: true),
        ),
      ),
    );

    final context = tester.element(find.byType(MiniButton));
    final primary = Theme.of(context).colorScheme.primary;

    final containerFinder = find.descendant(
      of: find.byType(MiniButton),
      matching: find.byType(Container),
    );

    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, primary.withValues(alpha: 0.15));

    final icon = tester.widget<Icon>(find.byIcon(Icons.add));
    expect(icon.color, primary);
  });
}
