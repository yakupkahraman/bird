import 'package:flutter/widgets.dart';

/// One result in Hawk and what choosing it does.
class HawkItem {
  const HawkItem({
    required this.title,
    required this.run,
    this.detail,
    this.leading,
  });

  final String title;

  /// Dimmer text beside the title, such as the folder a file is in.
  final String? detail;

  final Widget? leading;

  /// Runs after Hawk has closed, with a context that outlives it, so a
  /// command may open a dialog of its own.
  final void Function(BuildContext context) run;
}

/// Something Hawk can search: files today, commands and more later.
///
/// A source only turns a query into items. Hawk owns the box, the
/// keyboard and the list, so a new kind of result is one new source and a
/// line in `HawkSources.all`, with no change to Hawk itself.
abstract class HawkSource {
  const HawkSource();

  /// Called as Hawk opens: the place to start refreshing anything
  /// slow, so it is ready or nearly so by the first keystroke.
  void onOpen(BuildContext context) {}

  /// Items for [query], best first.
  ///
  /// Runs during Hawk's build on every keystroke, so it must be quick.
  /// A provider watched here rebuilds Hawk when it changes, which is
  /// how results that arrive late still show up.
  List<HawkItem> search(BuildContext context, String query);
}
