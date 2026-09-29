import 'package:nestprep/shared/links/external_link_opener.dart';

/// A phone where opening a link works, or — when told — does not. The one fake
/// for every link the app hands outside itself: a document's download link, a
/// provider's sign-in page, a calendar subscription (`ENG-01`).
final class FakeLinkOpener implements ExternalLinkOpener {
  bool opens = true;
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri link) async {
    opened.add(link);
    return opens;
  }
}
