import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/ui/family_section_card.dart';
import '../../family_profiles/ui/family_section_empty.dart';
import '../model/shift_checklist.dart';
import '../model/shift_moment.dart';
import '../state/nanny_hub_controller.dart';
import 'checklist_sheet.dart';
import 'moment_look.dart';
import 'nanny_hub_page.dart';

/// What to do at each of the five parts of a shift, as the parents wrote it.
/// Ticking happens in shift mode, on the shift; this is the list itself
/// (nanny-hub ADR-0001).
class ChecklistsScreen extends StatelessWidget {
  const ChecklistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NannyHubController>();
    final canEdit = controller.access.canEdit;
    return NannyHubPage(
      title: NannyCopy.checklists,
      builder: (context, view) => ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          Text(
            NannyCopy.checklistsIntro,
            style: NestTheme.of(context).text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.lg),
          for (final checklist in view.hub.checklists)
            if (checklist.moment case final moment?)
              Padding(
                key: ValueKey(moment),
                padding: const EdgeInsets.only(bottom: NestSpace.lg),
                child: _ChecklistCard(
                  moment: moment,
                  checklist: checklist,
                  onEdit: canEdit
                      ? () => _edit(context, controller, moment, checklist)
                      : null,
                ),
              ),
        ],
      ),
    );
  }

  static Future<void> _edit(
    BuildContext context,
    NannyHubController controller,
    ShiftMoment moment,
    ShiftChecklist checklist,
  ) async {
    final items = await showChecklistSheet(
      context: context,
      moment: moment,
      items: checklist.items,
    );
    if (items == null) return;
    await controller.edit.saveChecklist(moment, items);
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.moment,
    required this.checklist,
    required this.onEdit,
  });

  final ShiftMoment moment;
  final ShiftChecklist checklist;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return FamilySectionCard(
      icon: moment.icon,
      tint: moment.tint,
      title: NannyCopy.momentName(moment),
      actionLabel: NannyCopy.editChecklist(moment),
      onAction: onEdit,
      child: checklist.items.isEmpty
          ? const FamilySectionEmpty(message: NannyCopy.noChecklistItems)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in checklist.items)
                  Padding(
                    key: ValueKey(item.id),
                    padding: const EdgeInsets.only(bottom: NestSpace.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.circle,
                          size: NestSize.iconSmall,
                          color: nest.colors.inkTertiary,
                        ),
                        const SizedBox(width: NestSpace.sm),
                        Expanded(child: Text(item.text, style: nest.text.body)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
