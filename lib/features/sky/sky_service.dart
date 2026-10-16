import 'package:bird/features/settings/settings_store.dart';
import 'package:bird/features/sky/sky.dart';
import 'package:path/path.dart' as p;

/// Keeps each folder's Sky layout in Bird's own config directory.
///
/// Not in the project: where someone left their nodes is personal, and a
/// `.bird/` folder is only ever created when a user asks for one.
class SkyService {
  /// [store] and [directory] are only passed by tests.
  SkyService({SettingsStore? store, String? directory})
    : _store = store ?? SettingsStore(),
      _directory = directory ?? p.join(SettingsStore.defaultDirectory, 'sky');

  final SettingsStore _store;
  final String _directory;

  /// One file per folder, named after its path so it can be found by eye.
  String _file(String root) => p.join(
    _directory,
    '${root.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')}.json',
  );

  /// [root]'s layout, or an empty one when there is none or it will not read.
  SkyLayout load(String root) {
    final json = _store.read(_file(root));
    return json == null ? SkyLayout() : SkyLayout.fromJson(json);
  }

  Future<void> save(String root, SkyLayout layout) =>
      _store.write(_file(root), layout.toJson());
}
