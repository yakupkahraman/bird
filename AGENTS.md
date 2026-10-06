# AGENTS.md

Working rules for Bird IDE — for AI agents and humans alike.
Read this before touching the code.

## What Bird is

A desktop IDE for Flutter, written in Flutter. macOS, Linux, Windows only —
there is no mobile or web target. No Electron, no WebView, no Monaco. If a
change would pull in a web shell or an embedded browser, it does not belong here.

## Layout

```
lib/
  main.dart            App entry: bindings, window setup, runApp.
  app/                 Composition root. Knows every feature; nothing in
                       features/ or core/ may import it.
                       app.dart (MaterialApp), wiring.dart (the provider
                       tree), shell.dart (bars + panes), bindings.dart
                       (shortcuts, and the focus that keeps them live).
  core/                Feature-agnostic building blocks. Imports nothing from
                       app/ or features/ — that is what keeps it reusable.
                       ui/ (MyButton, MyTile, MySwitch, NfIcons, FileIcon...),
                       result.dart (Result), fuzzy.dart (fuzzy matching).
  features/<name>/     Everything one feature is, in one folder: its models,
                       its state, its I/O and its widgets. Today: editor,
                       workspace, search, hawk, pub, lsp, terminal, sdk,
                       settings, theme, layout, commands, notifications,
                       extensions, internal_views.
test/                  Tests.
```

A feature is a functional requirement, not a screen — `lsp` is a feature and
has no screen of its own. Everything it owns lives in its folder, so adding one
means adding a folder and deleting one means deleting a folder.

Inside a feature the files are flat and named for their job. One feature is
usually three of them, in a line: `x.dart` describes what a thing is,
`x_service.dart` does what cannot be done in memory, and `x_provider.dart`
holds the state and joins the two. The provider never spawns a process; the
service never calls `notifyListeners()`. Split a feature into subfolders only
once it passes six files.

Features import each other sideways where they must, and several do today.
Nothing imports upwards into `app/`.

## Rules

**Language.** All code, comments, commit messages, docs and user-facing strings
are in English, with no exceptions.

**Minimal diffs.** Write the fewest lines that solve the problem. No speculative
abstractions, no options nobody asked for, no reformatting unrelated code.
Small, readable diffs are what keep this project contributable.

**State lives in providers.** UI reads it with `context.watch<T>()` and writes it
with `context.read<T>()`. Widgets hold only ephemeral local state (hover,
controllers, focus). Providers never import a widget.

**`dart:io` lives in services.** Reading a file, listing a folder, spawning a
process or asking the OS anything happens in an `x_service.dart` (or
`settings_store.dart`), never in a provider and never in a widget. Services
take a `FileSystem` from `package:file` so a test can hand them an in-memory
one instead of the disk. The one deliberate exception is `top_bar.dart`, where
`Platform.isMacOS` decides where the window buttons go — that is layout, not
I/O.

**Slow work stays off the UI thread.** Anything that can take long — listing a
folder, searching, a language server, a shell — is asynchronous I/O or its own
process, owned by a service. Bird already runs `dart language-server`, the PTY,
ripgrep and `git` this way. A synchronous existence check or a tiny known file
is fine — settings are read that way so the first frame has the right theme —
but nothing that grows with the user's project. ripgrep ships inside the app via
`dart_ripgrep` and is never taken from PATH; on macOS the Xcode project's
"Embed ripgrep" build phase is what bundles it, so keep that phase. `git` is the
user's own and optional: without it, the explorer simply dims nothing.

**Errors the user asked for come back as `Result`, and go to
`NotificationsProvider`.** If someone pressed a key and the thing did not
happen, the provider posts `error(message, detail: ...)` and returns `Failed` —
a save that fails quietly is how work gets lost. The notification is what the
user sees, bottom right; the `Result` is for a caller that has to decide
something on the back of it. Info messages retire on their own, warnings and
errors wait to be dismissed.

