import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// What the app says about itself before anybody has signed in: the mark
/// with a household's whole week circling it, the wordmark, and the tagline
/// (design-system ADR-0006, ADR-0011).
///
/// Three rings, each turning its own way at its own speed:
///
/// * **far** — the people: five member marks in five palette colours, slowly
///   clockwise;
/// * **middle**, dashed — what the app keeps for them: to-dos, sport, the
///   cleaning, places, birthdays and the shopping, twice as fast the other way;
/// * **close**, dotted — five little satellites in the other five palette
///   colours, quickest of all.
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
          centre: const NestBrandMark(size: NestSize.brandMarkLarge),
          items: orbiting,
          itemExtent: NestSize.avatarMedium,
          spins: true,
        ),
        const SizedBox(height: NestSpace.lg),
        const NestRiseIn(
          index: 1,
          child: NestWordmark(semanticsLabel: AppCopy.appName),
        ),
        const SizedBox(height: NestSpace.md),
        NestRiseIn(
          index: 2,
          child: Text(
            AppCopy.signInTagline,
            style: nest.text.bodySecondary,
            textAlign: TextAlign.center,
          ),
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

  static const _things = [
    (LucideIcons.listChecks, NestTileTint.basil),
    (LucideIcons.trophy, NestTileTint.lilac),
    (LucideIcons.sprayCan, NestTileTint.butter),
    (LucideIcons.mapPin, NestTileTint.guava),
    (LucideIcons.cake, NestTileTint.accent),
    (LucideIcons.shoppingBasket, NestTileTint.lilac),
  ];

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

  /// The member marks carry initials because [NestAvatar] always draws one —
  /// they are the illustration's letters, not anybody's name.
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
