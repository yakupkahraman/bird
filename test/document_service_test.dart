import 'package:bird/features/editor/document_service.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryFileSystem fs;
  late DocumentService service;

  setUp(() {
    fs = MemoryFileSystem();
    fs.directory('/w').createSync();
    service = DocumentService(fileSystem: fs);
  });

  test('what is written comes back', () async {
    await service.write('/w/main.dart', 'void main() {}');

    expect(await service.read('/w/main.dart'), 'void main() {}');
    expect(service.exists('/w/main.dart'), isTrue);
  });

  test('a write replaces what was there', () async {
    await service.write('/w/main.dart', 'first');
    await service.write('/w/main.dart', 'second');

    expect(await service.read('/w/main.dart'), 'second');
  });

  test('a file that was never written does not exist', () {
    expect(service.exists('/w/missing.dart'), isFalse);
  });

  test('watching answers null when the filesystem cannot do it', () {
    // An in-memory filesystem never can. The editor treats that as "no
    // watching" rather than an error, which is what keeps saving working.
    expect(service.watchPaths('/w'), isNull);
  });
}
