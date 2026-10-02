import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// What the app says about itself before anybody has signed in: the nest from
/// the logo with a household's whole week circling it, the wordmark, and the
/// line typing itself out underneath (design-system ADR-0002 for the arrival,
/// ADR-0003 for the brand, ADR-0006 for the turning).
///
/// Three rings, each turning its own way at its own speed:
///
/// * **far** — the people: five member marks in five palette colours, slowly
///   clockwise;
/// * **middle**, dashed — what the app keeps for them: to-dos, sport, the
///   cleaning, places, birthdays and the shopping, twice as fast the other way;
/// * **close**, dotted — five little satellites in the other five palette
///   colours, quickest of all.
///
/// The calendar, the lunchbox and the tick are already in the nest, so they
/// are not repeated. Everything is the app's own avatars, tiles and dots
/// rather than stock illustration, so the first screen is made of the same
/// parts as every screen after it (`ENG-01`).
class SignInWelcome extends StatelessWidget {
  const SignInWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final orbiting = _householdInOrbit();
    return Column(
      children: [
        NestOrbit(
          semanticsLabel: AppCopy.signInOrbitLabel,
          centre: const NestBrandMark(),
          items: orbiting,
          itemExtent: NestSize.avatarMedium,
          spins: true,
        ),
        const SizedBox(height: NestSpace.lg),
        NestRiseIn(
          index: orbiting.length,
          child: const NestWordmark(semanticsLabel: AppCopy.appName),
        ),
        const SizedBox(height: NestSpace.md),
        NestTypewriterText(
          text: AppCopy.signInTagline,
          style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
        ),
      ],
    );
  }

  /// Five palette colours, far enough apart to read as five different people
  /// in both themes.
  static const _memberColors = [
    MemberColor.coral,
    MemberColor.amber,
    MemberColor.teal,
    MemberColor.sky,
    MemberColor.violet,
  ];

  /// The other five, for the satellites, so no dot looks like a person.
  static const _satelliteColors = [
    MemberColor.pink,
    MemberColor.lime,
    MemberColor.mint,
    MemberColor.indigo,
    MemberColor.plum,
  ];

  /// What the household keeps in here, each in its own tint so neighbours
  /// never match.
  static const _things = [
    (Icons.checklist_rounded, NestTileTint.mint),
    (Icons.sports_soccer_rounded, NestTileTint.sky),
    (Icons.cleaning_services_rounded, NestTileTint.peach),
    (Icons.location_on_rounded, NestTileTint.pink),
    (Icons.cake_rounded, NestTileTint.accent),
    (Icons.shopping_basket_rounded, NestTileTint.mint),
  ];

  /// [marks] spread evenly round [ring], the first [offset] of a gap past the
  /// top.
  static List<NestOrbitItem> _round(
    NestOrbitRing ring,
    List<Widget> marks, {
    double offset = 0.5,
  }) => [
    for (final (index, mark) in marks.indexed)
      NestOrbitItem(
        ring: ring,
        turns: (index + offset) / marks.length,
        child: mark,
      ),
  ];

  /// Inside out, which is also the order they arrive in: the satellites, the
  /// things, then the people.
  ///
  /// The member marks carry initials because [NestAvatar] always draws one —
  /// here they are the illustration's letters, not anybody's name, which is
  /// why they are one string in the copy file rather than five invented
  /// people.
  static List<NestOrbitItem> _householdInOrbit() => [
    ..._round(NestOrbitRing.close, [
      for (final color in _satelliteColors) NestDot(color: color),
    ], offset: 0.25),
    ..._round(NestOrbitRing.middle, [
      for (final (icon, tint) in _things)
        NestIconTile(
          icon: icon,
          tint: tint,
          size: NestSize.avatarSmall,
          iconSize: NestSize.iconSmall,
        ),
    ], offset: 0),
    ..._round(NestOrbitRing.far, [
      for (final (index, initial)
          in AppCopy.signInOrbitInitials.characters.indexed)
        NestAvatar(
          name: initial,
          color: _memberColors[index % _memberColors.length],
        ),
    ]),
  ];
}
