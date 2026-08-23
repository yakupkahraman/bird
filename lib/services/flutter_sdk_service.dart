import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:bird/models/flutter_sdk.dart';
import 'package:path/path.dart' as p;

/// Thrown to unwind whatever the service was doing when it was cancelled.
class SdkCancelled implements Exception {
  const SdkCancelled();
}

/// The directory holding every Flutter version Bird installed, one per
/// subdirectory named after its version.
///
/// A name people can find, not path_provider's bundle identifier
/// (`Application Support/com.<author>.bird`): this is a directory users open
/// to see what Bird put on their disk, and to delete it by hand if they want.
String get bundledSdkRoot {
  if (Platform.isWindows) {
    final appData =
        Platform.environment['APPDATA'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    return p.join(appData, 'Bird', 'flutter-sdk');
  }
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? '';
    return p.join(
      home,
      'Library',
      'Application Support',
      'Bird',
      'flutter-sdk',
    );
  }
  final xdg = Platform.environment['XDG_DATA_HOME'];
  if (xdg != null && xdg.isNotEmpty) {
    return p.join(xdg, 'bird', 'flutter-sdk');
  }
  final home = Platform.environment['HOME'] ?? '';
  return p.join(home, '.local', 'share', 'bird', 'flutter-sdk');
}

/// Where a single bundled version lives. [root] is only passed by tests, which
/// must not write into the user's real SDK directory.
String bundledVersionPath(String version, [String? root]) =>
    p.join(root ?? bundledSdkRoot, version);

/// The versions installed under [bundledSdkRoot], newest first.
///
/// The directory name is the version: it is what the installer called it, and
/// reading a version file per candidate would cost a scan on every rebuild.
List<String> installedBundledVersions([String? rootPath]) {
  final root = Directory(rootPath ?? bundledSdkRoot);
  if (!root.existsSync()) return const [];
  final versions = [
    for (final entry in root.listSync().whereType<Directory>())
      if (File(getFlutterExecutable(entry.path)).existsSync())
        p.basename(entry.path),
  ];
  versions.sort((a, b) => compareVersions(b, a));
  return versions;
}

/// Resolves the flutter binary path for a given SDK directory.
String getFlutterExecutable(String sdkPath) {
  return Platform.isWindows
      ? p.join(sdkPath, 'bin', 'flutter.bat')
      : p.join(sdkPath, 'bin', 'flutter');
}

/// Resolves the bundled Dart binary path for a given SDK directory.
String getDartExecutable(String sdkPath) {
  final cacheDart = Platform.isWindows
      ? p.join(sdkPath, 'bin', 'cache', 'dart-sdk', 'bin', 'dart.exe')
      : p.join(sdkPath, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');
  if (File(cacheDart).existsSync()) return cacheDart;

  return Platform.isWindows
      ? p.join(sdkPath, 'bin', 'dart.bat')
      : p.join(sdkPath, 'bin', 'dart');
}

/// The manifest, and the archive names inside it, are per operating system.
String get hostOs => Platform.isMacOS
    ? 'macos'
    : Platform.isWindows
    ? 'windows'
    : 'linux';

/// The CPU the archive has to match; see [pickRelease].
String get hostArch =>
    Abi.current().toString().toLowerCase().contains('arm64') ? 'arm64' : 'x64';

/// Flutter publishes one release manifest per operating system.
String get releaseManifestUrl =>
    'https://storage.googleapis.com/flutter_infra_release/releases/'
    'releases_$hostOs.json';

/// Free bytes on the volume holding [path], or null when it cannot be read.
Future<int?> freeBytes(String path) async {
  // The directory may not exist yet; the nearest existing parent is on the
  // same volume, which is what the answer is really about.
  var probe = Directory(path);
  while (!probe.existsSync() && probe.parent.path != probe.path) {
    probe = probe.parent;
  }
  try {
    if (Platform.isWindows) {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '(Get-PSDrive -Name (Split-Path -Qualifier "${probe.path}").'
            'TrimEnd(":")).Free',
      ]);
      return int.tryParse(result.stdout.toString().trim());
    }
    final result = await Process.run('df', ['-Pk', probe.path]);
    if (result.exitCode != 0) return null;
    final lines = result.stdout.toString().trim().split('\n');
    if (lines.length < 2) return null;
    final columns = lines.last.split(RegExp(r'\s+'));
    // device, 1K-blocks, used, available, ...
    final available = int.tryParse(columns[3]);
    return available == null ? null : available * 1024;
  } catch (_) {
    return null;
  }
}

