import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';
import '../model/nanny_limits.dart';
import '../model/pickup_collector.dart';
import '../model/pickup_drafts.dart';
import '../model/pickup_person.dart';
import '../model/school_run.dart';
import 'collector_choice.dart';
import 'pickup_time_choice.dart';

/// What the run sheet decided: the usual collection for one child on one
/// weekday, or — for a day already set — to clear it. Null means closed.
typedef SchoolRunOutcome = ({SchoolRunDraft draft, bool isRemoval});

/// Sets who collects [child] every [weekday], when and where. Save waits for
/// a collector (`FE-10`).
Future<SchoolRunOutcome?> showSchoolRunSheet({
  required BuildContext context,
  required Member child,
  required int weekday,
  required List<PickupPerson> people,
  required List<Member> adults,
  SchoolRun? existing,
}) => showNestSheet<SchoolRunOutcome>(
  context: context,
  title: NannyPickupCopy.runTitle(child.displayName, weekday),
  builder: (_) => _RunBody(
    child: child,
    weekday: weekday,
    people: people,
    adults: adults,
    existing: existing,
  ),
);

class _RunBody extends StatefulWidget {
  const _RunBody({
    required this.child,
    required this.weekday,
    required this.people,
    required this.adults,
    required this.existing,
  });

  final Member child;
  final int weekday;
  final List<PickupPerson> people;
  final List<Member> adults;
  final SchoolRun? existing;

  @override
  State<_RunBody> createState() => _RunBodyState();
}

class _RunBodyState extends State<_RunBody> {
  late PickupCollector? _collector = widget.existing?.collector;
  late int? _atMinute = widget.existing?.atMinute;
  late final _place = TextEditingController(text: widget.existing?.place);

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  void _finish(PickupCollector collector, {required bool isRemoval}) =>
      Navigator.of(context).pop((
        draft: (
          childId: widget.child.id,
          weekday: widget.weekday,
          collector: collector,
          atMinute: _atMinute,
          place: _place.text,
        ),
        isRemoval: isRemoval,
      ));

  @override
  Widget build(BuildContext context) {
    final collector = _collector;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CollectorChoice(
            people: widget.people,
            adults: widget.adults,
            chosen: collector,
            onChanged: (value) => setState(() => _collector = value),
          ),
          const SizedBox(height: NestSpace.lg),
          PickupTimeChoice(
            atMinute: _atMinute,
            onChanged: (value) => setState(() => _atMinute = value),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyPickupCopy.placeLabel,
            hint: NannyPickupCopy.placeHint,
            controller: _place,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.schoolRunPlace),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyCopy.save,
            onPressed: collector == null
                ? null
                : () => _finish(collector, isRemoval: false),
          ),
          if (widget.existing case final existing?) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: NannyPickupCopy.removeRun,
              variant: NestButtonVariant.ghost,
              icon: Icons.delete_outline,
              onPressed: () => _finish(existing.collector, isRemoval: true),
            ),
          ],
        ],
      ),
    );
  }
}
