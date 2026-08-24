/// The outcome of something that can fail in a way the user has to hear about.
///
/// Not for every error: a folder that will not list or a watch that cannot be
/// set up have documented fallbacks and stay `debugPrint`. This is for the ones
/// where the user asked for something, it did not happen, and nothing on screen
/// would otherwise say so.
///
/// Match on it; there are no `when`/`map` helpers because a switch reads better:
///
/// ```dart
/// switch (await editor.saveFile()) {
///   case Ok(): break;
///   case Failed(:final message): show(message);
/// }
/// ```
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Failed<T> extends Result<T> {
  const Failed(this.message);

  /// Ready to put in front of the user: what failed and, where it helps, why.
  final String message;
}
