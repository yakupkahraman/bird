import 'dart:io';

import 'package:bird/providers/lsp_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Other editors run language servers too, so the tests assert on the change
/// in this count rather than its absolute value.
Future<int> serverCount() async {
  final result = await Process.run('ps', ['-Ao', 'command=']);
  return result.stdout
      .toString()
      .split('\n')
      .where((line) => line.contains('dart language-server'))
      .length;
}

Future<void> settle() => Future<void>.delayed(const Duration(seconds: 2));

void main() {
  // Counting processes relies on `ps`.
  if (Platform.isWindows) return;

  final workspace = Directory.current.path;

  test('starts a server, and dispose kills the process', () async {
    final before = await serverCount();

    final provider = LspProvider();
    await provider.updateWorkspace(workspace);
    await settle();
    expect(provider.dartLspConfig, isNotNull);
    expect(await serverCount(), before + 1);

    provider.dispose();
    await settle();
    expect(await serverCount(), before);
  });

  test('switching workspace kills the old process', () async {
    final before = await serverCount();

    final provider = LspProvider();
    await provider.updateWorkspace(workspace);
    await settle();
    expect(await serverCount(), before + 1);

    await provider.updateWorkspace(Directory.systemTemp.path);
    await settle();
    expect(await serverCount(), before + 1);

    provider.dispose();
    await settle();
    expect(await serverCount(), before);
  });

  test('re-opening the same workspace reuses the server', () async {
    final provider = LspProvider();
    await provider.updateWorkspace(workspace);
    await settle();
    final config = provider.dartLspConfig;

    await provider.updateWorkspace(workspace);
    expect(identical(provider.dartLspConfig, config), isTrue);

    provider.dispose();
    await settle();
  });
}
