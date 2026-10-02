import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../state/household_gate_controller.dart';
import 'create_household_form.dart';
import 'join_household_form.dart';

/// Where an account with no household lands (household ADR-0002). Two ways
/// forward and nothing else, because there is nothing else to do here yet.
///
/// It is the second screen of the way in, so it opens the way the welcome
/// does: the nest and the wordmark, then the question, then the answers, each
/// rising in on the next step and then still (design-system ADR-0002,
/// ADR-0003).
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
      leading: const NestBrandLockup(semanticsLabel: AppCopy.appName),
      trailing: const [AccountMenuButton()],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NestRiseIn(child: _GateWelcome()),
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

/// The step, the question this screen asks and why, short enough to leave
/// the form on the first screenful.
class _GateWelcome extends StatelessWidget {
  const _GateWelcome();

  @override
  Widget build(BuildContext context) {
    return NestIntro(
      eyebrow: AppCopy.onboardingStep(2, AppCopy.stepHousehold),
      title: AppCopy.householdGateTitle,
      body: AppCopy.householdGateBody,
    );
  }
}
