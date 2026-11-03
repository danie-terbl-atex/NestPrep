import '../../household/model/member.dart';
import 'coordinates.dart';
import 'family_place.dart';
import 'member_location.dart';

/// What the screen says about one person, and the only four things it can say.
///
/// The distinction between [hereNow] and [lastSeen] is the safety one: a
/// position from forty minutes ago drawn as if it were live is worse than
/// showing nothing at all (live-location ADR-0002).
enum MemberPresence {
  /// Sharing, and the position is fresh enough to mean *now*.
  hereNow,

  /// Sharing, but the last fix is old — the phone lost signal, or went into a
  /// pocket in a building. The age is shown beside it.
  lastSeen,

  /// Not sharing: never started, stopped, or the window has closed.
  notSharing,

  /// Nobody has claimed this profile, so there is no device that could report
  /// for it — and no rule that would let one (live-location ADR-0001).
  hasNotJoined,
}

/// One member as the live-location screen reads them: who they are, what is
/// known about where they are, and how old that is.
class LocatedMember {
  const LocatedMember({
    required this.member,
    required this.presence,
    this.at,
    this.accuracyMetres,
    this.age,
    this.sharingUntil,
    this.metresFromViewer,
    this.mode = ShareMode.window,
    this.place,
    this.batteryPercent,
    this.charging,
    this.motion,
  });

  /// Reads [location] against the clock. [viewerAt] is where the person
  /// looking is, when they are sharing too — without it there is no distance
  /// to show, which is the ordinary case for somebody who has not shared.
  factory LocatedMember.from({
    required Member member,
    required MemberLocation? location,
    required DateTime now,
    Coordinates? viewerAt,
    List<FamilyPlace> places = const [],
  }) {
    if (location == null || !location.isSharingAt(now)) {
      return LocatedMember(
        member: member,
        presence: member.isClaimed
            ? MemberPresence.notSharing
            : MemberPresence.hasNotJoined,
      );
    }
    final age = location.ageAt(now);
    final freshFor = location.mode == ShareMode.continuous
        ? liveWithinAlways
        : liveWithin;
    return LocatedMember(
      member: member,
      // A write the server has not timed yet was, by definition, a moment ago.
      presence: age == null || age <= freshFor
          ? MemberPresence.hereNow
          : MemberPresence.lastSeen,
      at: location.point,
      accuracyMetres: location.accuracyMetres,
      age: age,
      sharingUntil: location.sharingUntil,
      metresFromViewer: viewerAt?.metresTo(location.point),
      mode: location.mode,
      place: FamilyPlace.at(location.point, places),
      batteryPercent: location.batteryPercent,
      charging: location.charging,
      motion: location.motion,
    );
  }

  /// How fresh a position has to be to mean *here now* rather than *last seen*.
  /// A sharing device reports at least every 90 seconds while it is moving
  /// (live-location ADR-0001), so anything past two minutes has stopped
  /// arriving rather than stopped moving.
  static const liveWithin = Duration(minutes: 2);

  /// An always-on phone that is still writes once an hour and wakes the moment
  /// it moves, so an hour's silence still means *here*; past that the phone
  /// has stopped, not the person (live-location ADR-0005).
  static const liveWithinAlways = Duration(minutes: 75);

  final Member member;
  final MemberPresence presence;

  /// Null unless this member is sharing — there is nothing to hold on to once
  /// a share ends.
  final Coordinates? at;
  final int? accuracyMetres;
  final Duration? age;

  /// When this share ends, for the person sharing to be told in words rather
  /// than left to remember which button they pressed (live-location ADR-0002).
  final DateTime? sharingUntil;

  final double? metresFromViewer;
  final ShareMode mode;

  /// The household place this member is inside, when they are in one.
  final FamilyPlace? place;
  final int? batteryPercent;
  final bool? charging;
  final DeviceMotion? motion;

  bool get isSomewhere => at != null;

  bool get isSharing =>
      presence == MemberPresence.hereNow || presence == MemberPresence.lastSeen;
}
