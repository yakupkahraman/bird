import 'package:bird/features/hawk/hawk.dart';
import 'package:bird/features/search/file_source.dart';

/// Registry of everything Hawk searches.
///
/// Results are listed source by source, in this order. A new kind of result,
/// such as commands or symbols, is a [HawkSource] added here.
class HawkSources {
  const HawkSources._();

  static const all = <HawkSource>[FileSource()];
}
