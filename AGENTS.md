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
  main.dart            App entry: window setup, provider tree.
  bindings.dart        Global keyboard shortcuts.
  shell_page.dart      Root layout: bars + panes.
  providers/           State (ChangeNotifier). No widgets here.
  theme/               ThemeProvider + ThemeData factory.
  ui/bars/             Top, left and bottom chrome.
  ui/panels/           Pane contents (explorer, code, terminal, extensions).
  ui/views/            Full-screen tab contents (settings, themes, keymap...).
  widgets/             Reusable, feature-agnostic widgets.
test/                  Tests, mirroring the lib/ path.
```

Put a file where its siblings are. A new pane goes in `ui/panels/`, a new piece
of shared state goes in `providers/`.

## Rules

**Language.** All code, comments, commit messages, docs and user-facing strings
are in English, with no exceptions.

**Minimal diffs.** Write the fewest lines that solve the problem. No speculative
abstractions, no options nobody asked for, no reformatting unrelated code.
Small, readable diffs are what keep this project contributable.

**State lives in providers.** UI reads it with `context.watch<T>()` and writes it
with `context.read<T>()`. Widgets hold only ephemeral local state (hover,
controllers, focus). Providers never import from `ui/` or `widgets/`.

**Dispose what you own.** Every provider that owns a process, controller, or
listener kills it in `dispose()`. `LspProvider` owns the `dart language-server`
process; `TerminalProvider` owns the PTY; `FileProvider` owns the editor
controllers. Leaking one leaves an orphan process behind after the app closes.

**Colors come from the theme.** Use `Theme.of(context).colorScheme.primary` /
`.secondary` / `scaffoldBackgroundColor`. Never hardcode a color that should
follow the active theme. The editor's syntax palette in `code_panel.dart` is the
one deliberate exception.

**Icons come from `NfIcons`.** Nerd Font glyphs only, defined in
`widgets/nf_icons.dart` with a doc comment. File-type icons come from
`FileIcon`. Do not use Material icons.

**Reuse the widget set.** `MyButton`, `MyIconButton`, `MiniButton`, `MyTile`,
`MySwitch`, `MySearch`, `MyMenuItem` already exist. Extend one before writing a
new one.

**Comments explain why.** The code already says what it does. Comment the
non-obvious constraint — a race, an ordering requirement, a library quirk. See
`file_provider.dart` and `lsp_provider.dart` for the tone.

**Internal views go in the registry.** Settings, themes, keymap and account open
as `bird://<id>` tabs. Register a new one in `InternalViews.menuGroups`
(`ui/views/internal_views.dart`) — id, title, icon and widget in one place — and
the menu, tab bar, editor area and status bar pick it up. Look a path up with
`InternalViews.of(path)`; never compare against a `bird://` literal. These tabs
have no file on disk, so anything path-based must skip them.

## Before you finish

```bash
flutter analyze          # must be clean
dart format lib test
flutter test
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
