import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../data/street_names.dart';
import '../model/coordinates.dart';
import '../model/located_member.dart';
import '../model/member_location.dart';

/// One person, and the honest version of what is known about where they are:
/// a position is never shown without its age (live-location ADR-0002).
class LocatedMemberRow extends StatelessWidget {
  const LocatedMemberRow({required this.located, this.onTap, super.key});

  final LocatedMember located;
  final VoidCallback? onTap;

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
      subtitle: _status,
      footer: located.isSomewhere ? _Where(located: located) : null,
      onTap: onTap,
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

  String get _status {
    final parts = [
      switch (located.presence) {
        MemberPresence.hasNotJoined => AppCopy.householdUnclaimed,
        MemberPresence.notSharing => LocationCopy.notSharing,
        MemberPresence.hereNow => LocationCopy.hereNow,
        MemberPresence.lastSeen => _howLongAgo,
      },
      if (located.isSomewhere) ...[
        if (located.motion case final motion?
            when motion != DeviceMotion.unknown)
          LocationCopy.motion(motion),
        if (located.batteryPercent case final battery?)
          LocationCopy.battery(battery, charging: located.charging ?? false),
        if (located.accuracyMetres case final accuracy?)
          AppCopy.withinMetres(accuracy),
      ],
    ];
    return parts.join(' · ');
  }

  String get _howLongAgo {
    final age = located.age;
    return age == null
        ? LocationCopy.lastSeen
        : '${LocationCopy.lastSeen} ${NestDates.ago(age)}';
  }
}

class _Where extends StatelessWidget {
  const _Where({required this.located});

  final LocatedMember located;

  @override
  Widget build(BuildContext context) {
    final style = NestTheme.of(context).text.caption;
    final place = located.place;
    if (place != null) {
      return Text(LocationCopy.atPlace(place.name), style: style);
    }
    final at = located.at!;
    final names = context.read<StreetNames?>();
    if (names == null) return Text(_coordinates(at), style: style);
    return FutureBuilder<String?>(
      future: names.near(at),
      builder: (context, street) => Text(
        street.data == null
            ? _coordinates(at)
            : '${LocationCopy.near} ${street.data}',
        style: style,
      ),
    );
  }

  static String _coordinates(Coordinates at) =>
      '${at.latitude.toStringAsFixed(4)}, ${at.longitude.toStringAsFixed(4)}';
}
