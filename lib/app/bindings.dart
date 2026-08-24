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