/// Everything about the Flutter SDK that leaves the process: reading the disk,
/// running `flutter` and `git`, and fetching releases from flutter.dev.
///
/// It holds no application state and notifies nobody. Progress is reported
/// through the callbacks the owner passes in, so the same pipeline can drive a
/// settings page, a test, or nothing at all.
class FlutterSdkService {
  /// [bundledRoot] is only passed by tests, so they never touch the real one.
  FlutterSdkService({
    String? bundledRoot,
    this.onPhase,
    this.onLog,
    this.onProgress,
  }) : bundledRoot = bundledRoot ?? bundledSdkRoot;

  /// The directory holding every version Bird installed.
  final String bundledRoot;

  /// Which step is running, and a line about it fit to show a person.
  final void Function(SdkInstallPhase phase, String message)? onPhase;

  /// A line of output from whatever is running.
  final void Function(String line)? onLog;

  /// Bytes so far, bytes expected, and the rate in bytes per second.
  final void Function(int received, int total, double bytesPerSecond)?
  onProgress;

  Process? _process;
  HttpClient? _client;
  bool _cancelled = false;
  List<({String version, String channel})>? _releases;

  /// Clears the cancel flag before a new operation.
  void begin() => _cancelled = false;

  /// Stops what is running now. The call in flight throws [SdkCancelled].
  void cancel() {
    _cancelled = true;
    _client?.close(force: true);
    _process?.kill();
  }

  void dispose() {
    _cancelled = true;
    _process?.kill();
    _client?.close(force: true);
  }

  /// The versions installed under [bundledRoot], newest first.
  List<String> installedVersions() => installedBundledVersions(bundledRoot);

  /// Where a given installed version lives.
  String versionPath(String version) =>
      bundledVersionPath(version, bundledRoot);

  void _log(String line) => onLog?.call(line);

  void _phase(SdkInstallPhase phase, String message) =>
      onPhase?.call(phase, message);

  /// Reads version and channel metadata for an SDK path.
  Future<FlutterSdkInfo?> inspect(
    String sdkPath,
    FlutterSdkLocation location,
  ) async {
    // Fast path: try reading version.json or version file if available.
    final versionJsonFile = File(
      p.join(sdkPath, 'bin', 'cache', 'flutter.version.json'),
    );
    if (versionJsonFile.existsSync()) {
      final info = parseVersionJson(
        versionJsonFile.readAsStringSync(),
        sdkPath: sdkPath,
        location: location,
      );
      if (info != null) return info;
    }

    // Fallback: run `flutter --version --json` or `flutter --version`
    final executable = getFlutterExecutable(sdkPath);
    try {
      final result = await Process.run(executable, const [
        '--version',
        '--json',
      ]);
      if (result.exitCode == 0) {
        return parseVersionJson(
          result.stdout.toString(),
          sdkPath: sdkPath,
          location: location,
        );
      }
    } catch (_) {}

    // Fallback to text parsing
    try {
      final result = await Process.run(executable, const ['--version']);
      if (result.exitCode == 0) {
        return parseVersionText(
          result.stdout.toString(),
          sdkPath: sdkPath,
          location: location,
        );
      }
    } catch (_) {}

    return null;
  }

