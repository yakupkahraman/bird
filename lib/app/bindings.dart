import 'package:bird/features/commands/commands.dart';
import 'package:flutter/widgets.dart';

/// The key bindings, built from the command catalogue.
///
/// Every command declares its own default key, so there is no second list here
/// to drift out of step with it. A command that is not built yet registers
/// nothing, which is why the keymap can list it without it silently failing.
Map<ShortcutActivator, VoidCallback> getAppShortcuts(BuildContext context) {
  return {
    for (final command in Commands.bound)
      for (final activator in command.key!.activators)
        activator: () => command.run!(context),
  };
}

/// The app's key bindings, live wherever focus is in [child].
///
/// Key events travel up from whatever has focus. With no editor focused, focus
/// sits on the route above the shell, so the bindings never saw the keys and
/// Cmd+K only worked with a tab open. The [Focus] here holds focus whenever
/// nothing else does, including after the focused editor's tab is closed.
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: getAppShortcuts(context),
    child: Focus(autofocus: true, child: child),
  );
}
