import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../model/onboarding_step.dart';

/// The top of every step on the way in (onboarding ADR-0001): how far along
/// the person is, Twig with one short line, then the step's question
/// (design-system ADR-0026). Twig acts on arrival and again whenever
/// [twigActionKey] changes, which is how a step reacts to what was just done.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    required this.title,
    required this.twigPose,
    required this.twigLine,
    this.step,
    this.body,
    this.twigAction = NestTwigAction.arrive,
    this.twigActionKey,
    super.key,
  });

  /// Null where the screen is not a step of a way in (a consent asked again
  /// after an update): no bar.
  final OnboardingStep? step;
  final String title;
  final String? body;
  final NestTwigPose twigPose;
  final String twigLine;
  final NestTwigAction twigAction;
  final Object? twigActionKey;

  @override
  Widget build(BuildContext context) {
    final step = this.step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (step != null) ...[
          NestStepsBar(count: step.count, index: step.index, label: step.label),
          const SizedBox(height: NestSpace.xl),
        ],
        Row(
          children: [
            NestTwig(
              pose: twigPose,
              size: NestSize.twigLarge,
              action: twigAction,
              actionKey: twigActionKey,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: NestRiseIn(
                child: AnimatedSwitcher(
                  duration: NestMotion.of(context).standard,
                  child: NestSaying(twigLine, key: ValueKey(twigLine)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: NestSpace.xl),
        NestRiseIn(
          index: 1,
          child: NestIntro(title: title, body: body),
        ),
      ],
    );
  }
}
