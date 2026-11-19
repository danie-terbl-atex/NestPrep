import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/state/pending_frame_code.dart';

void main() {
  late StreamController<Uri> links;
  late PendingFrameCode pending;
  late int notified;

  setUp(() {
    links = StreamController<Uri>();
    pending = PendingFrameCode(links: links.stream);
    notified = 0;
    pending.addListener(() => notified++);
  });

  tearDown(() async {
    pending.dispose();
    await links.close();
  });

  test('holds the code a frame link brings until it is taken', () async {
    links.add(Uri.parse('nestprep://frame/k7mq9z'));
    await pumpEventQueue();
    expect(pending.code, 'K7MQ9Z');

    expect(pending.take(), 'K7MQ9Z');
    expect(pending.code, isNull);
    expect(pending.take(), isNull);
    expect(notified, 2);
  });

  test('reads the https link as well', () async {
    links.add(Uri.parse('https://app.nestprep.io/frame/K7MQ9Z'));
    await pumpEventQueue();
    expect(pending.code, 'K7MQ9Z');
  });

  test('ignores invites, other links and the same code twice', () async {
    links
      ..add(Uri.parse('nestprep://invite/ABCD2345'))
      ..add(Uri.parse('https://example.com/frame/K7MQ9Z'))
      ..add(Uri.parse('nestprep://frame/K7MQ9Z'))
      ..add(Uri.parse('nestprep://frame/K7MQ9Z'));
    await pumpEventQueue();
    expect(pending.code, 'K7MQ9Z');
    expect(notified, 1);
  });
}
