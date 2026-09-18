import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/live_location_view.dart';
import 'package:nestprep/features/live_location/model/located_member.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';

import '../../../support/household_fixtures.dart';

/// The four things this screen can say about a person, and when it says each.
///
/// The one that matters is the line between [MemberPresence.hereNow] and
/// [MemberPresence.lastSeen]. A position from forty minutes ago drawn as if it
/// were live is the failure this feature exists to avoid (live-location
/// ADR-0002), and it is a comparison with a clock — which means it is a
/// comparison that can be got wrong silently.
void main() {
  final now = DateTime.utc(2026, 9, 18, 14);
  const johannesburg = Coordinates(latitude: -26.2041, longitude: 28.0473);
  const pretoria = Coordinates(latitude: -25.7479, longitude: 28.2293);

  MemberLocation locationFor(
    String memberId, {
    Duration? reportedAgo,
    Duration sharingFor = const Duration(hours: 1),
    Coordinates at = johannesburg,
  }) => MemberLocation(
    id: memberId,
    point: at,
    accuracyMetres: 12,
    reportedAt: reportedAgo == null ? null : now.subtract(reportedAgo),
    sharingUntil: now.add(sharingFor),
  );

  LiveLocationView viewOf(
    List<MemberLocation> locations, {
    String viewer = Fixtures.samMemberId,
  }) => LiveLocationView.from(
    members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    locations: locations,
    viewerMemberId: viewer,
    now: now,
  );

  LocatedMember rowFor(LiveLocationView view, String memberId) =>
      view.others.firstWhere((located) => located.member.id == memberId);

  group('what the screen says about somebody', () {
    test('a fresh position inside an open window is here now', () {
      final view = viewOf([
        locationFor(
          Fixtures.thandiMemberId,
          reportedAgo: const Duration(seconds: 30),
        ),
      ]);

      expect(
        rowFor(view, Fixtures.thandiMemberId).presence,
        MemberPresence.hereNow,
      );
    });

    test('a position older than two minutes is last seen, with its age', () {
      final view = viewOf([
        locationFor(
          Fixtures.thandiMemberId,
          reportedAgo: const Duration(minutes: 24),
        ),
      ]);
      final row = rowFor(view, Fixtures.thandiMemberId);

      expect(row.presence, MemberPresence.lastSeen);
      expect(row.age, const Duration(minutes: 24));
    });

    test('the line between them is exactly two minutes', () {
      // A sharing device reports at least every 90 seconds while it moves, so
      // two minutes is "one report has not arrived". Move this number and the
      // screen starts calling stale positions live.
      final onTheLine = viewOf([
        locationFor(
          Fixtures.thandiMemberId,
          reportedAgo: LocatedMember.liveWithin,
        ),
      ]);
      final justPast = viewOf([
        locationFor(
          Fixtures.thandiMemberId,
          reportedAgo: LocatedMember.liveWithin + const Duration(seconds: 1),
        ),
      ]);

      expect(
        rowFor(onTheLine, Fixtures.thandiMemberId).presence,
        MemberPresence.hereNow,
      );
      expect(
        rowFor(justPast, Fixtures.thandiMemberId).presence,
        MemberPresence.lastSeen,
      );
    });

    test('a write the server has not timed yet counts as a moment ago', () {
      // `reportedAt` is null until the write reaches the server. It was written
      // by a device that is reporting right now, so treating it as stale would
      // make every share look broken for its first second.
      final view = viewOf([locationFor(Fixtures.thandiMemberId)]);

      expect(
        rowFor(view, Fixtures.thandiMemberId).presence,
        MemberPresence.hereNow,
      );
    });

    test('a closed window is not sharing, however fresh the position', () {
      final view = viewOf([
        locationFor(
          Fixtures.thandiMemberId,
          reportedAgo: const Duration(seconds: 5),
          sharingFor: const Duration(seconds: -1),
        ),
      ]);
      final row = rowFor(view, Fixtures.thandiMemberId);

      expect(row.presence, MemberPresence.notSharing);
      expect(
        row.at,
        isNull,
        reason: 'a share that has ended leaves nowhere to point at',
      );
    });

    test('somebody with no document is not sharing, not missing', () {
      final view = viewOf([]);

      expect(
        rowFor(view, Fixtures.thandiMemberId).presence,
        MemberPresence.notSharing,
      );
    });

    test('a profile nobody has claimed can never be anywhere', () {
      // The rules make this document impossible to write (`isOwnMember` on an
      // unclaimed profile is false for every caller). If one somehow existed,
      // the screen still refuses to place a person who has no device.
      final view = viewOf([
        locationFor(
          Fixtures.kidMemberId,
          reportedAgo: const Duration(seconds: 5),
        ),
      ]);
      final row = rowFor(view, Fixtures.kidMemberId);

      expect(row.presence, MemberPresence.hasNotJoined);
      expect(row.at, isNull);
    });
  });

  group('the person looking', () {
    test('is held apart from everybody else', () {
      final view = viewOf([]);

      expect(view.viewer?.member.id, Fixtures.samMemberId);
      expect(
        view.others.map((located) => located.member.id),
        isNot(contains(Fixtures.samMemberId)),
        reason: 'their own sharing is the card, not a row',
      );
    });

    test('sees a distance to somebody else only when they are sharing too', () {
      final onlyThandi = viewOf([
        locationFor(
          Fixtures.thandiMemberId,
          reportedAgo: const Duration(seconds: 5),
          at: pretoria,
        ),
      ]);
      expect(
        rowFor(onlyThandi, Fixtures.thandiMemberId).metresFromViewer,
        isNull,
      );

      final both = viewOf([
        locationFor(
          Fixtures.samMemberId,
          reportedAgo: const Duration(seconds: 5),
        ),
        locationFor(
          Fixtures.thandiMemberId,
          reportedAgo: const Duration(seconds: 5),
          at: pretoria,
        ),
      ]);
      final metres = rowFor(both, Fixtures.thandiMemberId).metresFromViewer;

      // Johannesburg to Pretoria, in a straight line.
      expect(metres, isNotNull);
      expect(metres! / 1000, closeTo(53.9, 0.5));
    });

    test('is null when the account has claimed no profile here', () {
      final view = viewOf([], viewer: 'nobody');

      expect(view.viewer, isNull);
      expect(view.others, hasLength(3));
    });
  });

  group('the order of the list', () {
    test('puts whoever is findable first, then by name', () {
      final view = LiveLocationView.from(
        members: [Fixtures.kid, Fixtures.thandi, Fixtures.sam],
        locations: [
          locationFor(
            Fixtures.thandiMemberId,
            reportedAgo: const Duration(minutes: 30),
          ),
        ],
        viewerMemberId: Fixtures.samMemberId,
        now: now,
      );

      expect(view.others.map((located) => located.presence), [
        MemberPresence.lastSeen,
        MemberPresence.hasNotJoined,
      ]);
    });
  });

  test('a household of one is empty, and nobody is hidden by that', () {
    final alone = LiveLocationView.from(
      members: [Fixtures.sam],
      locations: const [],
      viewerMemberId: Fixtures.samMemberId,
      now: now,
    );

    expect(alone.isEmpty, isTrue);
    expect(viewOf([]).isEmpty, isFalse);
  });
}
