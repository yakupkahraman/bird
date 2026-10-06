import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

/// Rewrites what a README needs from GitHub-flavoured rendering into markdown
/// the renderer understands.
///
/// READMEs lean on HTML for their headers — centred titles, badge rows, demo
/// GIFs — and the renderer drops HTML outright, so a block of it is turned into
/// the markdown it means. GitHub alerts (`> [!NOTE]`) become a bold label.
/// Fenced code is left exactly as written.
String prepareReadme(String markdown) {
  final out = <String>[];
  final block = <String>[];
  var fence = '';

  void flush() {
    if (block.isEmpty) return;
    out
      ..add(htmlToMarkdown(block.join('\n')))
      ..add('');
    block.clear();
  }

  for (final line in markdown.split('\n')) {
    final trimmed = line.trimLeft();
    if (fence.isNotEmpty) {
      if (trimmed.startsWith(fence)) fence = '';
      out.add(line);
    } else if (block.isNotEmpty) {
      // An HTML block runs to the next blank line, as in CommonMark.
      line.trim().isEmpty ? flush() : block.add(line);
    } else if (_fenceStart.firstMatch(trimmed) case final match?) {
      fence = match[0]!;
      out.add(line);
    } else if (_htmlStart.hasMatch(trimmed)) {
      block.add(line);
    } else {
      out.add(
        line
            // A <br> mid-line, often in a table cell, which a newline would
            // split in two.
            .replaceAll(_br, ' ')
            .replaceFirstMapped(
              _alert,
              // The trailing backslash breaks the line, so the label stands
              // alone above the alert's text, as on GitHub.
              (m) =>
                  '${m[1]}**${m[2]![0].toUpperCase()}${m[2]!.substring(1).toLowerCase()}**\\',
            ),
      );
    }
  }
  flush();
  return out.join('\n');
}

final _fenceStart = RegExp(r'^(```+|~~~+)');
final _br = RegExp(r'<br\s*/?>', caseSensitive: false);
final _htmlStart = RegExp(r'^<(/?[a-zA-Z]|!--)');
final _alert = RegExp(
  r'^(\s*>\s*)\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]',
  caseSensitive: false,
);

/// The markdown an HTML fragment means, as far as markdown can say it.
/// Alignment is lost; an image keeps its width as a `#<width>` fragment, which
/// the image builder reads back.
String htmlToMarkdown(String fragment) => _markdown(
  html.parseFragment(fragment),
).replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

String _markdown(dom.Node node) {
  if (node is dom.Text) return node.text.replaceAll(RegExp(r'\s+'), ' ');
  final inner = node.nodes.map(_markdown).join();
  if (node is! dom.Element) return inner;
  final text = inner.trim();
  final tag = node.localName!;

  if (RegExp(r'^h[1-6]$').hasMatch(tag)) {
    return '\n\n${'#' * int.parse(tag[1])} $text\n\n';
  }
  return switch (tag) {
    'p' ||
    'div' ||
    'center' ||
    'section' ||
    'picture' ||
    'details' => '\n\n$text\n\n',
    'summary' => '\n\n**$text**\n\n',
    'br' => '\\\n',
    'hr' => '\n\n---\n\n',
    'strong' || 'b' => text.isEmpty ? '' : '**$text**',
    'em' || 'i' => text.isEmpty ? '' : '*$text*',
    'code' => '`${node.text}`',
    'pre' => '\n\n```\n${node.text.trimRight()}\n```\n\n',
    'a' when text.isNotEmpty => '[$text](${node.attributes['href'] ?? ''})',
    'img' => _image(node),
    'ul' || 'ol' => '\n\n${_items(node, ordered: tag == 'ol')}\n\n',
    'source' || 'script' || 'style' => '',
    _ => inner,
  };
}

String _image(dom.Element img) {
  final src = img.attributes['src'];
  if (src == null || src.isEmpty) return '';
  final width = int.tryParse(img.attributes['width'] ?? '');
  return '![${img.attributes['alt'] ?? ''}]($src${width == null ? '' : '#$width'})';
}

String _items(dom.Element list, {required bool ordered}) => [
  for (final (i, item)
      in list.children.where((c) => c.localName == 'li').indexed)
    '${ordered ? '${i + 1}.' : '-'} ${_markdown(item).trim()}',
].join('\n');

