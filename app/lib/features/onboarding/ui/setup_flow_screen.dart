import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../model/onboarding_step.dart';
import '../state/setup_flow_controller.dart';
import 'setup_calendar_panel.dart';
import 'setup_family_panel.dart';
import 'setup_ready_panel.dart';

/// A new household's setup step (onboarding ADR-0001): family, calendar, and
/// the payoff, under the bar the rest of the way in shares, with the waves
/// behind (design-system ADR-0026). The screen only composes; each panel is
/// its own.
class SetupFlowScreen extends StatelessWidget {
  const SetupFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<SetupFlowController>();
    final step = flow.step;
    return NestScaffold(
      backdrop: const NestWaves(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestStepsBar(count: step.count, index: step.index, label: step.label),
          const SizedBox(height: NestSpace.xl),
          Expanded(
            child: NestTwigWarmUp(
              child: AnimatedSwitcher(
                duration: NestMotion.of(context).standard,
                child: KeyedSubtree(
                  key: ValueKey(flow.panel),
                  child: switch (flow.panel) {
                    SetupPanel.family => const SetupFamilyPanel(),
                    SetupPanel.calendar => const SetupCalendarPanel(),
                    SetupPanel.ready => const SetupReadyPanel(),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
