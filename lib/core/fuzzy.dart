/// How well [query] matches [text] as an in-order subsequence, ignoring case.
/// Higher is better; null when it does not match at all.
///
/// Runs of consecutive characters and characters that start a word (after
/// `/`, `_`, `-`, `.` or a space, or a lower-to-upper case change) score extra,
/// which is what lets `edp` find `editor_provider.dart` ahead of a path that
/// merely contains those letters.
int? fuzzyScore(String query, String text) {
  final q = query.toLowerCase();
  final t = text.toLowerCase();
  var score = 0;
  var matched = 0;
  var run = 0;
  for (var i = 0; i < t.length && matched < q.length; i++) {
    if (t[i] != q[matched]) {
      run = 0;
      continue;
    }
    run++;
    matched++;
    score += 1 + run * 3;
    if (i == 0 ||
        '/\\_-. '.contains(text[i - 1]) ||
        (text[i] != t[i] && text[i - 1] == t[i - 1])) {
      score += 8;
    }
  }
  return matched == q.length ? score : null;
}