/// GitHub's id for a heading, which is what a README's `#section` links use.
String headingSlug(String text) => text
    .toLowerCase()
    .trim()
    .replaceAll(RegExp(r'[^\p{L}\p{N}\s_-]', unicode: true), '')
    .replaceAll(RegExp(r'\s'), '-');

/// Where a README's relative [path] lives on GitHub: the raw file for an
/// image, the page for a link. Null for a repository elsewhere, since there
/// is no telling where another host serves files from.
Uri? githubUrl(String path, String? repository, {required bool raw}) {
  final repo = Uri.tryParse(repository ?? '');
  if (repo == null || repo.host != 'github.com') return null;
  final segments = repo.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length < 2) return null;
  final owner = segments[0];
  final name = segments[1].replaceFirst(RegExp(r'\.git$'), '');
  // A package in a monorepo points at github.com/o/r/tree/<ref>/<folder>.
  final (ref, folder) = segments.length >= 4 && segments[2] == 'tree'
      ? (segments[3], segments.skip(4).join('/'))
      : ('HEAD', '');
  final file = p.posix.normalize(p.posix.join(folder, path));
  return raw
      ? Uri.https('raw.githubusercontent.com', '/$owner/$name/$ref/$file')
      : Uri.https('github.com', '/$owner/$name/blob/$ref/$file');
}

/// A shields.io badge that flutter_svg draws correctly.
///
/// shields.io sets badge text ten times too large and shrinks it with
/// `scale(.1)`, a transform flutter_svg does not apply to text, so the letters
/// came out huge. Dividing the sizes and positions by ten and dropping the
/// transform draws the same badge, still as a sharp vector.
///
/// Its logo is a second SVG embedded as an `<image>`, which flutter_svg only
/// draws for raster formats; it is unpacked into a group in its place.
String unscaleBadge(String svg) => svg
    .replaceAllMapped(
      RegExp(
        r'<image\b([^>]*?)href="data:image/svg\+xml;base64,([^"]+)"([^>]*)>',
      ),
      (m) => _inlineLogo('${m[1]}${m[3]}', utf8.decode(base64.decode(m[2]!))),
    )
    .replaceAll(RegExp(r'\s*transform="scale\(\.1\)"'), '')
    .replaceAllMapped(
      RegExp(r'<text\b[^>]*>'),
      (tag) => tag[0]!.replaceAllMapped(
        RegExp(r'\b(x|y|textLength)="([\d.]+)"'),
        (a) => '${a[1]}="${double.parse(a[2]!) / 10}"',
      ),
    )
    .replaceAllMapped(
      RegExp(r'font-size="([\d.]+)"'),
      (m) => 'font-size="${double.parse(m[1]!) / 10}"',
    );

/// [logo]'s drawing as a group placed where the `<image>` with [attributes]
/// put it, scaled from the logo's viewBox to the image's size.
String _inlineLogo(String attributes, String logo) {
  final open = RegExp(r'<svg\b([^>]*)>').firstMatch(logo);
  final end = logo.lastIndexOf('</svg>');
  if (open == null || end < open.end) return '';
  String? attribute(String source, String name) =>
      RegExp('\\b$name="([^"]*)"').firstMatch(source)?[1];
  num number(String name, num fallback) =>
      num.tryParse(attribute(attributes, name) ?? '') ?? fallback;

  final box = (attribute(open[1]!, 'viewBox') ?? '0 0 24 24')
      .trim()
      .split(RegExp(r'[\s,]+'))
      .map(num.parse)
      .toList();
  final fill = attribute(open[1]!, 'fill');
  final scaleX = number('width', box[2]) / box[2];
  final scaleY = number('height', box[3]) / box[3];
  return '<g${fill == null ? '' : ' fill="$fill"'} transform="'
      'translate(${number('x', 0)} ${number('y', 0)}) '
      'scale($scaleX $scaleY) translate(${-box[0]} ${-box[1]})">'
      '${logo.substring(open.end, end)}</g>';
}

/// [text] if it is an SVG document, or an empty one in its place.
String svgOrBlank(String text) => RegExp(r'<svg[\s>/]').hasMatch(text)
    ? text
    // A size is required: an SVG without one is rejected as well.
    : '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>';
