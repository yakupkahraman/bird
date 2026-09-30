import 'dart:convert';
import 'dart:io' show Process;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_picker/file_picker.dart';

/// One entry of a directory, reduced to what the tree needs.
///
/// A `FileSystemEntity` would drag the filesystem into everything that holds a
/// listing; the tree only ever asks these questions of one.
typedef DirectoryEntry = ({String path, bool isDirectory, bool isIgnored});

/// Reads folders off the disk for the file tree.
///
/// Holds no state: what is expanded and which listings are remembered is the
/// provider's business. [fileSystem] is only passed by tests, which must not
/// touch the real disk.
class WorkspaceService {
  WorkspaceService({FileSystem? fileSystem})
    : _fs = fileSystem ?? const LocalFileSystem();

  final FileSystem _fs;

  /// Never listed: VS Code's default `files.exclude`, version control
  /// internals and OS litter nobody opens on purpose.
  static const hidden = {
    '.git',
    '.svn',
    '.hg',
    'CVS',
    '.DS_Store',
    'Thumbs.db',
  };

  /// The entries of [directory], directories first and each group by name.
  ///
  /// Throws if the directory cannot be read — what an unreadable folder should
  /// look like on screen is not a decision for this layer.
  ///
  /// Asynchronous so a slow disk or a huge folder never stalls a frame.
  Future<List<DirectoryEntry>> list(String directory) async {
    final entities = await _fs
        .directory(directory)
        .list()
        .where((entity) => !hidden.contains(entity.basename))
        .toList();
    entities.sort((a, b) {
      final aIsDirectory = a is Directory;
      final bIsDirectory = b is Directory;
      if (aIsDirectory != bIsDirectory) return aIsDirectory ? -1 : 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
    final ignored = await _ignored(directory, [
      for (final e in entities) e.path,
    ]);
    return [
      for (final entity in entities)
        (
          path: entity.path,
          isDirectory: entity is Directory,
          isIgnored: ignored.contains(entity.path),
        ),
    ];
  }

  /// Which of [paths] git ignores, asked once per folder.
  ///
  /// Git is the authority on `.gitignore`: nested ignore files, negations,
  /// folders and everything under them. No git, not a repository, or a
  /// filesystem git cannot see (the in-memory one tests use) means nothing is
  /// ignored, which only costs the dimming.
  Future<Set<String>> _ignored(String directory, List<String> paths) async {
    if (paths.isEmpty || _fs is! LocalFileSystem) return const {};
    try {
      // -z on both sides, because a path may contain a newline.
      final git = await Process.start('git', [
        'check-ignore',
        '-z',
        '--stdin',
      ], workingDirectory: directory);
      git.stdin.add(utf8.encode(paths.map((path) => '$path\x00').join()));
      await git.stdin.close();
      // Drained so a chatty stderr ("not a git repository") cannot block it.
      final (out, _) = await (
        git.stdout.transform(utf8.decoder).join(),
        git.stderr.drain<void>(),
      ).wait;
      await git.exitCode;
      return out.split('\x00').where((path) => path.isNotEmpty).toSet();
    } catch (_) {
      return const {};
    }
  }

  /// Asks the user for a folder, or null if they cancelled.
  Future<String?> promptForFolder() => FilePicker.platform.getDirectoryPath();
}
