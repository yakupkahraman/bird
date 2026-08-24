import 'package:bird/core/ui/my_icon_button.dart';
import 'package:bird/core/ui/nf_icons.dart';
import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The stack of notifications in the bottom right corner.
///
/// Newest at the bottom, nearest the status bar, so a message arriving while
/// the user is reading one does not shove it out from under their eyes.
class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key});

  static const double width = 340;

  @override
  Widget build(BuildContext context) {
    final items = context.watch<NotificationsProvider>().items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (items.length > 1) const _ClearAll(),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            // Keyed by id so an arriving notification animates in and the ones
            // already up do not.
            child: _Toast(key: ValueKey(item.id), notification: item),
          ),
      ],
    );
  }
}

class _ClearAll extends StatelessWidget {
  const _ClearAll();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.read<NotificationsProvider>().dismissAll(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          child: Text(
            'Clear all',
            style: TextStyle(
              fontSize: 11,
              color: primary.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final (IconData icon, Color accent) = switch (notification.severity) {
      NotificationSeverity.error => (NfIcons.error, theme.colorScheme.error),
      NotificationSeverity.warning => (NfIcons.warning, Colors.orangeAccent),
      NotificationSeverity.info => (NfIcons.info, primary),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset((1 - progress) * 24, 0),
          child: child,
        ),
      ),
      child: Container(
        width: NotificationOverlay.width,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: primary.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 10.0, 4.0, 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Icon(icon, size: 13, color: accent),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: primary.withValues(alpha: 0.9),
                      ),
                    ),
                    if (notification.detail case final detail?) ...[
                      const SizedBox(height: 5),
                      Text(
                        detail,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'FiraCode',
                          fontSize: 10.5,
                          height: 1.35,
                          color: primary.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              MyIconButton(
                icon: NfIcons.close,
                size: 13,
                tooltip: 'Dismiss',
                onPressed: () => context.read<NotificationsProvider>().dismiss(
                  notification.id,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
