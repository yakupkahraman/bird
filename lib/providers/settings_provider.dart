import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Bird's configuration, kept in a plain JSON file the user can read and edit.
///
/// Two layers are merged over the built-in defaults: the user's own settings,
/// and the ones committed alongside an opened project. The workspace layer wins,
/// so a team can pin the editor config for everyone who opens the folder.
///
/// The format is plain JSON — no comments, no trailing commas. The settings view
/// rewrites the file, and anything `dart:convert` cannot round-trip would be
/// destroyed on the next toggle.
class SettingsProvider extends ChangeNotifier {
  /// Loads synchronously: this is one small file, and reading it before the
  /// first frame is what keeps the app from painting in the wrong theme and
  /// then snapping to the right one.
  ///
  /// [userFile] is only passed by tests, which must not touch the real config.
  SettingsProvider({String? userFile})
    : userFile = userFile ?? p.join(defaultDirectory, fileName) {
    _userValues = _read(this.userFile) ?? {};
    _watchUserFile();
  }

  /// Where this instance keeps the user's own settings.
  final String userFile;

  static const String fileName = 'settings.json';

  /// The directory an opened project keeps its shared settings in.
  static const String workspaceDirectory = '.bird';

  static const Map<String, Object?> defaults = {
    'editor.fontSize': 13,
    'editor.tabSize': 2,
    'editor.wordWrap': false,
    'editor.lineNumbers': true,
    'workbench.colorTheme': 'vs2015',
  };

  Map<String, Object?> _userValues = {};
  Map<String, Object?> _workspaceValues = {};
  String? _workspacePath;
  StreamSubscription<FileSystemEvent>? _watch;

  /// The configuration directory.
  ///
  /// macOS shares `~/.config` with Linux rather than using
  /// `~/Library/Application Support`. This is a file people keep in their
  /// dotfiles, next to the rest of their tooling, and every developer-first
  /// editor puts it there. Windows has no such convention, so it keeps
  /// `%APPDATA%`.
  static String get defaultDirectory {
    // Honoured on every platform, not just Linux: setting it is deliberate.
    // Per the XDG spec an empty value means "unset", so fall through.
    final xdg = Platform.environment['XDG_CONFIG_HOME'];
    if (xdg != null && xdg.isNotEmpty) return p.join(xdg, 'bird');

    if (Platform.isWindows) {
      final appData =
          Platform.environment['APPDATA'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      return p.join(appData, 'Bird');
    }

    return p.join(Platform.environment['HOME'] ?? '', '.config', 'bird');
  }

  /// The workspace settings file, or null while no folder is open.
  String? get workspaceFile => _workspacePath == null
      ? null
      : p.join(_workspacePath!, workspaceDirectory, fileName);

  double get editorFontSize => _number('editor.fontSize').toDouble();
  int get editorTabSize => _number('editor.tabSize').toInt();
  bool get editorWordWrap => _boolean('editor.wordWrap');
  bool get editorLineNumbers => _boolean('editor.lineNumbers');
  String get colorTheme => _string('workbench.colorTheme');

  /// Called when a folder is opened, so the project's own settings apply.
  void setWorkspace(String? rootPath) {
    if (rootPath == _workspacePath) return;
    _workspacePath = rootPath;
    _workspaceValues = workspaceFile == null ? {} : _read(workspaceFile!) ?? {};
    notifyListeners();
  }

  /// Creates the file if nothing has been changed yet, so that "open
  /// settings.json" always has something to open. It starts out empty: writing
  /// the defaults into it would freeze them, and a later Bird could never move
  /// one without silently disagreeing with every file already on disk.
  Future<String> ensureUserFile() async {
    if (!File(userFile).existsSync()) await _writeFile(userFile, _userValues);
    return userFile;
  }

  /// The workspace equivalent, or null while no folder is open. `.bird/` is
  /// only created here — that is, when someone explicitly asks for the file —
  /// so Bird never leaves a folder in a project that did not want one.
  Future<String?> ensureWorkspaceFile() async {
    final path = workspaceFile;
    if (path == null) return null;
    if (!File(path).existsSync()) await _writeFile(path, _workspaceValues);
    return path;
  }

  /// Writes to the user layer, leaving keys Bird does not know about alone so a
  /// newer Bird's settings survive being opened by an older one.
  Future<void> set(String key, Object? value) async {
    if (_effective(key) == value && _userValues[key] == value) return;
    _userValues[key] = value;
    notifyListeners();
    await _write();
  }

  Object? _effective(String key) =>
      _workspaceValues[key] ?? _userValues[key] ?? defaults[key];

  /// A hand-edited file can hold anything, so a value of the wrong type falls
  /// back to the default rather than crashing the app that reads it.
  num _number(String key) {
    final value = _effective(key);
    return value is num ? value : defaults[key]! as num;
  }

  bool _boolean(String key) {
    final value = _effective(key);
    return value is bool ? value : defaults[key]! as bool;
  }

  String _string(String key) {
    final value = _effective(key);
    return value is String ? value : defaults[key]! as String;
  }

  /// Null means the file could not be read — missing, half-written, or not
  /// valid JSON. That is deliberately different from an empty file: writing is
  /// a temporary file renamed over this one, and a watch event landing inside
  /// that window would otherwise report "no settings" and wipe them.
  Map<String, Object?>? _read(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? Map.of(decoded) : {};
    } catch (e) {
      // A broken file must not stop the app from starting; the defaults win
      // until the user fixes it.
      debugPrint('Failed to read settings from $path: $e');
      return null;
    }
  }

  Future<void> _write() => _writeFile(userFile, _userValues);

  /// Writes through a temporary file, so a crash mid-write cannot leave a
  /// truncated config behind.
  Future<void> _writeFile(String path, Map<String, Object?> values) async {
    try {
      final directory = Directory(p.dirname(path));
      if (!directory.existsSync()) await directory.create(recursive: true);

      final temporary = File('$path.tmp');
      await temporary.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(values)}\n',
      );
      await temporary.rename(path);
    } catch (e) {
      debugPrint('Failed to write settings to $path: $e');
    }
  }

  /// Picks up edits made outside the settings view — including ones made in
  /// Bird itself, since settings.json opens as an ordinary tab.
  ///
  /// Only the user file is watched. Watching a workspace would mean either
  /// creating `.bird/` in a project that never asked for it, or walking the
  /// whole tree; its settings are re-read when the folder is opened instead.
  void _watchUserFile() {
    try {
      final directory = Directory(p.dirname(userFile));
      if (!directory.existsSync()) directory.createSync(recursive: true);

      _watch = directory.watch().listen((event) {
        if (!p.equals(event.path, userFile)) return;
        // Keep what is in memory when the file cannot be read: it is more
        // likely mid-rename than genuinely empty.
        final reloaded = _read(userFile);
        if (reloaded == null) return;

        // Comparing the encoded form keeps this free of package:collection;
        // our own writes land here too, and must not loop back as a change.
        if (jsonEncode(reloaded) == jsonEncode(_userValues)) return;
        _userValues = reloaded;
        notifyListeners();
      });
    } catch (e) {
      // Watching is a convenience; the app is still usable without it.
      debugPrint('Failed to watch ${p.dirname(userFile)}: $e');
    }
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }
}
