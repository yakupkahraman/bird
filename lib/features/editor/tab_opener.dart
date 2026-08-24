/// Opens a path as an editor tab.
///
/// `FileProvider.openFile` is what actually does it, but depending on that
/// class directly would drag `code_forge` into everything that wants to open a
/// file, and that plugin cannot be compiled for the web. Views take this
/// instead, so they stay buildable by anything able to put a tab on screen.
///
/// A function rather than an interface on purpose: the implementation is a
/// `ChangeNotifier`, and `Provider` rejects a `Listenable` value because it
/// cannot rebuild dependents from it. A tear-off is neither.
typedef TabOpener = Future<void> Function(String path);
