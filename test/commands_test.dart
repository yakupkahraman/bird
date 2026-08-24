import 'package:bird/app/bindings.dart';
import 'package:bird/features/commands/commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `SingleActivator` compares by identity, so two equal-looking activators are
/// never `==`. Everything below compares what they actually match on instead.
String describe(SingleActivator a) =>
    '${a.trigger.keyLabel}|${a.control}|${a.meta}|${a.shift}|${a.alt}';

void main() {
  test('no two commands share an id', () {
    final ids = Commands.all.map((command) => command.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('no two commands claim the same keys', () {
    final claimed = [
      for (final command in Commands.all)
        ...?command.key?.activators.map(describe),
    ];

    // Only checkable at all because the keys live in one list. A duplicate
    // would mean one shortcut silently shadowing another.
    expect(claimed.toSet(), hasLength(claimed.length));
  });

  test('bound is exactly the commands that are built and have a key', () {
    expect(
      Commands.bound.every(
        (command) => command.isImplemented && command.key != null,
      ),
      isTrue,
    );
    expect(Commands.bound.map((command) => command.id), [
      'file.save',
      'file.openFolder',
      'workbench.settings',
    ]);
  });

  group('key labels', () {
    test('the primary modifier is written for both desktops', () {
      expect(Commands.save.key!.label, 'Ctrl+S / Cmd+S');
      expect(Commands.settings.key!.label, 'Ctrl+, / Cmd+,');
    });

    test('extra modifiers come before the key', () {
      expect(Commands.commandPalette.key!.label, 'Ctrl+Shift+P / Cmd+Shift+P');
      expect(Commands.toggleRightPane.key!.label, 'Ctrl+Alt+B / Cmd+Alt+B');
      expect(Commands.newTerminal.key!.label, 'Ctrl+Shift+` / Cmd+Shift+`');
    });

    test('a key without the primary modifier is written once', () {
      expect(Commands.formatDocument.key!.label, 'Shift+Alt+F');
    });

    test('zoom is two commands, not one row with two keys', () {
      expect(Commands.zoomIn.key!.label, 'Ctrl+= / Cmd+=');
      expect(Commands.zoomOut.key!.label, 'Ctrl+- / Cmd+-');
    });
  });

  group('the shortcut map', () {
    testWidgets('holds an activator for every bound command, and nothing '
        'else', (tester) async {
      late Map<ShortcutActivator, VoidCallback> shortcuts;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              shortcuts = getAppShortcuts(context);
              return const SizedBox();
            },
          ),
        ),
      );

      final registered = shortcuts.keys.cast<SingleActivator>().map(describe);
      final expected = [
        for (final command in Commands.bound)
          ...command.key!.activators.map(describe),
      ];

      // The number is not the point: it is that this map is derived from the
      // same list the keymap renders, so a command can never appear in one and
      // be missing from the other.
      expect(registered.toSet(), expected.toSet());
      expect(shortcuts, hasLength(expected.length));
    });

    testWidgets('a command that is not built registers nothing', (
      tester,
    ) async {
      late Map<ShortcutActivator, VoidCallback> shortcuts;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              shortcuts = getAppShortcuts(context);
              return const SizedBox();
            },
          ),
        ),
      );

      final registered = shortcuts.keys
          .cast<SingleActivator>()
          .map(describe)
          .toSet();

      for (final activator in Commands.closeTab.key!.activators) {
        expect(registered, isNot(contains(describe(activator))));
      }
    });
  });
}
