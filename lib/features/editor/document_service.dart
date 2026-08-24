import 'dart:io' show FileSystemMoveEvent;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_picker/file_picker.dart';

/// Reads and writes the files behind the open buffers, and reports when one
/// changes underneath them.
///
/// Holds no state and notifies nobody: it hands back futures and a stream, and
/// its owner decides what any of it means. [fileSystem] is only passed by
/// tests, which must not touch the real disk.
class DocumentService {
  DocumentService({FileSystem? fileSystem})
    : _fs = fileSystem ?? const LocalFileSystem();

  final FileSystem _fs;

  Future<String> read(String path) => _fs.file(path).readAsString();

  Future<void> write(String path, String text) =>
      _fs.file(path).writeAsString(text);

  bool exists(String path) => _fs.file(path).existsSync();

  /// The paths that change under [directory], as they change.
  ///
  /// Watches are per directory, not per file: an editor that saves by writing a
  /// temporary file and renaming it over the original — Bird's own settings do
  /// exactly that — replaces the inode, and a watch on the file dies with it.
  ///
  /// Null when this filesystem cannot watch, which an in-memory one never can.
  /// Watching is a convenience; editing still works without it.
  Stream<String>? watchPaths(String directory) {
    try {
      return _fs
          .directory(directory)
          .watch()
          .expand(
            // A rename reports the old path; the new one arrives as the
            // destination, so one event can name two files.
            (event) => [
              event.path,
              if (event is FileSystemMoveEvent && event.destination != null)
                event.destination!,
            ],
          );
    } catch (e) {
      return null;
    }
  }

  /// Asks the user where to put a file that has never been saved, or null if
  /// they cancelled.
  Future<String?> promptForSavePath() => FilePicker.platform.saveFile(
    dialogTitle: 'Save New File',
    fileName: 'new_chick.txt',
    allowedExtensions: ['txt'],
    type: FileType.custom,
  );
}