Everything with a documented fallback stays `debugPrint`: a folder that will
not list shows empty, a config that will not parse falls back to the defaults,
a watch that cannot be set up simply does not watch. Not every `catch` is a
notification.

A state that belongs to one file, and that the user has to answer, stays inline
in the editor instead — the disk-conflict bar in `code_panel.dart` is the
example, and it is not a notification.

**Dispose what you own.** Every provider that owns a process, controller, or
listener kills it in `dispose()`. `LspProvider` owns the `dart language-server`
process; `TerminalProvider` owns the PTY; `EditorProvider` owns the editor
controllers. Leaking one leaves an orphan process behind after the app closes.

**Colors come from the theme.** Use `Theme.of(context).colorScheme.primary` /
`.secondary` / `scaffoldBackgroundColor`, and `.tertiary` for an accent — it is
the editor theme's keyword colour. `ThemeProvider.syntax('string')` and friends
give the rest of that palette when one accent is not enough. Never hardcode a color that should
follow the active theme. The editor's syntax palette in `code_panel.dart` is the
one deliberate exception.

**Icons come from `NfIcons`.** Nerd Font glyphs only, defined in
`core/ui/nf_icons.dart` with a doc comment. File-type icons come from
`FileIcon`. Do not use Material icons.

**Reuse the widget set.** `MyButton`, `MyIconButton`, `MiniButton`, `MyTile`,
`MySwitch`, `MySearch`, `MyMenuItem` already exist. Extend one before writing a
new one.

**Comments explain why.** The code already says what it does. Comment the
non-obvious constraint — a race, an ordering requirement, a library quirk. See
`editor_provider.dart` and `lsp_provider.dart` for the tone.

**What the app is made of goes in a registry.** Four lists say what exists,
and each is the only place its thing is declared:

- `features/commands/commands.dart` — every command, with its id, title,
  category, default key and what it does. `bindings.dart` and the keymap view
  are both built from it. A command with no `run` is declared but not built: it
  binds nothing, and the keymap shows it as "not bound yet" rather than
  promising a shortcut that does nothing.
- `features/internal_views/internal_views.dart` — every `bird://<id>` tab, with
  its id, title, icon and widget. The menu, tab bar, editor area and status bar
  all pick it up. Look a path up with `InternalViews.of(path)`; never compare
  against a `bird://` literal. A view opened on something, such as a pub.dev
  package, has a `builder` instead of a `view` and lives at
  `bird://<id>/<argument>` (see `pathFor`). These tabs have no file on disk, so
  anything path-based must skip them.
- `features/layout/side_panels.dart` — every sidebar panel, with its id, title,
  icon and widget. The left bar builds its buttons from it and the shell shows
  whichever is selected.
- `features/hawk/hawk_sources.dart` — everything Hawk, the Cmd/Ctrl+K search
  box, searches. Hawk owns the box, the keyboard and the list; a new kind of
  result is one `HawkSource` added here, with no change to Hawk itself.

Registering is how a feature reaches the chrome without editing it. Two lists
lining up by position is how the keymap came to advertise eight shortcuts
nobody had bound, and how inserting a sidebar panel would have handed every
panel after it the wrong icon.

## Before you finish

```bash
flutter analyze          # must be clean
dart format lib test
flutter test             # one test: flutter test test/x_test.dart --plain-name "name"
flutter run -d macos     # or -d linux / -d windows
```

Analyzer warnings are not acceptable. If a change affects the LSP lifecycle,
run `flutter test` — `test/lsp_provider_test.dart` counts real processes and
catches leaks.

## Commits

Conventional commits, imperative, one concern per commit:

```
feat: add git status markers to the file tree
fix: keep the terminal alive after a failed shell lookup
refactor: extract tab header into its own widget
docs: ...   chore: ...   test: ...
```

## Do not

- Add a dependency without a clear reason and a note in the PR.
- Commit generated or platform build output (`build/`, `.dart_tool/`, Pods).
- Broaden a task beyond what was asked.
- Add mobile or web platform folders back.
