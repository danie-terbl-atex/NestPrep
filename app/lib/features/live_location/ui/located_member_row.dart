import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/coordinates.dart';
import '../model/located_member.dart';

/// One person, and the honest version of what is known about where they are.
///
/// The age is never left off a position that has one. *Here now* and *last seen
/// 24 minutes ago* are two different facts, and drawing the second as the first
/// is the thing that makes a feature like this dangerous rather than useful
/// (live-location ADR-0002).
class LocatedMemberRow extends StatelessWidget {
  const LocatedMemberRow({required this.located, super.key});

  final LocatedMember located;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final metres = located.metresFromViewer;
    return NestListRow(
      leading: NestAvatar(
        name: located.member.displayName,
        color: located.member.color,
      ),
      title: located.member.displayName,
      subtitle: _subtitle,
      trailing: metres == null
          ? null
          : Text(
              AppCopy.distanceAway(metres),
              style: nest.text.caption.copyWith(
                color: nest.colors.inkSecondary,
              ),
            ),
    );
  }

  String get _subtitle {
    final at = located.at;
    final status = switch (located.presence) {
      MemberPresence.hasNotJoined => AppCopy.householdUnclaimed,
      MemberPresence.notSharing => AppCopy.locationNotSharing,
      MemberPresence.hereNow => '${AppCopy.locationHereNow}$_howSure',
      MemberPresence.lastSeen => '$_howLongAgo$_howSure',
    };
    return at == null ? status : '$status\n${_coordinates(at)}';
  }

  String get _howLongAgo {
    final age = located.age;
    return age == null
        ? AppCopy.locationLastSeen
        : '${AppCopy.locationLastSeen} ${NestDates.ago(age)}';
  }

  String get _howSure {
    final accuracy = located.accuracyMetres;
    return accuracy == null ? '' : ' \u00b7 ${AppCopy.withinMetres(accuracy)}';
  }

  /// Four decimal places is about eleven metres, which is finer than anything
  /// this feature claims to know. There is no map in phase 1, so this is what
  /// a person can act on: read it out, or paste it somewhere that draws maps
  /// (live-location ADR-0001).
  static String _coordinates(Coordinates at) =>
      '${at.latitude.toStringAsFixed(4)}, '
      '${at.longitude.toStringAsFixed(4)}';
}
