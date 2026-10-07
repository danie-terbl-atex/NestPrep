import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/nest_date_field.dart';
import '../../household/model/member.dart';
import '../model/nanny_limits.dart';
import '../model/nanny_pickups.dart';
import '../model/pickup_change.dart';
import '../model/pickup_collector.dart';
import '../model/pickup_drafts.dart';
import 'collector_choice.dart';
import 'pickup_time_choice.dart';

/// What the change sheet decided: one day's exception, or — for one that
/// exists — to remove it. Null means closed.
typedef PickupChangeOutcome = ({PickupChangeDraft draft, bool isRemoval});

/// A change for one child on one day: somebody else collects, at another
/// time, or nobody does. Never before today — the past is not a plan.
/// Save waits for a child and a collector (`FE-10`).
Future<PickupChangeOutcome?> showPickupChangeSheet({
  required BuildContext context,
  required List<Member> children,
  required List<Member> adults,
  required NannyPickups pickups,
  required CalendarDate today,
  PickupChange? existing,
}) => showNestSheet<PickupChangeOutcome>(
  context: context,
  title: existing == null
      ? NannyPickupCopy.changeTitle
      : NannyPickupCopy.editChange,
  builder: (_) => _ChangeBody(
    children: children,
    adults: adults,
    pickups: pickups,
    today: today,
    existing: existing,
  ),
);

class _ChangeBody extends StatefulWidget {
  const _ChangeBody({
    required this.children,
    required this.adults,
    required this.pickups,
    required this.today,
    required this.existing,
  });

  final List<Member> children;
  final List<Member> adults;
  final NannyPickups pickups;
  final CalendarDate today;
  final PickupChange? existing;

  @override
  State<_ChangeBody> createState() => _ChangeBodyState();
}

class _ChangeBodyState extends State<_ChangeBody> {
  late String? _childId =
      widget.existing?.childId ??
      (widget.children.length == 1 ? widget.children.single.id : null);
  late CalendarDate _date = widget.existing?.date ?? widget.today;
  late PickupCollector? _collector = widget.existing?.collector;
  late int? _atMinute = widget.existing?.atMinute;
  late final _note = TextEditingController(text: widget.existing?.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _pickChild(String childId) => setState(() {
    _childId = childId;
    // Somebody listed for the other child may not be for this one.
    if (_collector case CollectedByPerson(
      :final id,
    ) when !(widget.pickups.personById(id)?.mayCollect(childId) ?? false)) {
      _collector = null;
    }
  });

  void _finish({required bool isRemoval}) {
    final childId = _childId;
    final collector = _collector;
    if (childId == null || collector == null) return;
    Navigator.of(context).pop((
      draft: (
        childId: childId,
        date: _date,
        collector: collector,
        atMinute: _atMinute,
        note: _note.text,
      ),
      isRemoval: isRemoval,
    ));
  }

  Future<void> _remove() async {
    final confirmed = await showNestConfirm(
      context: context,
      title: NannyPickupCopy.removeChangeConfirm,
      confirmLabel: NannyCopy.delete,
      cancelLabel: NannyCopy.cancel,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    _finish(isRemoval: true);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final childId = _childId;
    final isExisting = widget.existing != null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            NannyPickupCopy.whichChild,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final child in widget.children)
                NestChip(
                  label: child.displayName,
                  isSelected: child.id == childId,
                  icon: child.id == childId ? LucideIcons.check : null,
                  // A change is keyed by its child and day; moving it is a
                  // new change, so an existing one keeps both.
                  onTap: isExisting ? null : () => _pickChild(child.id),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          if (!isExisting) ...[
            NestDateField(
              label: NannyPickupCopy.date,
              value: _date,
              today: widget.today,
              yearsAhead: 1,
              onChanged: (date) => setState(
                () => _date = date.isBefore(widget.today) ? widget.today : date,
              ),
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          CollectorChoice(
            people: childId == null
                ? const []
                : widget.pickups.allowedFor(childId),
            adults: widget.adults,
            chosen: _collector,
            allowsNobody: true,
            onChanged: (value) => setState(() => _collector = value),
          ),
          const SizedBox(height: NestSpace.lg),
          PickupTimeChoice(
            atMinute: _atMinute,
            onChanged: (value) => setState(() => _atMinute = value),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyPickupCopy.note,
            hint: NannyPickupCopy.noteHint,
            controller: _note,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.pickupChangeNote),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyCopy.save,
            onPressed: childId == null || _collector == null
                ? null
                : () => _finish(isRemoval: false),
          ),
          if (isExisting) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: NannyCopy.delete,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.trash2,
              onPressed: _remove,
            ),
          ],
        ],
      ),
    );
  }
}
