import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// A side action on a proposal — *usually in the house* — kept its own
/// control so it never merges into the line it sits beside.
typedef GroceryRowAction = ({
  IconData icon,
  String label,
  VoidCallback onPressed,
});

/// One line of *From this week's plans*: the name and how much, why the plans
/// want it, and what would happen to it (groceries ADR-0002, ADR-0003).
///
/// With [isTicked] it is a choice — the whole line toggles it, and it reads
/// to a screen reader as one checkable thing; without, it is information.
class GroceryProposalRow extends StatelessWidget {
  const GroceryProposalRow({
    required this.name,
    required this.detail,
    this.quantity,
    this.status,
    this.isTicked,
    this.onToggle,
    this.action,
    super.key,
  });

  final String name;
  final String? quantity;

  /// Why — *For 5 lunches + Tuesday dinner*.
  final String detail;

  /// What would change — *Now 2 loaves*, *Bought yesterday — add again?*.
  final String? status;

  /// Null for a line that is not a choice.
  final bool? isTicked;
  final VoidCallback? onToggle;
  final GroceryRowAction? action;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ticked = isTicked;
    final side = action;
    final line = status;
    return Row(
      children: [
        Expanded(
          child: MergeSemantics(
            child: InkWell(
              borderRadius: BorderRadius.circular(NestRadius.lg),
              onTap: ticked == null ? null : onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
                child: Row(
                  children: [
                    if (ticked != null)
                      Checkbox(
                        value: ticked,
                        onChanged: onToggle == null ? null : (_) => onToggle!(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(NestSpace.md),
                        child: Icon(
                          Icons.check_rounded,
                          size: NestSize.iconSmall,
                          color: nest.colors.success,
                        ),
                      ),
                    const SizedBox(width: NestSpace.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: name,
                              style: nest.text.bodyStrong,
                              children: [
                                if (quantity case final amount?)
                                  TextSpan(
                                    text: '  ·  $amount',
                                    style: nest.text.body.copyWith(
                                      color: nest.colors.accentInk,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(detail, style: nest.text.caption),
                          if (line != null)
                            Text(
                              line,
                              style: nest.text.label.copyWith(
                                color: nest.colors.accentInk,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (side != null)
          NestIconButton(
            icon: side.icon,
            label: side.label,
            variant: NestIconButtonVariant.plain,
            onPressed: side.onPressed,
          ),
      ],
    );
  }
}
