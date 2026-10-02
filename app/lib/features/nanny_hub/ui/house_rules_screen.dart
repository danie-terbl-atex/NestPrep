import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/house_rule.dart';
import '../state/nanny_hub_controller.dart';
import 'hub_empty_note.dart';
import 'nanny_hub_page.dart';
import 'rule_sheet.dart';

/// What goes in this house, in the order the parents wrote them.
class HouseRulesScreen extends StatelessWidget {
  const HouseRulesScreen({super.key});

  static Future<void> _edit(
    BuildContext context,
    NannyHubController controller, [
    HouseRule? rule,
  ]) async {
    final outcome = await showRuleSheet(context: context, existing: rule);
    if (outcome == null) return;
    if (rule == null) {
      await controller.edit.addRule(outcome.text);
    } else if (outcome.isRemoval) {
      await controller.edit.removeRule(rule.id);
    } else {
      await controller.edit.updateRule(rule.id, outcome.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NannyHubController>();
    final canEdit = controller.access.canEdit;
    final nest = NestTheme.of(context);
    return NannyHubPage(
      title: NannyCopy.houseRules,
      floatingAction: canEdit
          ? NestButton(
              label: NannyCopy.addRule,
              icon: LucideIcons.plus,
              isExpanded: false,
              onPressed: () => _edit(context, controller),
            )
          : null,
      builder: (context, view) => ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          if (view.hub.rules.isEmpty)
            HubEmptyNote(
              icon: LucideIcons.gavel,
              title: NannyCopy.rulesEmptyTitle,
              message: canEdit
                  ? NannyCopy.rulesEmptyBody
                  : NannyCopy.rulesEmptyCarer,
            ),
          for (final rule in view.hub.rules)
            Padding(
              key: ValueKey(rule.id),
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: NestCard(
                variant: NestCardVariant.flat,
                padding: EdgeInsets.zero,
                child: NestListRow(
                  leading: const NestIconTile(
                    icon: LucideIcons.circleCheck,
                    tint: NestTileTint.basil,
                    size: NestSize.avatarMedium,
                    iconSize: NestSize.iconMedium,
                  ),
                  title: rule.text,
                  titleStyle: nest.text.bodyStrong,
                  onTap: canEdit
                      ? () => _edit(context, controller, rule)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
