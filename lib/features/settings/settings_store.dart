import 'dart:convert';
import 'dart:io' show Platform;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Reads and writes Bird's settings files, and reports when one changes.
///
/// Holds no settings of its own: it moves JSON between a path and a map, and
/// what any of it means is [SettingsProvider]'s business. [fileSystem] is only
/// passed by tests, which must not touch the real config.
class SettingsStore {
  SettingsStore({FileSystem? fileSystem})
    : _fs = fileSystem ?? const LocalFileSystem();

  final FileSystem _fs;

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

  bool exists(String path) => _fs.file(path).existsSync();

  /// Null means the file could not be read — missing, half-written, or not
  /// valid JSON. That is deliberately different from an empty file: [write] is
  /// a temporary file renamed over this one, and a watch event landing inside
  /// that window would otherwise report "no settings" and wipe them.
  Map<String, Object?>? read(String path) {
    try {
      final file = _fs.file(path);
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

  /// Writes through a temporary file, so a crash mid-write cannot leave a
  /// truncated config behind.
  ///
  /// Throws if it cannot: a setting that looks changed in the window but never
  /// reached the disk is only discovered on the next launch, so the caller has
  /// to be able to say so.
  Future<void> write(String path, Map<String, Object?> values) async {
    final directory = _fs.directory(p.dirname(path));
    if (!directory.existsSync()) await directory.create(recursive: true);

    final temporary = _fs.file('$path.tmp');
    await temporary.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(values)}\n',
    );
    await temporary.rename(path);
  }

  /// The paths that change in [directory], as they change. Creates the
  /// directory if it is not there yet, so the config file has somewhere to land.
  ///
  /// Null when this filesystem cannot watch, which an in-memory one never can.
  /// Watching is a convenience; the app is still usable without it.
  Stream<String>? watchDirectory(String directory) {
    try {
      final handle = _fs.directory(directory);
      if (!handle.existsSync()) handle.createSync(recursive: true);
      return handle.watch().map((event) => event.path);
    } catch (e) {
      debugPrint('Failed to watch $directory: $e');
      return null;
    }
  }
}
