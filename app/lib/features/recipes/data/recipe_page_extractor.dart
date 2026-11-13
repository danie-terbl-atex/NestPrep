import 'dart:convert';
import 'dart:typed_data';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../model/recipe_page.dart';
import 'page_link.dart';

const _imageMetas = {
  'og:image',
  'og:image:url',
  'og:image:secure_url',
  'twitter:image',
  'twitter:image:src',
};

const _invisible =
    'script, style, noscript, template, svg, nav, header, footer, aside, form';

final _space = RegExp(r'\s+');
final _control = RegExp(r'[\x00-\x1f]');
final _trailingComma = RegExp(r',\s*([}\]])');
final _wrapper = RegExp(
  r'<!--|-->|//\s*<!\[CDATA\[|//\s*\]\]>|<!\[CDATA\[|\]\]>',
);

String decodedPage(Uint8List bytes, String? contentType) {
  final type = contentType?.toLowerCase() ?? '';
  final isLatin = ['iso-8859-1', 'latin1', 'windows-1252'].any(type.contains);
  return isLatin
      ? latin1.decode(bytes)
      : utf8.decode(bytes, allowMalformed: true);
}

/// Null when the page has neither a recipe nor enough words to hold one, so no
/// model call is spent on it. Mirrors `tools/recipe-import-eval.mjs`.
RecipePage? extractRecipePage({required String url, required String html}) {
  final document = html_parser.parse(html);
  final title = _clipped(
    document.querySelector('title')?.text.trim() ?? '',
    RecipePage.maxTitleChars,
  );
  final recipes = _recipesIn(document);
  final imageUrls = _imagesOf(document, recipes, pageUrl: url);
  var room = RecipePage.maxChars - title.length;
  final jsonLd = <String>[];
  for (final recipe in recipes) {
    if (jsonLd.length == RecipePage.maxJsonLdBlocks) break;
    final block = jsonEncode(recipe);
    if (block.length > room) continue;
    jsonLd.add(block);
    room -= block.length;
  }
  final text = jsonLd.isEmpty ? _clipped(_visibleText(document), room) : '';
  if (jsonLd.isEmpty && text.length < RecipePage.minTextChars) return null;
  return RecipePage(
    url: url,
    title: title.isEmpty ? null : title,
    jsonLd: jsonLd,
    text: text,
    imageUrls: imageUrls,
  );
}

List<Map<Object?, Object?>> _recipesIn(Document document) => [
  for (final script in document.querySelectorAll('script'))
    if (_isJsonLd(script)) ..._recipeNodes(_lenientJson(script.text)),
];

bool _isJsonLd(Element script) =>
    script.attributes['type']?.trim().toLowerCase().startsWith(
      'application/ld+json',
    ) ??
    false;

Object? _lenientJson(String raw) {
  for (final attempt in [raw, _repaired(raw)]) {
    try {
      return jsonDecode(attempt);
    } on FormatException {
      continue;
    }
  }
  return null;
}

String _repaired(String raw) {
  final bare = raw
      .replaceAll(_wrapper, '')
      .replaceAll(_control, ' ')
      .replaceAllMapped(_trailingComma, (match) => match.group(1)!)
      .trim();
  return bare.endsWith(';') ? bare.substring(0, bare.length - 1) : bare;
}

Iterable<Map<Object?, Object?>> _recipeNodes(Object? value) sync* {
  if (value is List) {
    for (final item in value) {
      yield* _recipeNodes(item);
    }
  } else if (value is Map<Object?, Object?>) {
    if (_isRecipe(value)) {
      yield value;
    } else {
      yield* _recipeNodes(value['@graph']);
    }
  }
}

bool _isRecipe(Map<Object?, Object?> node) => switch (node['@type']) {
  'Recipe' => true,
  final List<Object?> types => types.contains('Recipe'),
  _ => false,
};

List<String> _imagesOf(
  Document document,
  List<Map<Object?, Object?>> recipes, {
  required String pageUrl,
}) {
  final base = Uri.parse(pageUrl);
  final candidates = [
    for (final recipe in recipes) ..._imageValues(recipe['image']),
    for (final meta in document.querySelectorAll('meta'))
      if (_imageMetas.contains(
        (meta.attributes['property'] ?? meta.attributes['name'])?.toLowerCase(),
      ))
        ?meta.attributes['content'],
  ];
  final links = <String>{};
  for (final candidate in candidates) {
    final target = Uri.tryParse(candidate.trim());
    if (target == null || candidate.trim().isEmpty) continue;
    final link = pageLink(base.resolveUri(target).toString());
    if (link != null) links.add(link);
  }
  return links.take(RecipePage.maxImages).toList();
}

Iterable<String> _imageValues(Object? image) sync* {
  if (image is String) {
    yield image;
  } else if (image is List) {
    for (final item in image) {
      yield* _imageValues(item);
    }
  } else if (image is Map && image['url'] is String) {
    yield image['url'] as String;
  }
}

String _visibleText(Document document) {
  final body = document.body;
  if (body == null) return '';
  for (final hidden in body.querySelectorAll(_invisible)) {
    hidden.remove();
  }
  final words = StringBuffer();
  final waiting = <Node>[body];
  while (waiting.isNotEmpty) {
    final node = waiting.removeLast();
    if (node is Text) {
      words
        ..write(node.text)
        ..write(' ');
    } else {
      waiting.addAll(node.nodes.reversed);
    }
  }
  return words.toString().replaceAll(_space, ' ').trim();
}

String _clipped(String text, int limit) {
  if (text.length <= limit) return text;
  final splitsAPair = (text.codeUnitAt(limit - 1) & 0xfc00) == 0xd800;
  return text.substring(0, splitsAPair ? limit - 1 : limit);
}
