import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Where a Flutter SDK came from. Bird keeps one of each around so the user can
/// switch between them instead of being handed whichever one was found first.
enum FlutterSdkLocation {
  bundled(label: 'Bundled SDK'),
  custom(label: 'Custom SDK'),
  system(label: 'System SDK');

  final String label;

  const FlutterSdkLocation({required this.label});
}

/// The step a long-running SDK operation is on, so the UI can narrate it.
enum SdkInstallPhase {
  idle(''),
  resolving('Resolving release'),
  downloading('Downloading'),
  extracting('Extracting'),
  precaching('Pre-caching artifacts'),
  running('Running'),
  done('Done'),
  failed('Failed');

  final String label;

  const SdkInstallPhase(this.label);
}

/// Encapsulates metadata about a detected or active Flutter SDK.
class FlutterSdkInfo {
  final String flutterVersion;
  final String dartVersion;
  final String channel;
  final String sdkPath;
  final String dartSdkPath;
  final FlutterSdkLocation location;
  final String? frameworkRevision;

  const FlutterSdkInfo({
    required this.flutterVersion,
    required this.dartVersion,
    required this.channel,
    required this.sdkPath,
    required this.dartSdkPath,
    required this.location,
    this.frameworkRevision,
  });

  bool get isBundled => location == FlutterSdkLocation.bundled;
}

/// Orders `3.47.1` after `3.44.9`, and a release after its own pre-releases.
///
/// Flutter versions are `major.minor.patch` with an optional `-0.1.pre` tail,
/// which string ordering gets wrong in both halves.
int compareVersions(String a, String b) {
  final (aNumbers, aPre) = _splitVersion(a);
  final (bNumbers, bPre) = _splitVersion(b);
  for (var i = 0; i < 3; i++) {
    final difference =
        (aNumbers.elementAtOrNull(i) ?? 0) - (bNumbers.elementAtOrNull(i) ?? 0);
    if (difference != 0) return difference;
  }
  if (aPre == bPre) return 0;
  if (aPre.isEmpty) return 1; // a release outranks any pre-release of it
  if (bPre.isEmpty) return -1;
  return aPre.compareTo(bPre);
}

(List<int>, String) _splitVersion(String version) {
  final parts = version.split('-');
  final numbers = [
    for (final piece in parts.first.split('.')) int.tryParse(piece) ?? 0,
  ];
  return (numbers, parts.length > 1 ? parts.sublist(1).join('-') : '');
}

/// Picks the archive built for this OS *and* CPU out of a release manifest.
///
/// One release hash lists an x64 build and an arm64 build, so taking the
/// first match hands an Apple Silicon machine the Intel SDK — which installs
/// fine and only goes wrong later, under Rosetta.
({String downloadUrl, String archivePath, String version}) pickRelease(
  Map<String, dynamic> manifest,
  String channel, {
  required String arch,
  String? version,
}) {
  final baseUrl =
      manifest['base_url'] as String? ??
      'https://storage.googleapis.com/flutter_infra_release/releases';
  final releases = (manifest['releases'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();
  if (releases.isEmpty) throw Exception('Release manifest listed no builds.');

  final currentHash =
      (manifest['current_release'] as Map<String, dynamic>?)?[channel]
          as String?;
  bool fitsHost(Map<String, dynamic> r) =>
      (r['dart_sdk_arch'] as String? ?? 'x64') == arch;

  final release = version != null
      ? releases.firstWhereOrNull((r) => r['version'] == version && fitsHost(r))
      : releases.firstWhereOrNull(
              (r) => r['hash'] == currentHash && fitsHost(r),
            ) ??
            releases.firstWhereOrNull(
              (r) => r['channel'] == channel && fitsHost(r),
            ) ??
            releases.firstWhereOrNull((r) => r['hash'] == currentHash);
  if (release == null) {
    throw Exception(
      version != null
          ? 'No $version build for $arch in the manifest.'
          : 'No $channel build for $arch in the manifest.',
    );
  }

  final archivePath = release['archive'] as String;
  return (
    downloadUrl: '$baseUrl/$archivePath',
    archivePath: archivePath,
    version: release['version'] as String? ?? 'unknown',
  );
}

/// Every release this machine can run, newest first.
///
/// One version appears once: the manifest lists an x64 and an arm64 build of
/// each, and only one of them is installable here.
List<({String version, String channel})> listReleases(
  Map<String, dynamic> manifest, {
  required String arch,
}) {
  final seen = <String>{};
  final releases = <({String version, String channel})>[];
  for (final release
      in (manifest['releases'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()) {
    if ((release['dart_sdk_arch'] as String? ?? 'x64') != arch) continue;
    final version = release['version'] as String?;
    if (version == null || !seen.add(version)) continue;
    releases.add((
      version: version,
      channel: release['channel'] as String? ?? 'stable',
    ));
  }
  releases.sort((a, b) => compareVersions(b.version, a.version));
  return releases;
}

/// Parses JSON output from `flutter --version --json`.
FlutterSdkInfo? parseVersionJson(
  String jsonString, {
  required String sdkPath,
  required FlutterSdkLocation location,
  String? dartSdkPath,
}) {
  try {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final flutterVersion = decoded['flutterVersion'] as String? ?? 'unknown';
    final dartVersion = decoded['dartSdkVersion'] as String? ?? 'unknown';
    final channel = decoded['channel'] as String? ?? 'stable';
    final frameworkRevision = decoded['frameworkRevisionShort'] as String?;

    return FlutterSdkInfo(
      flutterVersion: flutterVersion,
      dartVersion: dartVersion,
      channel: channel,
      sdkPath: sdkPath,
      dartSdkPath: dartSdkPath ?? p.join(sdkPath, 'bin', 'dart'),
      location: location,
      frameworkRevision: frameworkRevision,
    );
  } catch (e) {
    debugPrint('Failed to parse flutter --version json: $e');
    return null;
  }
}

/// Parses plain-text output from `flutter --version`.
FlutterSdkInfo? parseVersionText(
  String text, {
  required String sdkPath,
  required FlutterSdkLocation location,
  String? dartSdkPath,
}) {
  try {
    // Flutter 3.44.0 • channel stable • https://github.com/flutter/flutter.git
    // Framework • revision ...
    // Engine • revision ...
    // Tools • Dart 3.12.0 • DevTools 2.45.0
    final lines = text.split('\n');
    String flutterVersion = 'unknown';
    String channel = 'stable';
    String dartVersion = 'unknown';

    final flutterMatch = RegExp(
      r'Flutter\s+([\d\.\w\-]+)\s+•\s+channel\s+([\w\-]+)',
    ).firstMatch(lines.first);
    if (flutterMatch != null) {
      flutterVersion = flutterMatch.group(1) ?? 'unknown';
      channel = flutterMatch.group(2) ?? 'stable';
    }

    for (final line in lines) {
      final dartMatch = RegExp(r'Dart\s+([\d\.\w\-]+)').firstMatch(line);
      if (dartMatch != null) {
        dartVersion = dartMatch.group(1) ?? 'unknown';
        break;
      }
    }

    return FlutterSdkInfo(
      flutterVersion: flutterVersion,
      dartVersion: dartVersion,
      channel: channel,
      sdkPath: sdkPath,
      dartSdkPath: dartSdkPath ?? p.join(sdkPath, 'bin', 'dart'),
      location: location,
    );
  } catch (e) {
    debugPrint('Failed to parse flutter --version text: $e');
    return null;
  }
}

/// Human sizes for the progress panel: 1.4 GB reads, 1503238553 does not.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

/// Named so every layer can reach it; an unnamed extension stays private to
/// the file it is declared in.
extension FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
