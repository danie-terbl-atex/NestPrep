import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// What the app says about itself before anybody has signed in: the nest mark
/// with a household's week circling it, the name, and the line typing itself
/// out underneath.
///
/// The things in orbit are the app's own furniture — the four tabs' icon tiles
/// and five member marks in five palette colours — rather than stock
/// illustration, so the first screen is made of the same parts as every screen
/// after it (`ENG-01`).
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
          centre: const NestIconTile(
            icon: Icons.home_rounded,
            size: NestSize.mark,
            iconSize: NestSize.iconMark,
          ),
          items: orbiting,
        ),
        const SizedBox(height: NestSpace.xl),
        NestRiseIn(
          index: orbiting.length,
          child: Text(
            AppCopy.appName,
            style: nest.text.display.copyWith(color: nest.colors.ink),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: NestSpace.sm),
        NestTypewriterText(
          text: AppCopy.signInTagline,
          style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
        ),
      ],
    );
  }

  /// The four things the app is for, on the inner ring.
  static const _theWeek = [
    NestOrbitItem(
      ring: NestOrbitRing.inner,
      turns: 0.06,
      child: NestIconTile(icon: Icons.calendar_month_outlined),
    ),
    NestOrbitItem(
      ring: NestOrbitRing.inner,
      turns: 0.31,
      child: NestIconTile(
        icon: Icons.checklist_outlined,
        tint: NestTileTint.mint,
      ),
    ),
    NestOrbitItem(
      ring: NestOrbitRing.inner,
      turns: 0.56,
      child: NestIconTile(
        icon: Icons.restaurant_outlined,
        tint: NestTileTint.peach,
      ),
    ),
    NestOrbitItem(
      ring: NestOrbitRing.inner,
      turns: 0.81,
      child: NestIconTile(
        icon: Icons.shopping_basket_outlined,
        tint: NestTileTint.sky,
      ),
    ),
  ];

  /// Where each member mark sits on the outer ring.
  ///
  /// Four of them sit on the spokes *between* the tiles inside them, because
  /// the two rings are only about one item apart: put a mark on the same
  /// bearing as a tile and the two overlap however good the arithmetic looks.
  /// The fifth takes the widest gap left over.
  static const _memberTurns = [0.185, 0.435, 0.685, 0.875, 0.985];

  /// Five palette colours, far enough apart to read as five different people
  /// in both themes.
  static const _memberColors = [
    MemberColor.violet,
    MemberColor.coral,
    MemberColor.amber,
    MemberColor.teal,
    MemberColor.sky,
  ];

  /// The picture: the week on the inside, the household on the outside.
  ///
  /// The marks carry initials because [NestAvatar] always draws one — here
  /// they are the illustration's letters, not anybody's name, which is why
  /// they are one string in the copy file rather than five invented people.
  static List<NestOrbitItem> _householdInOrbit() => [
    ..._theWeek,
    for (final (index, initial)
        in AppCopy.signInOrbitInitials.characters.indexed)
      NestOrbitItem(
        ring: NestOrbitRing.outer,
        turns: _memberTurns[index],
        child: NestAvatar(name: initial, color: _memberColors[index]),
      ),
  ];
}
