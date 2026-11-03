import '../../household/model/member.dart';
import 'family_place.dart';
import 'located_member.dart';
import 'member_location.dart';

/// What the live-location screen renders, derived once per emission rather
/// than in a build method (`FE-12`).
///
/// The person looking is held apart from everybody else. Their own sharing is
/// a control, not a row — it is the one thing on this screen they can change,
/// and it is the only place the app asks anybody for their position
/// (live-location ADR-0002).
class LiveLocationView {
  const LiveLocationView({
    required this.viewer,
    required this.others,
    this.places = const [],
  });

  factory LiveLocationView.from({
    required List<Member> members,
    required List<MemberLocation> locations,
    required String viewerMemberId,
    required DateTime now,
    List<FamilyPlace> places = const [],
  }) {
    final byMember = {for (final location in locations) location.id: location};
    final viewerMember = members
        .where((member) => member.id == viewerMemberId)
        .firstOrNull;
    final viewer = viewerMember == null
        ? null
        : LocatedMember.from(
            member: viewerMember,
            location: byMember[viewerMember.id],
            now: now,
            places: places,
          );

    final others = [
      for (final member in members)
        if (member.id != viewerMemberId)
          LocatedMember.from(
            member: member,
            location: byMember[member.id],
            now: now,
            viewerAt: viewer?.at,
            places: places,
          ),
    ]..sort(_whoMattersFirst);

    return LiveLocationView(viewer: viewer, others: others, places: places);
  }

  /// Null when the signed-in account has claimed no profile here. The household
  /// gate makes that unreachable; a screen that assumed otherwise would crash
  /// rather than say so.
  final LocatedMember? viewer;

  /// Everybody else, whether or not they are sharing. Somebody who is not
  /// sharing is shown saying so: a household that could not tell *not sharing*
  /// from *not here* would read silence as an answer.
  final List<LocatedMember> others;
  final List<FamilyPlace> places;

  /// Everybody with a position to draw, the viewer included.
  List<LocatedMember> get onTheMap => [
    if (viewer case final viewer? when viewer.isSomewhere) viewer,
    for (final located in others)
      if (located.isSomewhere) located,
  ];

  /// A household of one. Nobody is hidden by this — there is nobody else.
  bool get isEmpty => others.isEmpty;

  /// Whoever is findable, first. Within a group, the order the household
  /// screen uses, so the same people are not in a different order here.
  static int _whoMattersFirst(LocatedMember a, LocatedMember b) {
    final byPresence = a.presence.index.compareTo(b.presence.index);
    if (byPresence != 0) return byPresence;
    return a.member.displayName.toLowerCase().compareTo(
      b.member.displayName.toLowerCase(),
    );
  }
}
