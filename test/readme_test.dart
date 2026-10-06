import 'dart:convert';

import 'package:bird/features/pub/readme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an HTML header becomes the markdown it means', () {
    final markdown = prepareReadme('''
<h1 align="center">CodeForge</h1>

<p align="center">
  <strong>A powerful editor</strong> with <a href="https://x.dev">links</a>
</p>

<p align="center">
  <a href="https://pub.dev/packages/code_forge">
    <img src="https://img.shields.io/pub/v/code_forge.svg" alt="Pub"/>
  </a>
  <img src="demo.gif" width="800"/><br><sub>A caption</sub>
</p>
''');

    expect(markdown, contains('# CodeForge'));
    expect(
      markdown,
      contains('**A powerful editor** with [links](https://x.dev)'),
    );
    expect(
      markdown,
      contains(
        '[![Pub](https://img.shields.io/pub/v/code_forge.svg)]'
        '(https://pub.dev/packages/code_forge)',
      ),
    );
    expect(markdown, contains('![](demo.gif#800)'));
    expect(markdown, contains('A caption'));
    expect(markdown, isNot(contains('<')));
  });

  test('details keep their content, with the summary as a bold line', () {
    final markdown = prepareReadme('''
<details>
<summary>Advanced usage</summary>

Plain **markdown** inside.

</details>
''');

    expect(markdown, contains('**Advanced usage**'));
    expect(markdown, contains('Plain **markdown** inside.'));
    expect(markdown, isNot(contains('details')));
  });

  test('code fences are left alone, HTML-looking lines and all', () {
    const code = '```dart\n<LspConfig>\nfinal x = 1;\n```';

    expect(prepareReadme(code), code);
  });

  test('a <br> inside a table cell does not show as a tag', () {
    expect(
      prepareReadme('| 180+ languages<br>Available |'),
      '| 180+ languages Available |',
    );
  });

  test('GitHub alerts become a bold label', () {
    expect(
      prepareReadme('> [!NOTE]\n> Mind this.'),
      '> **Note**\\\n> Mind this.',
    );
    expect(prepareReadme('> [!warning]'), '> **Warning**\\');
  });

  test('heading slugs match the ids GitHub gives headings', () {
    expect(headingSlug("What's new in 10.14.0:"), 'whats-new-in-10140');
    expect(headingSlug('Why CodeForge?'), 'why-codeforge');
    expect(headingSlug('Getting started'), 'getting-started');
  });

  test('relative paths resolve against the GitHub repository', () {
    expect(
      githubUrl(
        'gifs/1M.gif',
        'https://github.com/heckmon/code_forge',
        raw: true,
      ),
      Uri.parse(
        'https://raw.githubusercontent.com/heckmon/code_forge/HEAD/gifs/1M.gif',
      ),
    );
    // A package inside a monorepo.
    expect(
      githubUrl(
        './README.zh-CN.md',
        'https://github.com/dart-lang/http/tree/master/pkgs/http',
        raw: false,
      ),
      Uri.parse(
        'https://github.com/dart-lang/http/blob/master/pkgs/http/README.zh-CN.md',
      ),
    );
    expect(githubUrl('a.png', 'https://gitlab.com/o/r', raw: true), isNull);
  });

  test('badge text drops the scale it was drawn at, keeping its place', () {
    const svg =
        '<g font-size="110"><g transform="scale(.1)">'
        '<text x="165" y="140" fill-opacity=".3" textLength="210">pub</text>'
        '</g></g><g font-size="100">'
        '<text transform="scale(.1)" x="378.75" y="175">LICENSE</text></g>';

    expect(
      unscaleBadge(svg),
      '<g font-size="11.0"><g>'
      '<text x="16.5" y="14.0" fill-opacity=".3" textLength="21.0">pub</text>'
      '</g></g><g font-size="10.0">'
      '<text x="37.875" y="17.5">LICENSE</text></g>',
    );
  });

  test('an embedded SVG logo is unpacked where its image was', () {
    final logo = base64.encode(
      utf8.encode(
        '<svg fill="white" viewBox="0 0 24 24"><path d="M0 0h24v24z"/></svg>',
      ),
    );
    final svg = unscaleBadge(
      '<image x="9" y="7" width="12" height="12" '
      'href="data:image/svg+xml;base64,$logo"/>',
    );

    expect(
      svg,
      '<g fill="white" transform="translate(9 7) scale(0.5 0.5) '
      'translate(0 0)"><path d="M0 0h24v24z"/></g>',
    );
  });

  test('a page that is not an SVG becomes an empty one', () {
    const svg = '<svg xmlns="http://www.w3.org/2000/svg"><rect/></svg>';

    expect(svgOrBlank(svg), svg);
    expect(svgOrBlank('<!DOCTYPE html><html>404</html>'), startsWith('<svg'));
    expect(svgOrBlank(''), startsWith('<svg'));
  });
}
