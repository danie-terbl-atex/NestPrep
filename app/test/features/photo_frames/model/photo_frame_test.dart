import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';

PhotoFrame frameWithout(String panel) => PhotoFrame.fromJson({
  'id': 'f1',
  'name': 'Kitchen frame',
  'panels': {
    'calendar': true,
    'todos': true,
    'meals': true,
    'lunch': true,
    'addEvents': true,
    'share': true,
    'helperMemberId': null,
  }..remove(panel),
});

void main() {
  final now = DateTime.utc(2026, 10, 24, 10);

  test('reads the document the claim writes', () {
    final frame = PhotoFrame.fromJson({
      'id': 'f1',
      'name': 'Kitchen frame',
      'panels': {
        'calendar': true,
        'todos': false,
        'meals': true,
        'helperMemberId': 'm-thandi',
      },
      'model': 'NestPrep Home',
      'linkedBy': 'uid-sam',
      'linkedAt': Timestamp.fromDate(now),
      'lastSeenAt': null,
    });

    expect(frame.name, 'Kitchen frame');
    expect(
      frame.panels,
      const FramePanels(todos: false, helperMemberId: 'm-thandi'),
    );
    expect(frame.linkedAt, now);
    expect(frame.lastSeenAt, isNull);
  });

  test('panels write the exact shape the rules ask for', () {
    expect(const FramePanels(meals: false).toJson(), {
      'calendar': true,
      'todos': true,
      'meals': false,
      'lunch': false,
      'addEvents': false,
      'share': false,
      'people': false,
      'helperMemberId': null,
    });
  });

  test('a frame linked before sharing does not open shared pages', () {
    expect(frameWithout('share').panels.share, isFalse);
    expect(const FramePanels().share, isFalse);
  });

  test('panels survive the round trip, with sharing on and without it', () {
    for (final panels in [
      const FramePanels(share: true, addEvents: true),
      const FramePanels(lunch: true, helperMemberId: 'm-thandi'),
    ]) {
      expect(FramePanels.fromJson(panels.toJson()), panels);
    }
    final stored = const FramePanels(share: true).toJson();
    expect(stored['share'], isTrue);
    expect(
      FramePanels.fromJson({...stored}..remove('share')),
      const FramePanels(),
    );
  });

  test('a frame linked before adding events cannot add them', () {
    expect(frameWithout('addEvents').panels.addEvents, isFalse);
    expect(const FramePanels().addEvents, isFalse);
    final adding = PhotoFrame.fromJson({
      'id': 'f1',
      'name': 'Kitchen frame',
      'panels': {
        'calendar': true,
        'todos': true,
        'meals': true,
        'addEvents': true,
        'helperMemberId': null,
      },
    });
    expect(adding.panels.addEvents, isTrue);
  });

  test('a frame linked before lunch boxes has them off', () {
    expect(frameWithout('lunch').panels.lunch, isFalse);
    expect(
      const FramePanels(
        calendar: false,
        todos: false,
        meals: false,
        lunch: true,
      ).showsAnything,
      isTrue,
    );
  });

  test('a frame linked before where everyone is has it off', () {
    expect(frameWithout('people').panels.people, isFalse);
    expect(const FramePanels().people, isFalse);
    expect(
      FramePanels.fromJson(const FramePanels(people: true).toJson()).people,
      isTrue,
    );
    expect(
      const FramePanels(
        calendar: false,
        todos: false,
        meals: false,
        people: true,
      ).showsAnything,
      isTrue,
    );
  });

  test('a panel set with nothing on shows nothing', () {
    expect(
      const FramePanels(
        calendar: false,
        todos: false,
        meals: false,
      ).showsAnything,
      isFalse,
    );
    expect(
      const FramePanels(
        calendar: false,
        todos: false,
        meals: false,
        helperMemberId: 'm-thandi',
      ).showsAnything,
      isTrue,
    );
  });

  group('what it opens', () {
    PhotoFrame frameAccepting(Object? accepts) => PhotoFrame.fromJson({
      'id': 'f1',
      'name': 'Kitchen frame',
      'accepts': ?accepts,
    });

    test('a frame that has never said opens pages only', () {
      final frame = frameAccepting(null);
      expect(frame.accepts, ['page']);
      expect(frame.opensRecipes, isFalse);
    });

    test('a frame that cooks along says so', () {
      final frame = frameAccepting(['page', 'recipe']);
      expect(frame.accepts, ['page', 'recipe']);
      expect(frame.opensRecipes, isTrue);
    });

    test('a kind this app has not heard of is kept, not a reason to doubt '
        'the rest', () {
      expect(frameAccepting(['page', 'recipe', 'video']).opensRecipes, isTrue);
    });

    test('anything malformed reads as pages only', () {
      for (final malformed in [
        'recipe',
        42,
        {'recipe': true},
        ['page', 7],
      ]) {
        expect(frameAccepting(malformed).accepts, [
          'page',
        ], reason: '$malformed');
      }
    });

    test('is the server’s to write, never the app’s', () {
      final frame = frameAccepting(['page', 'recipe']);
      expect(frame.toJson().containsKey('accepts'), isFalse);
    });
  });

  group('quiet', () {
    PhotoFrame frame({DateTime? linkedAt, DateTime? lastSeenAt}) => PhotoFrame(
      id: 'f1',
      name: 'Kitchen frame',
      linkedAt: linkedAt,
      lastSeenAt: lastSeenAt,
    );

    test('seen within the hour is not', () {
      expect(
        frame(lastSeenAt: now.subtract(const Duration(minutes: 59)))
            .isQuietAt(now),
        isFalse,
      );
    });

    test('seen more than an hour ago is', () {
      expect(
        frame(lastSeenAt: now.subtract(const Duration(minutes: 61)))
            .isQuietAt(now),
        isTrue,
      );
    });

    test('never seen counts from when it was linked', () {
      expect(
        frame(linkedAt: now.subtract(const Duration(minutes: 5)))
            .isQuietAt(now),
        isFalse,
      );
      expect(
        frame(linkedAt: now.subtract(const Duration(hours: 2))).isQuietAt(now),
        isTrue,
      );
    });

    test('a frame the server has not stamped yet is not', () {
      expect(frame().isQuietAt(now), isFalse);
    });
  });
}
