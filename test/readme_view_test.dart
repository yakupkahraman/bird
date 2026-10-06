import 'package:bird/features/pub/readme_view.dart';
import 'package:bird/features/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget page(String data, List<Uri> opened) => ChangeNotifierProvider(
  create: (_) => ThemeProvider(),
  child: MaterialApp(
    home: Scaffold(
      body: ListView(
        children: [
          ReadmeView(
            data: data,
            repository: 'https://github.com/o/r',
            onOpenLink: opened.add,
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('a #section link scrolls to its heading', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      page(
        '[Jump to usage](#usage-guide)\n\n'
        '${List.filled(80, 'Filler paragraph.\n\n').join()}'
        '## Usage guide\n\nThe end.',
        opened,
      ),
    );
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.pixels, 0);

    await tester.tap(find.text('Jump to usage'));
    await tester.pumpAndSettle();

    expect(scroll.position.pixels, greaterThan(0));
    expect(find.text('Usage guide'), findsOneWidget);
    expect(opened, isEmpty, reason: 'an anchor stays in the page');
  });

  testWidgets('a relative link opens on the repository', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(page('[Chinese](./README.zh-CN.md)', opened));

    await tester.tap(find.text('Chinese'));

    expect(opened, [
      Uri.parse('https://github.com/o/r/blob/HEAD/README.zh-CN.md'),
    ]);
  });

  testWidgets('HTML headers and alerts render as text, not tags', (
    tester,
  ) async {
    await tester.pumpWidget(
      page('<h1 align="center">CodeForge</h1>\n\n> [!NOTE]\n> Mind this.', []),
    );

    expect(find.text('CodeForge'), findsOneWidget);
    expect(find.textContaining('<h1'), findsNothing);
    expect(find.textContaining('[!NOTE]', findRichText: true), findsNothing);
  });

  testWidgets('an SVG link that answers with something else draws nothing', (
    tester,
  ) async {
    // Tests answer every request with an empty 400, which is no SVG — the
    // same as a github.com/…/blob/ link answering with an HTML page.
    await tester.pumpWidget(
      page(
        '![logo](https://example.com/logo.svg) '
        '![badge](https://img.shields.io/badge/a-b-green)',
        [],
      ),
    );
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
