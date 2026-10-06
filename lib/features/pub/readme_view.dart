import 'dart:typed_data';

import 'package:bird/features/editor/languages.dart';
import 'package:bird/features/pub/readme.dart';
import 'package:bird/features/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:re_highlight/re_highlight.dart';

/// A package document rendered the way pub.dev shows it: HTML headers, badges,
/// highlighted code, and `#section` links that scroll to their heading.
class ReadmeView extends StatelessWidget {
  const ReadmeView({
    super.key,
    required this.data,
    required this.repository,
    required this.onOpenLink,
  });

  final String data;

  /// The package's repository, which relative images and links resolve
  /// against.
  final String? repository;

  final void Function(Uri uri) onOpenLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editorTheme = context.watch<ThemeProvider>().editorTheme;
    // Rebuilt with the document: a key may sit on one heading only.
    final anchors = <String, GlobalKey>{};

    return MarkdownBody(
      data: prepareReadme(data),
      selectable: true,
      // Blocks take the full width, so code blocks line up with the text.
      fitContent: false,
      styleSheet: _style(theme),
      imageBuilder: (uri, title, alt) => _image(uri, repository),
      builders: {
        for (var level = 1; level <= 6; level++) 'h$level': _Heading(anchors),
        'pre': _CodeBlock(editorTheme),
      },
      onTapLink: (_, href, _) {
        if (href == null || href.isEmpty) return;
        if (href.startsWith('#')) {
          final target = anchors[headingSlug(href.substring(1))];
          if (target?.currentContext case final context?) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          return;
        }
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        final target = uri.hasScheme
            ? uri
            : githubUrl(href, repository, raw: false);
        if (target != null) onOpenLink(target);
      },
    );
  }
}

/// A heading with a key under its slug, which is what `#section` scrolls to.
class _Heading extends MarkdownElementBuilder {
  _Heading(this.anchors);

  final Map<String, GlobalKey> anchors;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final slug = headingSlug(element.textContent);
    // A repeated heading keeps no key: GitHub numbers repeats, links rarely
    // point at them, and one key on two widgets throws.
    final key = anchors.containsKey(slug)
        ? null
        : (anchors[slug] = GlobalKey());
    return Text(element.textContent, key: key, style: preferredStyle);
  }
}

/// A fenced block, highlighted like the editor when its language is one Bird
/// knows.
class _CodeBlock extends MarkdownElementBuilder {
  _CodeBlock(this.editorTheme);

  final Map<String, TextStyle> editorTheme;

  /// Fence names that are not file extensions.
  static const _aliases = {'shell': 'sh', 'console': 'sh', 'zsh': 'sh'};

  static final _highlight = Highlight();

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent.replaceFirst(RegExp(r'\n$'), '');
    final fence = (element.children?.firstOrNull as md.Element?)
        ?.attributes['class']
        ?.replaceFirst('language-', '');
    final language = fence == null
        ? null
        : Languages.forPath('.${_aliases[fence] ?? fence}');
    final base = TextStyle(
      fontFamily: 'FiraCode',
      fontSize: 12.5,
      height: 1.5,
      color: editorTheme['root']?.color,
    );

    var span = TextSpan(text: code, style: base);
    if (language != null) {
      _highlight.registerLanguage(language.name, language.mode);
      final renderer = TextSpanRenderer(base, editorTheme);
      _highlight
          .highlight(code: code, language: language.name)
          .render(renderer);
      span = renderer.span ?? span;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(14),
      child: SelectableText.rich(span),
    );
  }
}

MarkdownStyleSheet _style(ThemeData theme) {
  final primary = theme.colorScheme.primary;
  final accent = theme.colorScheme.tertiary;
  final body = TextStyle(
    fontSize: 13.5,
    height: 1.6,
    color: primary.withValues(alpha: 0.85),
  );
  TextStyle heading(double size) => TextStyle(
    fontSize: size,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: primary,
  );
  final rule = BorderSide(color: primary.withValues(alpha: 0.12));

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: body,
    listBullet: body,
    tableBody: body,
    tableHead: body.copyWith(fontWeight: FontWeight.w600),
    h1: heading(22),
    h2: heading(18),
    h3: heading(15),
    h4: heading(14),
    h1Padding: const EdgeInsets.only(top: 20),
    h2Padding: const EdgeInsets.only(top: 16),
    h3Padding: const EdgeInsets.only(top: 12),
    a: body.copyWith(color: accent, decorationColor: accent),
    // Inline code only now: code blocks draw themselves in _CodeBlock.
    code: TextStyle(fontFamily: 'FiraCode', fontSize: 12.5, color: primary),
    codeblockDecoration: BoxDecoration(
      color: theme.colorScheme.secondary.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      border: Border.fromBorderSide(rule),
    ),
    blockquotePadding: const EdgeInsets.only(left: 14),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: accent.withValues(alpha: 0.6), width: 3),
      ),
    ),
    tableBorder: TableBorder.all(color: rule.color),
    horizontalRuleDecoration: BoxDecoration(border: Border(top: rule)),
  );
}

/// A web image, or a relative one fetched from the repository. A `#<width>`
/// fragment is the width an HTML `<img>` asked for.
Widget _image(Uri uri, String? repository) {
  final width = double.tryParse(uri.fragment);
  final source = uri.removeFragment();
  final url = source.hasScheme
      ? source
      : githubUrl(source.toString(), repository, raw: true);
  if (url == null || !(url.isScheme('https') || url.isScheme('http'))) {
    return const SizedBox.shrink();
  }
  if (url.host == 'img.shields.io') {
    return SvgPicture(
      _Svg('$url', badge: true),
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
  if (url.path.toLowerCase().endsWith('.svg')) {
    return SvgPicture(
      _Svg('$url'),
      height: 20,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
  return Image.network(
    '$url',
    width: width,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

/// A web SVG that cannot take the page down: what arrives is checked by
/// [svgOrBlank] first, and a shields.io [badge] is fixed by [unscaleBadge].
///
/// flutter_svg parses on another isolate and throws there, out of reach of
/// `errorBuilder`, so a link that answers with HTML — a `github.com/…/blob/`
/// URL, a 404 page — surfaced as an unhandled exception.
class _Svg extends SvgNetworkLoader {
  const _Svg(super.url, {this.badge = false});

  final bool badge;

  @override
  String provideSvg(Uint8List? message) {
    final svg = svgOrBlank(super.provideSvg(message));
    return badge ? unscaleBadge(svg) : svg;
  }
}
