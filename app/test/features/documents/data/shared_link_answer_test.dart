import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/data/callable_document_share_directory.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// What `createDocumentShare` answers, parsed at the edge (`ENG-09`,
/// documents ADR-0006): a link the app cannot read is never handed to a
/// person as if it were one.
void main() {
  test('a whole answer becomes the link, its id and when it ends', () {
    final link = parseSharedLink({
      'shareId': 's1',
      'url': 'https://africa-south1-x.cloudfunctions.net/documentShare?t=abc',
      'expiresAt': '2026-09-30T16:00:00.000Z',
    });
    expect(link.shareId, 's1');
    expect(link.url.queryParameters['t'], 'abc');
    expect(link.expiresAt, DateTime.utc(2026, 9, 30, 16));
    expect(link.expiresAt.isUtc, isTrue);
  });

  test('anything else is refused, not guessed at', () {
    for (final answer in <Object?>[
      null,
      'a link',
      {'shareId': 's1'},
      {'shareId': 's1', 'url': 'not a url', 'expiresAt': '2026-09-30'},
      {'shareId': 's1', 'url': 'https://x.test/a', 'expiresAt': 'soon'},
      {'shareId': 1, 'url': 'https://x.test/a', 'expiresAt': '2026-09-30'},
    ]) {
      expect(
        () => parseSharedLink(answer),
        throwsA(isA<UnknownFailure>()),
        reason: '$answer',
      );
    }
  });
}
