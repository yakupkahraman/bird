# CLAUDE.md

Operating notes for Claude Code in this repo. The project rules are **not** here
— they live in the files below, and this file must not restate them.

## Read first

- **[AGENTS.md](AGENTS.md)** — project layout, code conventions, and the
  pre-finish checklist. This is the contract; follow it exactly.
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — workflow, commit style, and the
  current list of open tasks worth picking up.

## Tooling in this repo

- Prefer the `dart-flutter` MCP tools over shelling out: `analyze_files` instead
  of `flutter analyze`, `hot_reload` / `hot_restart` against a running app,
  `get_runtime_errors` for live exceptions, `pub` for dependency changes.
- `flutter test` takes ~15s because `test/lsp_provider_test.dart` starts real
  `dart language-server` processes and counts them with `ps`. Nothing is mocked;
  a failure there means a process really leaked.
- Widget tests run without code_forge's native library. Constructing a
  `CodeForgeController` throws `flutter_rust_bridge has not been initialized`,
  so keep tests off the editor path — `test/internal_views_test.dart` shows the
  pattern.
- A debug build for your own platform (`flutter build macos|linux|windows
  --debug`) is the cheapest proof the app still compiles. CI builds all three on
  every PR, so leave the other two to it.

## Working agreements

- **Do not commit or push unless you are asked to.** Leave finished work in the
  working tree and say what changed and how it was verified; whoever you are
  working with decides what gets committed.
- Everything written into the repo — code, comments, docs, commit messages — is
  English, whatever language you are talking in.
- Report honestly: name what was verified, and what was not. "Builds and
  analyzes clean" is not the same claim as "I ran the app and clicked it".