  /// Searches for flutter on PATH, then in the places it is usually unpacked.
  ///
  /// A window-server launched app inherits a bare PATH, not the one from the
  /// user's shell, so `which flutter` alone reports "no SDK" on a machine that
  /// plainly has one. The login shell is asked as well.
  Future<String?> findSystemSdk() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null && File(getFlutterExecutable(root)).existsSync()) {
      return root;
    }

    final probes = <List<String>>[
      if (Platform.isWindows)
        ['where', 'flutter']
      else ...[
        ['which', 'flutter'],
        // `-lc` so the shell reads the profile that puts flutter on PATH.
        [
          Platform.environment['SHELL'] ?? '/bin/sh',
          '-lc',
          'command -v flutter',
        ],
      ],
    ];

    for (final probe in probes) {
      try {
        final result = await Process.run(probe.first, probe.sublist(1));
        if (result.exitCode != 0) continue;
        final firstLine = result.stdout
            .toString()
            .split(RegExp(r'[\r\n]+'))
            .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
        if (firstLine.isEmpty) continue;
        final file = File(firstLine.trim());
        if (!file.existsSync()) continue;
        // flutter binary is at <sdk>/bin/flutter -> sdk is parent of bin
        return p.dirname(p.dirname(file.resolveSymbolicLinksSync()));
      } catch (_) {}
    }

    final home = Platform.environment['HOME'] ?? '';
    for (final candidate in [
      if (home.isNotEmpty) ...[
        p.join(home, 'development', 'flutter'),
        p.join(home, 'flutter'),
        p.join(home, 'fvm', 'default'),
      ],
      '/opt/homebrew/Caskroom/flutter/latest/flutter',
      '/usr/local/flutter',
      '/opt/flutter',
    ]) {
      if (File(getFlutterExecutable(candidate)).existsSync()) return candidate;
    }
    return null;
  }

  /// Moves an SDK installed under the old single-directory layout into a
  /// directory named after its version, so it joins the versions beside it
  /// instead of blocking the folder they live in.
  Future<void> adoptLegacyInstall() async {
    final root = Directory(bundledRoot);
    if (!File(getFlutterExecutable(root.path)).existsSync()) return;
    final info = await inspect(root.path, FlutterSdkLocation.bundled);
    if (info == null) return;

    final staging = Directory('${root.path}.moving');
    if (staging.existsSync()) await staging.delete(recursive: true);
    await root.rename(staging.path);
    await Directory(bundledRoot).create(recursive: true);
    await staging.rename(versionPath(info.flutterVersion));
  }

  /// Unpacks into the parent directory, where every archive holds a `flutter/`
  /// folder, then renames it to the name Bird looks for.
  Future<void> _extract(
    String archiveFile,
    String archivePath,
    Directory bundledDir,
  ) async {
    final parentDir = bundledDir.parent.path;
    final staged = Directory(p.join(parentDir, 'flutter'));
    if (staged.existsSync()) {
      _log('Removing a half-finished extraction from an earlier attempt...');
      await staged.delete(recursive: true);
    }

    // An entry per file, counted rather than logged: the archive holds tens of
    // thousands of them, and a silent `-q` run looks like the app has hung.
    var files = 0;
    void count(String line) {
      if (!line.contains(': flutter/')) return;
      files++;
      if (files % 500 == 0) {
        _phase(SdkInstallPhase.extracting, 'Extracting $files files...');
      }
    }

    // -o so a leftover file turns into an overwrite rather than a prompt that
    // waits on stdin forever.
    final zip = archivePath.endsWith('.zip');
    await _runLogged(
      zip && !Platform.isWindows ? 'unzip' : 'tar',
      zip && !Platform.isWindows
          ? ['-o', archiveFile, '-d', parentDir]
          : ['-xf', archiveFile, '-C', parentDir],
      onLine: count,
      logOutput: false,
    );

    if (!staged.existsSync()) {
      throw Exception('Archive did not contain a flutter/ directory.');
    }
    _log('Extracted $files files');
    await staged.rename(bundledDir.path);
    _log('Installed into ${bundledDir.path}');
  }

  /// Runs a child process, streaming its output into the install log so the
  /// user sees what a multi-minute step is actually doing.
  /// [onLine] also receives the output, for callers that keep it around.
  /// [allowFailure] is for commands whose non-zero exit is a result rather than
  /// an error — `flutter doctor` reports problems that way.
  Future<void> _runLogged(
    String executable,
    List<String> arguments, {
    void Function(String)? onLine,
    bool allowFailure = false,
    bool logOutput = true,
  }) async {
    _log('\$ $executable ${arguments.join(' ')}');
    final process = _process = await Process.start(
      executable,
      arguments,
      environment: {'PUB_ENVIRONMENT': 'bird'},
    );
    // Nothing here can answer a question, and a child that asks one would
    // otherwise wait on stdin until the user gives up on the whole install.
    await process.stdin.close();

    // The last lines are kept for the failure message: an exit code on its own
    // tells the user nothing, while the command itself just said what is wrong.
    final tail = <String>[];
    Future<void> drain(Stream<List<int>> stream) => stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          onLine?.call(line);
          if (logOutput) _log(line);
          if (line.trim().isEmpty) return;
          tail.add(line.trim());
          if (tail.length > 6) tail.removeAt(0);
        });

    final drained = [drain(process.stdout), drain(process.stderr)];
    final exitCode = await process.exitCode;
    await Future.wait(drained);
    _process = null;
    if (_cancelled) throw const SdkCancelled();
    if (exitCode != 0 && !allowFailure) {
      throw Exception(
        '${p.basename(executable)} ${arguments.first} failed (exit $exitCode)'
        '${tail.isEmpty ? '' : '\n${tail.join('\n')}'}',
      );
    }
  }

  /// Refuses an install that cannot fit, instead of filling the disk and dying
  /// halfway through the archive with whatever error the tools happen to give.
  Future<void> _requireRoomFor(
    int archiveBytes,
    String archiveDir,
    String targetDir,
  ) async {
    // The archive is written whole, then unpacked to about 1.4 times its size;
    // the rest is slack for the artifacts `precache` pulls afterwards.
    final needed = {
      archiveDir: archiveBytes,
      targetDir: (archiveBytes * 2.5).round(),
    };
    for (final MapEntry(key: dir, value: required) in needed.entries) {
      final free = await freeBytes(dir);
      if (free == null || free >= required) continue;
      throw Exception(
        'Not enough disk space: installing the Flutter SDK needs about '
        '${formatBytes(required)} free under $dir, and only '
        '${formatBytes(free)} is available.',
      );
    }
  }

  /// The tracked files edited inside [sdkPath], or null when it is clean or is
  /// not a git checkout at all.
  ///
  /// Flutter moves between channels with `git checkout`, which refuses to
  /// overwrite local edits — and an SDK picks up a modified `pubspec.lock` just
  /// from being used, so this is the common case rather than a rare one.
  Future<String?> _localChanges(String sdkPath) async {
    try {
      final result = await Process.run('git', [
        '-C',
        sdkPath,
        'status',
        '--porcelain',
        '--untracked-files=no',
      ]);
      if (result.exitCode != 0) return null;
      final files = result.stdout
          .toString()
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map(
            (line) => line.length > 3 ? line.substring(3).trim() : line.trim(),
          )
          .toList();
      return files.isEmpty ? null : files.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Refuses early, naming the fix, rather than through git's own wording.
  Future<void> _requireCleanCheckout(FlutterSdkInfo info, String action) async {
    final changed = await _localChanges(info.sdkPath);
    if (changed == null) return;
    throw Exception(
      'The Flutter SDK at ${info.sdkPath} has local changes ($changed), so it '
      'cannot $action. Revert them first:\n'
      'git -C ${info.sdkPath} checkout -- $changed',
    );
  }

  /// Every version installable on this machine, newest first.
  ///
  /// Fetched once and kept: the manifest is a megabyte and the list does not
  /// change while the settings page is open.
  Future<List<({String version, String channel})>> fetchReleases() async {
    if (_releases != null) return _releases!;
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(
        Uri.parse(releaseManifestUrl),
      )).close();
      if (response.statusCode != 200) {
        throw Exception('Release manifest: HTTP ${response.statusCode}');
      }
      final manifest =
          jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      return _releases = listReleases(manifest, arch: hostArch);
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads and unpacks [version], or the tip of [channel] when no version
  /// is named, into its own directory. Returns the version it installed.
  ///
  /// Versions live side by side, so this never disturbs the ones already there.
  Future<String> install({String channel = 'stable', String? version}) async {
    File? archive;
    try {
      final client = _client = HttpClient();
      _phase(SdkInstallPhase.resolving, 'Fetching release information...');
      final release = await _resolveRelease(client, channel, version);
      _log('Release: Flutter ${release.version} ($channel, $hostOs $hostArch)');
      _log('Source: ${release.downloadUrl}');

      final target = Directory(versionPath(release.version));
      target.parent.createSync(recursive: true);

      _phase(SdkInstallPhase.downloading, 'Starting download...');
      final response = await (await client.getUrl(
        Uri.parse(release.downloadUrl),
      )).close();
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download Flutter archive: HTTP ${response.statusCode}',
        );
      }

      final total = response.contentLength;
      await _requireRoomFor(
        total,
        Directory.systemTemp.path,
        target.parent.path,
      );
      archive = File(
        p.join(
          Directory.systemTemp.path,
          'bird_flutter_${DateTime.now().millisecondsSinceEpoch}'
          '_${p.basename(release.archivePath)}',
        ),
      );
      _log('Writing archive to ${archive.path}');

      final sink = archive.openWrite();
      final clock = Stopwatch()..start();
      var received = 0;
      try {
        await for (final chunk in response) {
          if (_cancelled) throw const SdkCancelled();
          sink.add(chunk);
          received += chunk.length;
          final seconds = clock.elapsedMilliseconds / 1000;
          onProgress?.call(
            received,
            total,
            seconds > 0 ? received / seconds : 0,
          );
        }
      } finally {
        await sink.close();
      }
      _log('Downloaded ${formatBytes(received)}');

      _phase(SdkInstallPhase.extracting, 'Extracting archive...');
      if (target.existsSync()) await target.delete(recursive: true);
      await _extract(archive.path, release.archivePath, target);

      final flutterBin = getFlutterExecutable(target.path);
      if (!File(flutterBin).existsSync() ||
          !File(
            p.join(target.path, 'packages', 'flutter', 'pubspec.yaml'),
          ).existsSync()) {
        throw Exception(
          'The archive only unpacked in part — ${target.path} is missing '
          'files the SDK needs. Install again to start over.',
        );
      }
      if (!Platform.isWindows) await Process.run('chmod', ['+x', flutterBin]);

      if (archive.existsSync()) {
        await archive.delete();
        _log('Removed the downloaded archive, freeing ${formatBytes(total)}');
      }

      _phase(
        SdkInstallPhase.precaching,
        'Downloading engine artifacts (this takes a while)...',
      );
      await _runLogged(flutterBin, const ['precache']);
      return release.version;
    } finally {
      if (archive?.existsSync() ?? false) {
        try {
          archive!.deleteSync();
        } catch (_) {}
      }
      _client?.close(force: true);
      _client = null;
    }
  }

  /// Fetches the release manifest for this OS and picks a build from it.
  Future<({String downloadUrl, String archivePath, String version})>
  _resolveRelease(HttpClient client, String channel, String? version) async {
    final response = await (await client.getUrl(
      Uri.parse(releaseManifestUrl),
    )).close();
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch release manifest: HTTP ${response.statusCode}',
      );
    }

    final manifest =
        jsonDecode(await response.transform(utf8.decoder).join())
            as Map<String, dynamic>;
    return pickRelease(manifest, channel, arch: hostArch, version: version);
  }

  /// Moves [info] onto [channel] and brings it up to that channel's tip.
  Future<void> switchChannel(FlutterSdkInfo info, String channel) async {
    await _requireCleanCheckout(info, 'switch channels');
    await _runLogged(getFlutterExecutable(info.sdkPath), ['channel', channel]);
    _phase(SdkInstallPhase.running, 'Upgrading to the $channel tip...');
    await _runLogged(getFlutterExecutable(info.sdkPath), const ['upgrade']);
  }

  /// Runs `flutter upgrade` on [info].
  Future<void> upgrade(FlutterSdkInfo info) async {
    await _requireCleanCheckout(info, 'be upgraded');
    await _runLogged(getFlutterExecutable(info.sdkPath), const ['upgrade']);
  }

  /// Runs `flutter doctor -v` on [info] and returns everything it printed.
  Future<String> doctor(FlutterSdkInfo info) async {
    final output = StringBuffer();
    // Doctor exits non-zero when it has something to report, which is the
    // normal case here, not a failure to run it.
    await _runLogged(
      getFlutterExecutable(info.sdkPath),
      const ['doctor', '-v'],
      onLine: output.writeln,
      allowFailure: true,
    );
    return output.toString();
  }

  /// Deletes one installed version, leaving the others alone.
  Future<void> deleteVersion(String version) async {
    final directory = Directory(versionPath(version));
    if (directory.existsSync()) await directory.delete(recursive: true);
  }
}
