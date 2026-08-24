import 'package:bird/core/ui/nf_icons.dart';
import 'package:bird/features/notifications/notification_overlay.dart';
import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late NotificationsProvider notifications;

  setUp(() => notifications = NotificationsProvider());
  tearDown(() => notifications.dispose());

  Future<void> pumpOverlay(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifications,
        child: const MaterialApp(home: Scaffold(body: NotificationOverlay())),
      ),
    );
    // Let the entrance animation finish so nothing is mid-fade.
    await tester.pumpAndSettle();
  }

  testWidgets('nothing is drawn while there is nothing to say', (tester) async {
    await pumpOverlay(tester);

    expect(find.byIcon(NfIcons.close), findsNothing);
    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('a message shows with its detail', (tester) async {
    notifications.error('Could not save main.dart', detail: 'Disk full');
    await pumpOverlay(tester);

    expect(find.text('Could not save main.dart'), findsOneWidget);
    expect(find.text('Disk full'), findsOneWidget);
    expect(find.byIcon(NfIcons.error), findsOneWidget);
  });

  testWidgets('each severity gets its own icon, and info retires', (
    tester,
  ) async {
    notifications.info('Formatted main.dart');
    notifications.warning('Analyzer is still starting');
    notifications.error('Could not save main.dart');
    await pumpOverlay(tester);

    expect(find.byIcon(NfIcons.info), findsOneWidget);
    expect(find.byIcon(NfIcons.warning), findsOneWidget);
    expect(find.byIcon(NfIcons.error), findsOneWidget);

    // Past the info message's lifetime: it goes on its own and the two that
    // report a problem stay. Draining the timer inside the test is also what
    // keeps flutter_test from failing on a pending one.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    expect(find.byIcon(NfIcons.info), findsNothing);
    expect(find.byIcon(NfIcons.warning), findsOneWidget);
    expect(find.byIcon(NfIcons.error), findsOneWidget);
  });

  testWidgets('clear all only appears once there is more than one', (
    tester,
  ) async {
    notifications.error('first');
    await pumpOverlay(tester);
    expect(find.text('Clear all'), findsNothing);

    notifications.error('second');
    await tester.pumpAndSettle();
    expect(find.text('Clear all'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsNothing);
  });

  testWidgets('the close button dismisses that message alone', (tester) async {
    notifications.error('first');
    notifications.error('second');
    await pumpOverlay(tester);

    await tester.tap(find.byIcon(NfIcons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
  });
}
