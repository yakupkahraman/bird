import 'dart:async';

import 'package:flutter/foundation.dart';

enum NotificationSeverity { info, warning, error }

/// One thing Bird has to tell the user.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.severity,
    required this.message,
    this.detail,
  });

  /// Identifies this notification for dismissal; ids are never reused.
  final int id;

  final NotificationSeverity severity;

  /// One line in the user's terms: what happened.
  final String message;

  /// The technical half — an OS error, a path — shown smaller underneath.
  /// Bird's users are developers, so it is worth showing rather than hiding.
  final String? detail;
}

/// Everything waiting to be read, oldest first.
///
/// Anything may post here and nothing has to thread the message back through
/// whatever widget triggered it — which is the whole reason this is app-wide
/// rather than a flag on the provider that failed.
class NotificationsProvider extends ChangeNotifier {
  /// [infoLifetime] is only passed by tests, which must not sit out the real
  /// one.
  NotificationsProvider({Duration? infoLifetime})
    : infoLifetime = infoLifetime ?? const Duration(seconds: 6);

  /// How long an info message stays up. Warnings and errors do not expire:
  /// something that went wrong must not scroll past while the user is typing.
  final Duration infoLifetime;

  /// Past this the oldest is dropped. A taller stack covers the editor, which
  /// is worse than losing the message the user has had longest to read.
  static const int maxVisible = 4;

  final List<AppNotification> _items = [];

  /// Auto-dismiss timers, kept so they can be cancelled: one firing after
  /// dispose would call `notifyListeners` on a dead notifier.
  final Map<int, Timer> _timers = {};

  int _nextId = 0;

  List<AppNotification> get items => List.unmodifiable(_items);

  void info(String message, {String? detail}) =>
      _add(NotificationSeverity.info, message, detail);

  void warning(String message, {String? detail}) =>
      _add(NotificationSeverity.warning, message, detail);

  void error(String message, {String? detail}) =>
      _add(NotificationSeverity.error, message, detail);

  void _add(NotificationSeverity severity, String message, String? detail) {
    final id = _nextId++;
    _items.add(
      AppNotification(
        id: id,
        severity: severity,
        message: message,
        detail: detail,
      ),
    );

    while (_items.length > maxVisible) {
      _timers.remove(_items.removeAt(0).id)?.cancel();
    }

    if (severity == NotificationSeverity.info) {
      _timers[id] = Timer(infoLifetime, () => dismiss(id));
    }

    notifyListeners();
  }

  void dismiss(int id) {
    _timers.remove(id)?.cancel();
    if (!_items.any((item) => item.id == id)) return;
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void dismissAll() {
    if (_items.isEmpty) return;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
