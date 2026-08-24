import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_picker/file_picker.dart';

/// One entry of a directory, reduced to what the tree needs.
///
/// A `FileSystemEntity` would drag the filesystem into everything that holds a
/// listing; the tree only ever asks these two questions of one.
typedef DirectoryEntry = ({String path, bool isDirectory});

/// Reads folders off the disk for the file tree.
///
/// Holds no state: what is expanded and which listings are remembered is the
/// provider's business. [fileSystem] is only passed by tests, which must not
/// touch the real disk.
class WorkspaceService {
  WorkspaceService({FileSystem? fileSystem})
    : _fs = fileSystem ?? const LocalFileSystem();

  final FileSystem _fs;

  /// The entries of [directory], directories first and each group by name.
  ///
  /// Throws if the directory cannot be read — what an unreadable folder should
  /// look like on screen is not a decision for this layer.
  List<DirectoryEntry> list(String directory) {
    final entities = _fs.directory(directory).listSync();
    entities.sort((a, b) {
      final aIsDirectory = a is Directory;
      final bIsDirectory = b is Directory;
      if (aIsDirectory != bIsDirectory) return aIsDirectory ? -1 : 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
    return [
      for (final entity in entities)
        (path: entity.path, isDirectory: entity is Directory),
    ];
  }

  /// Asks the user for a folder, or null if they cancelled.
  Future<String?> promptForFolder() => FilePicker.platform.getDirectoryPath();
}
