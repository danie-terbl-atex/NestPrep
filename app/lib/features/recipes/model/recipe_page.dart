import 'package:flutter/foundation.dart';

@immutable
final class RecipePage {
  const RecipePage({
    required this.url,
    required this.title,
    required this.jsonLd,
    required this.text,
    required this.imageUrls,
  });

  static const maxChars = 60000;
  static const maxImages = 6;
  static const maxJsonLdBlocks = 10;
  static const maxTitleChars = 300;

  /// Past a refusal or an error page, which is 5 KB of markup and a sentence
  /// or two, and well short of the smallest text-only recipe the eval met,
  /// about 4,400. Under it, no model call is spent.
  static const minTextChars = 1000;

  final String url;
  final String? title;
  final List<String> jsonLd;
  final String text;
  final List<String> imageUrls;

  int get chars =>
      (title?.length ?? 0) +
      text.length +
      jsonLd.fold(0, (total, block) => total + block.length);

  Map<String, Object?> toWire() => {
    'url': url,
    'title': title,
    'jsonLd': jsonLd,
    'text': text,
    'imageUrls': imageUrls,
  };
}
