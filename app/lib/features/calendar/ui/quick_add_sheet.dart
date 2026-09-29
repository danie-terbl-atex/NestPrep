import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/quick_add_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../model/quick_add/quick_add_parser.dart';
import '../model/quick_add/quick_add_result.dart';
import 'quick_add_preview.dart';

/// What the member chose in the quick-add sheet.
sealed class QuickAddChoice {
  const QuickAddChoice(this.proposal);

  final QuickAddProposal proposal;
}

/// Add it as understood.
final class QuickAddConfirmed extends QuickAddChoice {
  const QuickAddConfirmed(super.proposal);
}

/// Open it in the full event sheet first.
final class QuickAddToEdit extends QuickAddChoice {
  const QuickAddToEdit(super.proposal);
}

/// Type a line — "Soccer Tuesdays at 5" — and see, live, the event it will
/// make before anything is saved (calendar ADR-0004). The sheet only reads
/// and proposes; saving is the screen's, through its controller.
Future<QuickAddChoice?> showQuickAddSheet({
  required BuildContext context,
  required CalendarDate today,
  required List<Member> members,
}) => showNestSheet<QuickAddChoice>(
  context: context,
  title: QuickAddCopy.label,
  builder: (sheetContext) => _QuickAddPanel(today: today, members: members),
);

class _QuickAddPanel extends StatefulWidget {
  const _QuickAddPanel({required this.today, required this.members});

  final CalendarDate today;
  final List<Member> members;

  @override
  State<_QuickAddPanel> createState() => _QuickAddPanelState();
}

class _QuickAddPanelState extends State<_QuickAddPanel> {
  final _text = TextEditingController();

  /// What was typed is this widget's own state (`FE-07`); what it means is the
  /// parser's, a pure function of the household's today and members (`FE-04`).
  QuickAddResult? _result;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _read(String text) {
    setState(() {
      _result = text.trim().isEmpty
          ? null
          : parseQuickAdd(
              text,
              today: widget.today,
              members: [
                for (final member in widget.members)
                  QuickAddMember(id: member.id, name: member.displayName),
              ],
            );
    });
  }

  void _choose(QuickAddChoice choice) => Navigator.of(context).pop(choice);

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final result = _result;
    return SingleChildScrollView(
      child: AnimatedSize(
        duration: NestMotion.of(context).standard,
        curve: NestMotion.standardCurve,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            NestTextField(
              label: QuickAddCopy.fieldLabel,
              hint: QuickAddCopy.hint,
              controller: _text,
              autofocus: true,
              prefixIcon: Icons.auto_awesome_outlined,
              textInputAction: TextInputAction.done,
              onChanged: _read,
              onSubmitted: (_) {
                if (result is QuickAddProposal) {
                  _choose(QuickAddConfirmed(result));
                }
              },
            ),
            const SizedBox(height: NestSpace.lg),
            switch (result) {
              QuickAddProposal() => NestCard(
                variant: NestCardVariant.tinted,
                padding: const EdgeInsets.all(NestSpace.lg),
                child: QuickAddPreview(
                  proposal: result,
                  today: widget.today,
                  members: [
                    for (final member in widget.members)
                      if (result.memberIds.contains(member.id)) member,
                  ],
                  onAdd: () => _choose(QuickAddConfirmed(result)),
                  onEdit: () => _choose(QuickAddToEdit(result)),
                ),
              ),
              _ => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: NestSize.iconSmall,
                    color: nest.colors.inkTertiary,
                  ),
                  const SizedBox(width: NestSpace.sm),
                  Expanded(
                    child: Text(
                      QuickAddCopy.problem(switch (result) {
                        QuickAddRefusal(:final problem) => problem,
                        _ => QuickAddProblem.empty,
                      }),
                      style: nest.text.caption.copyWith(
                        color: nest.colors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}
