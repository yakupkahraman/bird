import 'dart:convert';
import 'dart:io';

import 'package:bird/features/pub/pub_package.dart';
import 'package:bird/features/sdk/flutter_sdk_service.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// Talks to pub.dev and runs `flutter pub` in the open project.
class PubService {
  /// Names of the packages pub.dev ranks first for [query].
  Future<List<String>> search(String query) async {
    final json = await _get(Uri.https('pub.dev', '/api/search', {'q': query}));
    return [
      for (final hit in (json['packages'] as List).cast<Map<String, dynamic>>())
        hit['package'] as String,
    ];
  }

  Future<PubPackage> package(String name) async {
    final (package, score) = await (
      _get(Uri.https('pub.dev', '/api/packages/$name')),
      _get(Uri.https('pub.dev', '/api/packages/$name/score')),
    ).wait;
    return PubPackage.fromJson(package, score);
  }

  /// One of [name]'s documents at [version], or null when it has none.
  ///
  /// pub.dev serves them only inside the package archive, which can run to
  /// megabytes of images and examples, so the archive is read as it streams
  /// and dropped as soon as the answer is known.
  Future<({String path, String text})?> document(
    String name,
    String version,
    PubDoc doc,
  ) async {
    final candidates = switch (doc) {
      PubDoc.readme => ['readme.md'],
      PubDoc.changelog => ['changelog.md'],
      // pub.dev's own order of preference.
      PubDoc.example => [
        for (final file in [
          'README.md',
          'example.md',
          'lib/main.dart',
          'bin/main.dart',
          'main.dart',
          for (final stem in [name, '${name}_example', 'example']) ...[
            'lib/$stem.dart',
            'bin/$stem.dart',
            '$stem.dart',
          ],
        ])
          'example/${file.toLowerCase()}',
      ],
    };
    final folder = p.posix.dirname(candidates.first);
    final found = <String, String>{};
    var inFolder = false;
    await _readArchive(name, version, (path, contents) {
      final key = path.toLowerCase().replaceFirst('./', '');
      if (candidates.contains(key)) {
        found[key] = utf8.decode(contents(), allowMalformed: true);
      }
      final here = folder == '.' || key.startsWith('$folder/');
      // Entries come sorted, so once past the folder nothing better follows.
      final passed = inFolder && !here;
      inFolder = here;
      return found.containsKey(candidates.first) || passed;
    });
    for (final path in candidates) {
      if (found[path] case final text?) return (path: path, text: text);
    }
    return null;
  }

  /// Streams [name]'s archive, handing [onEntry] each file until it says stop.
  Future<void> _readArchive(
    String name,
    String version,
    bool Function(String path, List<int> Function() contents) onEntry,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.https('pub.dev', '/api/archives/$name-$version.tar.gz');
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      // Tar is 512-byte blocks: a header (name at 0, octal size at 124), then
      // the contents padded to a whole block, then the next header.
      var tar = <int>[];
      await for (final chunk in response.transform(gzip.decoder)) {
        tar.addAll(chunk);
        while (tar.length >= 512) {
          final header = tar.sublist(0, 512);
          if (header.every((byte) => byte == 0)) return;
          final size = int.parse(_field(header, 124, 12).trim(), radix: 8);
          final end = 512 + (size + 511) ~/ 512 * 512;
          if (tar.length < end) break;
          final entry = tar;
          if (onEntry(
            _field(header, 0, 100),
            () => entry.sublist(512, 512 + size),
          )) {
            return;
          }
          tar = tar.sublist(end);
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  static String _field(List<int> header, int start, int length) {
    final bytes = header.sublist(start, start + length);
    final nul = bytes.indexOf(0);
    return utf8.decode(nul < 0 ? bytes : bytes.sublist(0, nul));
  }

  bool hasPubspec(String root) =>
      File(p.join(root, 'pubspec.yaml')).existsSync();

  /// The project's dependencies, with the newest version of each.
  Future<List<Dependency>> dependencies(String root, String sdkPath) async {
    final out = await _flutter(sdkPath, root, [
      'pub',
      'outdated',
      '--json',
      '--show-all',
    ]);
    return Dependency.parseOutdated(jsonDecode(out) as Map<String, dynamic>);
  }

  Future<void> add(
    String root,
    String sdkPath,
    String name, {
    bool dev = false,
  }) => _flutter(sdkPath, root, ['pub', 'add', dev ? 'dev:$name' : name]);

  Future<void> remove(String root, String sdkPath, String name) =>
      _flutter(sdkPath, root, ['pub', 'remove', name]);

  /// Moves [name] to its newest version, rewriting the constraint if it has to.
  Future<void> upgrade(String root, String sdkPath, String name) =>
      _flutter(sdkPath, root, ['pub', 'upgrade', '--major-versions', name]);

  Future<void> openInBrowser(Uri uri) => launchUrl(uri);

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  /// Runs flutter from [sdkPath] in [root]; throws with pub's own explanation,
  /// such as a version that does not resolve, when it fails.
  Future<String> _flutter(
    String sdkPath,
    String root,
    List<String> args,
  ) async {
    final result = await Process.run(
      getFlutterExecutable(sdkPath),
      args,
      workingDirectory: root,
      environment: {'PUB_ENVIRONMENT': 'bird'},
    );
    if (result.exitCode != 0) {
      throw ProcessException(
        'flutter',
        args,
        '${result.stderr}${result.stdout}'.trim(),
        result.exitCode,
      );
    }
    return '${result.stdout}';
  }
}
