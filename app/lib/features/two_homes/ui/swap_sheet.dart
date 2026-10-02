import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/nest_date_field.dart';
import '../model/change_request.dart';
import '../model/co_parent_link.dart';
import '../model/custody_side.dart';

/// What a swap asks for, once the sheet closes with it.
typedef SwapAsk = ({
  CalendarDate from,
  CalendarDate to,
  CustodySide toSide,
  String note,
});

/// Asking the other home for a swap (household ADR-0004): the days, which
/// home would have the child, and a note if there is one. It is only ever a
/// question — nothing moves until the other home answers.
Future<SwapAsk?> showSwapSheet({
  required BuildContext context,
  required CoParentLink link,
  required CalendarDate today,
}) => showNestSheet<SwapAsk>(
  context: context,
  title: TwoHomesCopy.swapTitle,
  builder: (_) => _SwapSheetBody(link: link, today: today),
);

class _SwapSheetBody extends StatefulWidget {
  const _SwapSheetBody({required this.link, required this.today});

  final CoParentLink link;
  final CalendarDate today;

  @override
  State<_SwapSheetBody> createState() => _SwapSheetBodyState();
}

class _SwapSheetBodyState extends State<_SwapSheetBody> {
  late CalendarDate _from = widget.today.addDays(1);
  late CalendarDate _to = _from;

  /// Asking for the child is the usual swap, so this home is offered first.
  late CustodySide _toSide = widget.link.ownSide;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String? get _problem {
    final days = _from.daysUntil(_to) + 1;
    if (days < 1) return TwoHomesCopy.swapEndsBeforeStart;
    if (days > ChangeRequest.maxSwapDays) {
      return TwoHomesCopy.swapTooLong(ChangeRequest.maxSwapDays);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final problem = _problem;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestDateField(
            label: TwoHomesCopy.swapFrom,
            value: _from,
            today: widget.today,
            yearsAhead: 1,
            onChanged: (date) => setState(() {
              _from = date;
              if (_to.isBefore(date)) _to = date;
            }),
          ),
          const SizedBox(height: NestSpace.md),
          NestDateField(
            label: TwoHomesCopy.swapUntil,
            value: _to,
            today: widget.today,
            yearsAhead: 1,
            onChanged: (date) => setState(() => _to = date),
          ),
          if (problem != null) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              problem,
              style: nest.text.caption.copyWith(color: nest.colors.danger),
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          Text(
            TwoHomesCopy.swapWith,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final side in [widget.link.ownSide, widget.link.otherSide])
                NestChip(
                  label: widget.link.homeOf(side).name,
                  isSelected: _toSide == side,
                  onTap: () => setState(() => _toSide = side),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: TwoHomesCopy.noteLabel,
            hint: TwoHomesCopy.noteHint,
            controller: _note,
            maxLines: 3,
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: TwoHomesCopy.send,
            icon: LucideIcons.send,
            onPressed: problem != null
                ? null
                : () => Navigator.of(context).pop<SwapAsk>((
                    from: _from,
                    to: _to,
                    toSide: _toSide,
                    note: _note.text,
                  )),
          ),
        ],
      ),
    );
  }
}
