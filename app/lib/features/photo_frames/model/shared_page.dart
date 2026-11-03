import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_page.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class SharedPage with _$SharedPage {
  const factory SharedPage({String? url, String? title}) = _SharedPage;

  const SharedPage._();

  static const scheme = 'nestprep';
  static const host = 'share';
  static const urlMaxLength = 2048;
  static const titleMaxLength = 200;

  static final _webLink = RegExp(
    r'''https?://[^\s<>"'`]+''',
    caseSensitive: false,
  );
  static final _trailing = RegExp(r'''[.,;:!?'"*»”’]+$''');
  static final _control = RegExp(r'[\u0000-\u001f\u007f-\u009f]');
  static final _space = RegExp(r'\s+');
  static const _openerOf = {')': '(', ']': '[', '}': '{'};

  String? get site {
    final link = url;
    return link == null ? null : Uri.tryParse(link)?.host;
  }

  static SharedPage? fromLink(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) return null;
    final query = uri.queryParameters;
    return SharedPage(
      url: firstWebLink(query['url'] ?? ''),
      title: cleanTitle(query['title']),
    );
  }

  static String? firstWebLink(String text) {
    for (final match in _webLink.allMatches(text)) {
      final link = _trimmed(match.group(0)!);
      if (Uri.tryParse(link)?.host.isNotEmpty ?? false) return link;
    }
    return null;
  }

  static String? cleanTitle(String? raw) {
    if (raw == null) return null;
    final title = raw.replaceAll(_control, ' ').replaceAll(_space, ' ').trim();
    if (title.isEmpty) return null;
    return title.length <= titleMaxLength
        ? title
        : title.substring(0, titleMaxLength).trimRight();
  }

  static String _trimmed(String link) {
    var trimmed = link;
    while (true) {
      final next = trimmed.replaceFirst(_trailing, '');
      final last = next.isEmpty ? '' : next[next.length - 1];
      final opener = _openerOf[last];
      final unbalanced =
          opener != null &&
          opener.allMatches(next).length < last.allMatches(next).length;
      final stripped = unbalanced ? next.substring(0, next.length - 1) : next;
      if (stripped == trimmed) return trimmed;
      trimmed = stripped;
    }
  }
}
