import 'package:bird/widgets/my_button.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('grows to fit its label instead of ellipsizing it', (
    tester,
  ) async {
    const label = 'Install Bundled Flutter SDK';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: MyButton(label: label, icon: NfIcons.play),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    expect(paragraph.didExceedMaxLines, isFalse);
    // Wide enough for the icon, the gap and the whole label.
    expect(
      tester.getSize(find.byType(MyButton)).width,
      greaterThan(paragraph.size.width + 24),
    );
  });

  testWidgets('hugs its label inside a full-width column', (tester) async {
    // The empty editor lays its button out like this; a centring Container with
    // no width of its own would happily eat the whole column.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyButton(label: 'Open Folder', icon: NfIcons.folderOpen),
              ],
            ),
          ),
        ),
      ),
    );

    // The point is that it does not fill the 800px column it sits in.
    expect(tester.getSize(find.byType(MyButton)).width, lessThan(400));
  });

  testWidgets('still ellipsizes when a caller pins a width', (tester) async {
    const label = 'Install Bundled Flutter SDK';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: MyButton(label: label, width: 90),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(MyButton)).width, 90);
    expect(
      tester.renderObject<RenderParagraph>(find.text(label)).didExceedMaxLines,
      isTrue,
    );
  });
}
