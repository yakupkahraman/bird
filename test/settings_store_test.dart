import 'package:bird/features/settings/settings_store.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryFileSystem fs;
  late SettingsStore store;

  setUp(() {
    fs = MemoryFileSystem();
    store = SettingsStore(fileSystem: fs);
  });

  test('what is written comes back', () async {
    await store.write('/config/bird/settings.json', {'editor.fontSize': 15});

    expect(store.read('/config/bird/settings.json'), {'editor.fontSize': 15});
  });

  test('writing creates the directory it needs', () async {
    await store.write('/nothing/here/yet/settings.json', {});

    expect(store.exists('/nothing/here/yet/settings.json'), isTrue);
  });

  test('no temporary file is left behind', () async {
    await store.write('/config/settings.json', {'a': 1});

    // The write is a temp file renamed over the target; a leftover .tmp would
    // mean the rename never happened.
    expect(store.exists('/config/settings.json.tmp'), isFalse);
  });

  test('a missing file reads as null, not as empty settings', () {
    // The difference matters: null means "could not read", and the caller
    // keeps what it already had rather than wiping it.
    expect(store.read('/config/settings.json'), isNull);
  });

  test('a half-written file reads as null', () {
    fs.directory('/config').createSync();
    fs.file('/config/settings.json').writeAsStringSync('{"editor.fontSi');

    expect(store.read('/config/settings.json'), isNull);
  });

  test('valid JSON that is not an object reads as empty', () {
    fs.directory('/config').createSync();
    fs.file('/config/settings.json').writeAsStringSync('[1, 2, 3]');

    expect(store.read('/config/settings.json'), isEmpty);
  });

  test(
    'the file is written as indented JSON with a trailing newline',
    () async {
      await store.write('/config/settings.json', {'a': 1});

      expect(
        fs.file('/config/settings.json').readAsStringSync(),
        '{\n  "a": 1\n}\n',
      );
    },
  );
}
