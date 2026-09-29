import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// What the app says about itself before anybody has signed in: the nest from
/// the logo with a household circling it, the wordmark, and the line typing
/// itself out underneath (design-system ADR-0002 for the arrival, ADR-0003 for
/// the brand).
///
/// The nest already holds the week — the calendar at 15, the lunchbox, the
/// tick, the house — so the orbit around it is only the people: five member
/// marks in five palette colours, the household the nest is for. They are the
/// app's own avatars rather than stock illustration, so the first screen is
/// made of the same parts as every screen after it (`ENG-01`).
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
          centre: const NestBrandMark(width: NestSize.brandMarkLarge),
          items: orbiting,
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

  /// Where each member mark sits on the ring: evenly, and never straight up,
  /// where the tick and the heart reach out of the nest. With nothing on an
  /// inner ring to dodge, spacing by formula is safe again (ADR-0002 picked
  /// these by eye only because the tab tiles sat inside them).
  static double _turnsFor(int index, int count) => (index + 0.5) / count;

  /// Five palette colours, far enough apart to read as five different people
  /// in both themes.
  static const _memberColors = [
    MemberColor.coral,
    MemberColor.amber,
    MemberColor.teal,
    MemberColor.sky,
    MemberColor.violet,
  ];

  /// The household, around the nest.
  ///
  /// The marks carry initials because [NestAvatar] always draws one — here
  /// they are the illustration's letters, not anybody's name, which is why
  /// they are one string in the copy file rather than five invented people.
  static List<NestOrbitItem> _householdInOrbit() {
    final initials = AppCopy.signInOrbitInitials.characters.toList();
    return [
      for (final (index, initial) in initials.indexed)
        NestOrbitItem(
          ring: NestOrbitRing.outer,
          turns: _turnsFor(index, initials.length),
          child: NestAvatar(name: initial, color: _memberColors[index]),
        ),
    ];
  }
}
