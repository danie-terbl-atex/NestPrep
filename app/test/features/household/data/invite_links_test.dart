import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/data/invite_links.dart';

void main() {
  test('a link carries the code on the site the app claims', () {
    expect(
      InviteLinks.linkFor('ABCD2345').toString(),
      'https://nestprep-643b7.web.app/invite/ABCD2345',
    );
    expect(InviteLinks.codeFrom(InviteLinks.linkFor('ABCD2345')), 'ABCD2345');
  });

  test('reads the code from the site, either host, and the scheme', () {
    for (final link in [
      'https://nestprep-643b7.web.app/invite/ABCD2345',
      'https://nestprep-643b7.firebaseapp.com/invite/abcd2345/',
      'nestprep://invite/ABCD2345',
    ]) {
      expect(InviteLinks.codeFrom(Uri.parse(link)), 'ABCD2345', reason: link);
    }
  });

  test('refuses anything that is not one of our invites', () {
    for (final link in [
      'https://example.com/invite/ABCD2345',
      'https://nestprep-643b7.web.app/privacy',
      'https://nestprep-643b7.web.app/invite/',
      'https://nestprep-643b7.web.app/invite/ABCD2345/more',
      'https://nestprep-643b7.web.app/invite/ABCD234',
      'https://nestprep-643b7.web.app/invite/O0IL1234',
      'http://nestprep-643b7.web.app/invite/ABCD2345',
      'nestprep://pair/ABCD2345',
    ]) {
      expect(InviteLinks.codeFrom(Uri.parse(link)), isNull, reason: link);
    }
  });

  test('the letters and length are the server code\'s', () {
    final server = File(
      '../functions/src/shared/readable_code.ts',
    ).readAsStringSync();
    expect(server, contains("READABLE_ALPHABET = '${InviteLinks.alphabet}'"));
    final invite = File(
      '../functions/src/household/invite_code.ts',
    ).readAsStringSync();
    expect(invite, contains('CODE_LENGTH = ${InviteLinks.codeLength};'));
  });

  test('the platforms open exactly the links this reads', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    for (final host in InviteLinks.hosts) {
      expect(manifest, contains('android:host="$host"'));
    }
    expect(manifest, contains('android:scheme="${InviteLinks.scheme}"'));
    expect(manifest, contains('flutter_deeplinking_enabled'));
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<string>${InviteLinks.scheme}</string>'));
    expect(plist, contains('FlutterDeepLinkingEnabled'));
  });
}
