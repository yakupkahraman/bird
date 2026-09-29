/// Opens a path as an editor tab, optionally at a position in it.
///
/// `EditorProvider.openFile` is what actually does it, but depending on that
/// class directly would drag `code_forge` into everything that wants to open a
/// file, and that plugin cannot be compiled for the web. Views take this
/// instead, so they stay buildable by anything able to put a tab on screen.
///
/// It is also the one way into a file at a place: search results today, and
/// go-to-definition or an agent's edits later, all arrive through it. [line]
/// and [column] are 1-based, as the user sees them, and [column] counts UTF-16
/// code units, like any Dart string index plus one. Whoever holds a 0-based
/// position, as LSP does, converts at their end.
///
/// A function rather than an interface on purpose: the implementation is a
/// `ChangeNotifier`, and `Provider` rejects a `Listenable` value because it
/// cannot rebuild dependents from it. A tear-off is neither.
typedef TabOpener =
    Future<void> Function(String path, {int? line, int? column});
