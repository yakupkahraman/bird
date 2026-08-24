import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/settings/settings_view.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// A key combination, declared once and read by everything that cares.
///
/// [primary] is Ctrl on Windows and Linux and Cmd on macOS — a command never
/// spells that difference out itself, and both are registered so one
/// declaration works on every desktop Bird runs on.
class CommandKey {
  const CommandKey(
    this.key, {
    this.primary = true,
    this.shift = false,
    this.alt = false,
  });

  final LogicalKeyboardKey key;
  final bool primary;
  final bool shift;
  final bool alt;

  List<SingleActivator> get activators => [
    if (primary)
      SingleActivator(key, control: true, shift: shift, alt: alt)
    else
      SingleActivator(key, shift: shift, alt: alt),
    if (primary) SingleActivator(key, meta: true, shift: shift, alt: alt),
  ];

  String get _tail =>
      [if (shift) 'Shift', if (alt) 'Alt', key.keyLabel].join('+');

  /// How the keymap writes it, e.g. `Ctrl+Shift+P / Cmd+Shift+P`.
  String get label => primary ? 'Ctrl+$_tail / Cmd+$_tail' : _tail;
}

/// Something Bird can do, named in one place.
///
/// [id] is what a key binding, a menu entry or — once there are extensions —
/// somebody else's code refers to. A command with no [run] is declared but not
/// built yet: the keymap lists it as such instead of promising a shortcut that
/// does nothing, and nothing registers a binding for it.
class Command {
  const Command({
    required this.id,
    required this.title,
    required this.category,
    this.key,
    this.run,
  });

  final String id;
  final String title;
  final String category;
  final CommandKey? key;
  final void Function(BuildContext context)? run;

  bool get isImplemented => run != null;
}

/// Registry of every command.
///
/// [all] is the single source of truth: a command added there is picked up by
/// the key bindings and the keymap view at once. Nothing else should hold a
/// list of shortcuts — two lists is how the keymap came to advertise eight
/// shortcuts that were never bound.
class Commands {
  const Commands._();

  static const save = Command(
    id: 'file.save',
    title: 'Save File',
    category: 'File',
    key: CommandKey(LogicalKeyboardKey.keyS),
    run: _save,
  );

  static const openFolder = Command(
    id: 'file.openFolder',
    title: 'Open Folder / Project',
    category: 'File',
    key: CommandKey(LogicalKeyboardKey.keyO),
    run: _openFolder,
  );

  static const settings = Command(
    id: 'workbench.settings',
    title: 'Settings',
    category: 'General',
    key: CommandKey(LogicalKeyboardKey.comma),
    run: _settings,
  );

  static const toggleLeftPane = Command(
    id: 'view.toggleLeftPane',
    title: 'Toggle Left Sidebar (Explorer)',
    category: 'View',
    key: CommandKey(LogicalKeyboardKey.keyB),
  );

  static const toggleBottomPane = Command(
    id: 'view.toggleBottomPane',
    title: 'Toggle Bottom Panel (Terminal)',
    category: 'View',
    key: CommandKey(LogicalKeyboardKey.keyJ),
  );

  static const toggleRightPane = Command(
    id: 'view.toggleRightPane',
    title: 'Toggle Right Sidebar',
    category: 'View',
    key: CommandKey(LogicalKeyboardKey.keyB, alt: true),
  );

  static const closeTab = Command(
    id: 'editor.closeTab',
    title: 'Close Active Editor Tab',
    category: 'Editor',
    key: CommandKey(LogicalKeyboardKey.keyW),
  );

  static const formatDocument = Command(
    id: 'editor.formatDocument',
    title: 'Format Document',
    category: 'Editor',
    key: CommandKey(
      LogicalKeyboardKey.keyF,
      primary: false,
      shift: true,
      alt: true,
    ),
  );

  static const zoomIn = Command(
    id: 'editor.zoomIn',
    title: 'Zoom In',
    category: 'View',
    key: CommandKey(LogicalKeyboardKey.equal),
  );

  static const zoomOut = Command(
    id: 'editor.zoomOut',
    title: 'Zoom Out',
    category: 'View',
    key: CommandKey(LogicalKeyboardKey.minus),
  );

  static const quickOpen = Command(
    id: 'navigation.quickOpen',
    title: 'Quick Open / Find File',
    category: 'Navigation',
    key: CommandKey(LogicalKeyboardKey.keyP),
  );

  static const commandPalette = Command(
    id: 'workbench.commandPalette',
    title: 'Command Palette',
    category: 'General',
    key: CommandKey(LogicalKeyboardKey.keyP, shift: true),
  );

  static const newTerminal = Command(
    id: 'terminal.new',
    title: 'New Integrated Terminal',
    category: 'Terminal',
    key: CommandKey(LogicalKeyboardKey.backquote, shift: true),
  );

  /// Order shown in the keymap.
  static const all = <Command>[
    save,
    openFolder,
    closeTab,
    formatDocument,
    quickOpen,
    commandPalette,
    settings,
    toggleLeftPane,
    toggleBottomPane,
    toggleRightPane,
    zoomIn,
    zoomOut,
    newTerminal,
  ];

  /// The commands that are built and have a key, which is exactly what the
  /// shortcut map can be made of.
  static Iterable<Command> get bound =>
      all.where((command) => command.isImplemented && command.key != null);
}

void _save(BuildContext context) => context.read<EditorProvider>().saveFile();

void _openFolder(BuildContext context) =>
    context.read<WorkspaceProvider>().pickFolder();

void _settings(BuildContext context) => SettingsView.show(context);
