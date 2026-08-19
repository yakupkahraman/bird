import 'package:bird/providers/file_provider.dart';
import 'package:bird/providers/lsp_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an open internal tab survives a language server notification', () {
    final lsp = LspProvider();
    addTearDown(lsp.dispose);
    final files = FileProvider()..openCustomTab('bird://settings');
    addTearDown(files.dispose);
    files.attachLsp(lsp);

    // Internal tabs have no controller, and rebinding used to assume one.
    // Reproduces: open the Settings tab, then open a folder.
    expect(lsp.stopServer, returnsNormally);
  });
}
