/// The link an invite travels as (household ADR-0005). It carries the code and
/// nothing else; joining is still the code, redeemed server-side (ADR-0002).
abstract final class InviteLinks {
  static final site = Uri.https('nestprep-643b7.web.app');
  static const hosts = {
    'nestprep-643b7.web.app',
    'nestprep-643b7.firebaseapp.com',
  };
  static const scheme = 'nestprep';
  static const codeLength = 8;
  static const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

  static Uri linkFor(String code) => site.replace(path: '/invite/$code');

  static String? codeFrom(Uri uri) {
    final segments = uri.pathSegments.where((each) => each.isNotEmpty).toList();
    final candidate = switch (uri.scheme) {
      'https'
          when hosts.contains(uri.host) &&
              segments.length == 2 &&
              segments.first == 'invite' =>
        segments.last,
      scheme when uri.host == 'invite' && segments.length == 1 =>
        segments.single,
      _ => null,
    };
    if (candidate == null) return null;
    final code = candidate.trim().toUpperCase();
    final isCode =
        code.length == codeLength && code.split('').every(alphabet.contains);
    return isCode ? code : null;
  }
}
