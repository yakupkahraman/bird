# Contributing to Bird IDE

Bird is under active development and every contribution counts — bug reports,
fixes, features, docs, design. Thank you for being here.

## Before anything else

Read **[AGENTS.md](AGENTS.md)**. It is the short list of conventions this
codebase follows: project layout, state management, theming, icons, comments and
commit style. It applies to human contributors and AI agents equally, and a PR
that ignores it will need a second round.

## Setup

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
`>=3.44.0` (Dart `^3.12.0`) and desktop build tools — Xcode on macOS, Visual
Studio with the C++ workload on Windows, `clang` + `cmake` + `ninja` +
`libgtk-3-dev` on Linux.

```bash
git clone https://github.com/yakupkahraman/bird.git
cd bird
flutter pub get
flutter run -d macos   # or -d linux / -d windows
```

## Workflow

1. **Open an issue first** for anything non-trivial, so effort is not duplicated
   and the approach can be agreed on early. Small fixes can go straight to a PR.
2. **Branch** from `main`: `feat/git-pane`, `fix/terminal-exit`, `docs/readme`.
3. **Build it** following the rules in [AGENTS.md](AGENTS.md). Keep the diff
   focused — one concern per PR.
4. **Check it:**
   ```bash
   flutter analyze     # must be clean
   dart format lib test
   flutter test
   ```
   Then run the app and confirm the change works for real. CI runs these same
   checks on every PR, plus a debug build on macOS, Linux and Windows.
5. **Commit** with conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`,
   `test:`, `chore:`.
6. **Open a PR** describing what changed and why. Add a screenshot or short clip
   for anything visual, and say which platform you tested on.

## Good first contributions

- Implement a shortcut listed in `ui/views/keymap_view.dart` — most of them are
  documented but not bound yet in `bindings.dart`.
- Wire up a setting in `ui/views/settings_view.dart` — the toggles render but do
  not persist yet. The selected theme does not survive a restart either.
- Fix the folder name in `ui/panels/explorer_panel.dart`: it splits on `/`, so
  it shows the full path on Windows.
- Extend `FileIcon` and `NfIcons` with missing file types.
- Add a language to `ProgLangProvider`.
- Write tests — coverage is thin outside `LspProvider`.

Bigger pieces are listed in the README roadmap: SDK management, pub.dev
integration, debugger, git pane, device manager, extensions.

## Reporting bugs

Include your OS, `flutter --version`, the steps to reproduce, what you expected,
and what happened. Console output or a screenshot helps a lot.

## License

By contributing you agree that your work is licensed under the
[GNU GPL v3.0](LICENSE).
