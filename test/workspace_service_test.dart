import 'dart:io' as io;

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

  test('directories come before files', () async {
    fs.directory('/w').createSync();
    fs.file('/w/a.dart').writeAsStringSync('');
    fs.directory('/w/z_folder').createSync();

    expect((await service.list('/w')).map((entry) => entry.path), [
      '/w/z_folder',
      '/w/a.dart',
    ]);
  });

  test('each group is sorted regardless of case', () async {
    fs.directory('/w').createSync();
    for (final name in ['Beta.dart', 'alpha.dart', 'Gamma.dart']) {
      fs.file('/w/$name').writeAsStringSync('');
    }

    expect((await service.list('/w')).map((entry) => entry.path), [
      '/w/alpha.dart',
      '/w/Beta.dart',
      '/w/Gamma.dart',
    ]);
  });

  test('an entry says whether it is a folder', () async {
    fs.directory('/w/sub').createSync(recursive: true);
    fs.file('/w/one.dart').writeAsStringSync('');

    final entries = {
      for (final entry in await service.list('/w'))
        entry.path: entry.isDirectory,
    };

    expect(entries, {'/w/sub': true, '/w/one.dart': false});
  });

  test('version control internals and OS litter are not listed', () async {
    fs.directory('/w/.git').createSync(recursive: true);
    fs.file('/w/.DS_Store').writeAsStringSync('');
    fs.file('/w/.gitignore').writeAsStringSync('');

    expect((await service.list('/w')).map((entry) => entry.path), [
      '/w/.gitignore',
    ]);
  });

  test('a directory that is not there throws', () async {
    // The provider turns this into an empty listing; deciding that is not
    // this layer's job.
    await expectLater(service.list('/nowhere'), throwsA(isA<Object>()));
  });

  group('ignored entries, from a real git repository', () {
    late io.Directory repo;

    setUp(() {
      repo = io.Directory.systemTemp.createTempSync('bird_ignore');
      io.Process.runSync('git', ['init', '-q'], workingDirectory: repo.path);
      io.File('${repo.path}/.gitignore').writeAsStringSync('build/\n*.log\n');
      io.Directory('${repo.path}/build/app').createSync(recursive: true);
      io.Directory('${repo.path}/lib').createSync();
      io.File('${repo.path}/debug.log').writeAsStringSync('');
      io.File('${repo.path}/main.dart').writeAsStringSync('');
    });

    tearDown(() => repo.deleteSync(recursive: true));

    Future<Map<String, bool>> ignored(String directory) async => {
      for (final entry in await WorkspaceService().list(directory))
        entry.path.split('/').last: entry.isIgnored,
    };

    test('folders and files matched by .gitignore are flagged', () async {
      expect(await ignored(repo.path), {
        'build': true,
        'lib': false,
        '.gitignore': false,
        'debug.log': true,
        'main.dart': false,
      });
    });

    test('everything inside an ignored folder is ignored too', () async {
      expect(await ignored('${repo.path}/build'), {'app': true});
    });

    test('outside a repository nothing is ignored', () async {
      io.Directory('${repo.path}/.git').deleteSync(recursive: true);

      expect((await ignored(repo.path)).values, everyElement(isFalse));
    });
  });
}
