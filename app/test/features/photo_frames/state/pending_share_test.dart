import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/model/shared_page.dart';
import 'package:nestprep/features/photo_frames/state/pending_share.dart';

void main() {
  late StreamController<Uri> links;
  late PendingShare pending;
  late int notified;

  setUp(() {
    links = StreamController<Uri>.broadcast();
    pending = PendingShare(links: links.stream);
    notified = 0;
    pending.addListener(() => notified++);
  });

  tearDown(() async {
    pending.dispose();
    await links.close();
  });

  test('holds the page a share link brings, until it is taken', () async {
    links.add(
      Uri.parse(
        'nestprep://share?url=https%3A%2F%2Fexample.com%2Ftart&title=Tart',
      ),
    );
    await pumpEventQueue();
    expect(
      pending.page,
      const SharedPage(url: 'https://example.com/tart', title: 'Tart'),
    );

    expect(pending.take()?.url, 'https://example.com/tart');
    expect(pending.page, isNull);
    expect(pending.take(), isNull);
    expect(notified, 2);
  });

  test('the latest share wins', () async {
    links
      ..add(Uri.parse('nestprep://share?url=https://one.example.com'))
      ..add(Uri.parse('nestprep://share?url=https://two.example.com'));
    await pumpEventQueue();
    expect(pending.page?.url, 'https://two.example.com');
  });

  test(
    'leaves an invite to the invite, and the invite still gets it',
    () async {
      final invites = <Uri>[];
      final listening = links.stream.listen(invites.add);
      links.add(Uri.parse('nestprep://invite/ABCD2345'));
      await pumpEventQueue();
      await listening.cancel();

      expect(pending.page, isNull);
      expect(notified, 0);
      expect(invites, [Uri.parse('nestprep://invite/ABCD2345')]);
    },
  );
}
