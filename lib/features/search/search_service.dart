import 'package:dart_ripgrep/dart_ripgrep.dart';

/// Searches file contents with the ripgrep bundled by `dart_ripgrep`.
class SearchService {
  // Located on first use: a missing binary is a failed search, not a failed
  // launch.
  late final Ripgrep _rg = Ripgrep();

  /// Every file under [root] that ripgrep would search, `.gitignore` applied.
  Stream<String> files(String root) async* {
    yield* _rg.files(root);
  }

  /// Lines under [root] containing [query] literally, capped at [limit].
  ///
  /// Cancelling the subscription kills the ripgrep process.
  Stream<RgMatch> search(String query, String root, {int limit = 2000}) async* {
    // Inside the generator, so a missing binary arrives as a stream error.
    yield* _rg
        .search(
          query,
          root,
          options: const RgOptions(caseMode: RgCase.smart, fixedString: true),
        )
        .where((line) => line is RgMatch)
        .cast<RgMatch>()
        .take(limit);
  }
}
