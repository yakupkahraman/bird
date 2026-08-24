/// One visible line of the explorer.
///
/// The tree is flattened into a list of these so the explorer can build only
/// the rows that are on screen. A recursive widget tree cannot do that: every
/// level has to exist for the one below it to be built at all.
class FileTreeRow {
  const FileTreeRow({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.depth,
    required this.isExpanded,
  });

  final String path;
  final String name;
  final bool isDirectory;

  /// How far to indent; the root's own children are at zero.
  final int depth;

  /// Always false for a file.
  final bool isExpanded;
}
