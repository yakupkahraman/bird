import 'dart:io';

import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Language servers started by this test process alone. Counting every one on
/// the machine made the tests flaky: other test files run in parallel with
/// their own, and so does any editor the developer has open.
Future<int> serverCount() async {
  final result = await Process.run('ps', ['-Ao', 'ppid=,command=']);
  return result.stdout
      .toString()
      .split('\n')
      .map((line) => line.trim())
      .where(
        (line) =>
            line.startsWith('$pid ') && line.contains('dart language-server'),
      )
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
