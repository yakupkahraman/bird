import 'package:bird/features/workspace/workspace_service.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryFileSystem fs;
  late WorkspaceService service;

  setUp(() {
    fs = MemoryFileSystem();
    service = WorkspaceService(fileSystem: fs);
  });

  test('directories come before files', () {
    fs.directory('/w').createSync();
    fs.file('/w/a.dart').writeAsStringSync('');
    fs.directory('/w/z_folder').createSync();

    expect(service.list('/w').map((entry) => entry.path), [
      '/w/z_folder',
      '/w/a.dart',
    ]);
  });

  test('each group is sorted regardless of case', () {
    fs.directory('/w').createSync();
    for (final name in ['Beta.dart', 'alpha.dart', 'Gamma.dart']) {
      fs.file('/w/$name').writeAsStringSync('');
    }

    expect(service.list('/w').map((entry) => entry.path), [
      '/w/alpha.dart',
      '/w/Beta.dart',
      '/w/Gamma.dart',
    ]);
  });

  test('an entry says whether it is a folder', () {
    fs.directory('/w/sub').createSync(recursive: true);
    fs.file('/w/one.dart').writeAsStringSync('');

    final entries = {
      for (final entry in service.list('/w')) entry.path: entry.isDirectory,
    };

    expect(entries, {'/w/sub': true, '/w/one.dart': false});
  });

  test('a directory that is not there throws', () {
    // The provider turns this into an empty listing; deciding that is not
    // this layer's job.
    expect(() => service.list('/nowhere'), throwsA(isA<Object>()));
  });
}
