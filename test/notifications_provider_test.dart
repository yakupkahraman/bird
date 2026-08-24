import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const brief = Duration(milliseconds: 20);
  late NotificationsProvider notifications;

  setUp(() => notifications = NotificationsProvider(infoLifetime: brief));
  tearDown(() => notifications.dispose());

  test('a posted message carries its severity and detail', () {
    notifications.error('Could not save main.dart', detail: 'Disk full');

    final posted = notifications.items.single;
    expect(posted.severity, NotificationSeverity.error);
    expect(posted.message, 'Could not save main.dart');
    expect(posted.detail, 'Disk full');
  });

  test('posting notifies, so the overlay rebuilds', () {
    var notified = 0;
    notifications.addListener(() => notified++);

    notifications.info('Formatted main.dart');

    expect(notified, 1);
  });

  test('the newest is last, nearest the status bar', () {
    notifications.error('first');
    notifications.error('second');

    expect(notifications.items.map((item) => item.message), [
      'first',
      'second',
    ]);
  });

  test('an info message retires on its own', () async {
    notifications.info('Formatted main.dart');
    expect(notifications.items, hasLength(1));

    await Future<void>.delayed(brief * 2);

    expect(notifications.items, isEmpty);
  });

  test('a warning and an error stay until they are dismissed', () async {
    notifications.warning('Analyzer is still starting');
    notifications.error('Could not save main.dart');

    await Future<void>.delayed(brief * 2);

    // Something that went wrong must not scroll past while the user types.
    expect(notifications.items, hasLength(2));
  });

  test('dismissing takes only the one asked for', () {
    notifications.error('first');
    notifications.error('second');

    notifications.dismiss(notifications.items.first.id);

    expect(notifications.items.single.message, 'second');
  });

  test('dismissing something already gone notifies nobody', () {
    notifications.error('first');
    final id = notifications.items.single.id;
    notifications.dismiss(id);

    var notified = 0;
    notifications.addListener(() => notified++);
    notifications.dismiss(id);

    expect(notified, 0);
  });

  test('dismissAll clears the stack', () {
    notifications.error('first');
    notifications.warning('second');

    notifications.dismissAll();

    expect(notifications.items, isEmpty);
  });

  test('beyond maxVisible the oldest is dropped', () {
    for (var i = 0; i <= NotificationsProvider.maxVisible; i++) {
      notifications.error('message $i');
    }

    expect(notifications.items, hasLength(NotificationsProvider.maxVisible));
    expect(notifications.items.first.message, 'message 1');
  });

  test('a pending timer does not outlive the provider', () async {
    notifications.info('Formatted main.dart');
    notifications.dispose();

    // Firing after dispose would throw "A ChangeNotifier was used after being
    // disposed", which is exactly the leak this guards.
    await Future<void>.delayed(brief * 2);

    // Already disposed; keep tearDown from doing it twice.
    notifications = NotificationsProvider(infoLifetime: brief);
  });
}
