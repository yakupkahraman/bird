import 'package:bird/core/fuzzy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches an in-order subsequence, ignoring case', () {
    expect(fuzzyScore('EDP', 'editor_provider.dart'), isNotNull);
    expect(fuzzyScore('xyz', 'editor_provider.dart'), isNull);
    expect(fuzzyScore('rote', 'editor.dart'), isNull);
    expect(fuzzyScore('', 'anything'), 0);
  });

  test('word starts beat letters buried mid-word', () {
    // Both contain e, d, p in order; only the first starts words with them.
    expect(
      fuzzyScore('edp', 'lib/editor_document_provider.dart')!,
      greaterThan(fuzzyScore('edp', 'lib/needs_deep.dart')!),
    );
  });

  test('camelCase humps count as word starts', () {
    expect(
      fuzzyScore('ep', 'EditorProvider')!,
      greaterThan(fuzzyScore('ep', 'Editorsampler')!),
    );
  });

  test('consecutive letters beat scattered ones', () {
    expect(
      fuzzyScore('shell', 'lib/app/shell.dart')!,
      greaterThan(fuzzyScore('shell', 'lib/settings/help_label.dart')!),
    );
  });
}
