import '../../../shared/links/app_link_site.dart';

/// The link an invite travels as (household ADR-0005, ADR-0012). It carries
/// the code and nothing else; joining is still the code, redeemed server-side
/// (ADR-0002).
abstract final class InviteLinks {
  static const segment = 'invite';
  static const codeLength = 8;
  static const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

  static Uri linkFor(String code) =>
      AppLinkSite.origin.replace(path: '/$segment/$code');

  static String? codeFrom(Uri uri) {
    final candidate = AppLinkSite.segmentAfter(segment, uri);
    if (candidate == null) return null;
    final code = candidate.trim().toUpperCase();
    final isCode =
        code.length == codeLength && code.split('').every(alphabet.contains);
    return isCode ? code : null;
  }
}
