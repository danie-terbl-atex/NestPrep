import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../onboarding/model/onboarding_step.dart';
import '../../onboarding/ui/onboarding_header.dart';
import '../state/household_gate_controller.dart';
import 'create_household_form.dart';
import 'join_household_form.dart';

/// Where an account with no household lands (household ADR-0002). Two ways
/// forward and nothing else, because there is nothing else to do here yet.
///
/// It is the third step of the creator's way in (onboarding ADR-0001): the
/// bar and Twig, then the question, then the answers, each rising in on the
/// next beat and then still (design-system ADR-0002, ADR-0026).
class HouseholdGateScreen extends StatefulWidget {
  const HouseholdGateScreen({super.key});

  static const path = '/households';

  @override
  State<HouseholdGateScreen> createState() => _HouseholdGateScreenState();
}

class _HouseholdGateScreenState extends State<HouseholdGateScreen> {
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HouseholdGateController>();
    final failure = controller.failure;
    final motion = NestMotion.of(context);
    return NestScaffold(
      backdrop: const NestWaves(),
      leading: const NestBrandLockup(semanticsLabel: AppCopy.appName),
      trailing: const [AccountMenuButton()],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _GateWelcome(),
            const SizedBox(height: NestSpace.xxl),
            if (failure != null) ...[
              NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
              ),
              const SizedBox(height: NestSpace.lg),
            ],
            // The two ways forward arrive after the question they answer, the
            // same entrance the sign-in screen uses, so creating a household
            // reads as the next beat of one flow rather than a new app.
            NestRiseIn(
              index: 2,
              child: Row(
                children: [
                  Expanded(
                    child: NestChip(
                      label: AppCopy.householdCreate,
                      isSelected: !_isJoining,
                      onTap: () => _switchTo(isJoining: false),
                    ),
                  ),
                  const SizedBox(width: NestSpace.sm),
                  Expanded(
                    child: NestChip(
                      label: AppCopy.householdJoin,
                      isSelected: _isJoining,
                      onTap: () => _switchTo(isJoining: true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NestSpace.xl),
            NestRiseIn(
              index: 3,
              child: NestCard(
                child: AnimatedSize(
                  duration: motion.standard,
                  curve: NestMotion.standardCurve,
                  alignment: Alignment.topCenter,
                  child: _isJoining
                      ? const JoinHouseholdForm()
                      : const CreateHouseholdForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchTo({required bool isJoining}) {
    if (_isJoining == isJoining) return;
    context.read<HouseholdGateController>().dismissFailure();
    setState(() => _isJoining = isJoining);
  }
}

/// The step, Twig, and the question this screen asks and why, short enough
/// to leave the form on the first screenful.
class _GateWelcome extends StatelessWidget {
  const _GateWelcome();

  @override
  Widget build(BuildContext context) {
    return const OnboardingHeader(
      step: CreatorStep.household,
      title: AppCopy.householdGateTitle,
      body: AppCopy.householdGateBody,
      twigPose: NestTwigPose.planning,
      twigLine: OnboardingCopy.twigHousehold,
    );
  }
}
