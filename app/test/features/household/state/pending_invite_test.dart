import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/state/pending_invite.dart';

void main() {
  late StreamController<Uri> links;
  late PendingInvite pending;
  late int notified;

  setUp(() {
    links = StreamController<Uri>();
    pending = PendingInvite(links: links.stream);
    notified = 0;
    pending.addListener(() => notified++);
  });

  tearDown(() async {
    pending.dispose();
    await links.close();
  });

  test('holds the code an invite link brings, until it is cleared', () async {
    links.add(Uri.parse('nestprep://invite/abcd2345'));
    await pumpEventQueue();
    expect(pending.code, 'ABCD2345');

    pending.clear();
    expect(pending.code, isNull);
    expect(notified, 2);
  });

  test(
    'ignores a link that is not an invite, and the same one twice',
    () async {
      links
        ..add(Uri.parse('https://example.com/invite/ABCD2345'))
        ..add(Uri.parse('nestprep://invite/ABCD2345'))
        ..add(Uri.parse('https://nestprep-643b7.web.app/invite/ABCD2345'));
      await pumpEventQueue();
      expect(pending.code, 'ABCD2345');
      expect(notified, 1);
    },
  );

  test('holds a typed code like a tapped one, and refuses what is not one', () {
    expect(pending.offerCode('abc'), isFalse);
    expect(pending.offerCode('ABCD234I'), isFalse);
    expect(pending.code, isNull);

    expect(pending.offerCode(' abcd2345 '), isTrue);
    expect(pending.code, 'ABCD2345');
    expect(notified, 1);
  });
}
