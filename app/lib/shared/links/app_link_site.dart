/// The site whose links open the app (household ADR-0005, ADR-0012). Every
/// host here is claimed by the Android manifest, the iOS entitlements and both
/// well-known files; `invite_links_test.dart` and `site_is_generated.test.ts`
/// hold them together.
abstract final class AppLinkSite {
  static final origin = Uri.https('app.nestprep.io');
  static const hosts = {
    'app.nestprep.io',
    'nestprep-643b7.web.app',
    'nestprep-643b7.firebaseapp.com',
  };
  static const scheme = 'nestprep';

  /// The one path segment after [prefix] on one of our hosts, or the one after
  /// `nestprep://<prefix>/`; null for any other link.
  static String? segmentAfter(String prefix, Uri uri) {
    final segments = uri.pathSegments.where((each) => each.isNotEmpty).toList();
    return switch (uri.scheme.toLowerCase()) {
      'https'
          when hosts.contains(uri.host.toLowerCase()) &&
              segments.length == 2 &&
              segments.first == prefix =>
        segments.last,
      scheme when uri.host.toLowerCase() == prefix && segments.length == 1 =>
        segments.single,
      _ => null,
    };
  }
}
