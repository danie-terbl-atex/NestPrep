import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/child_in_care.dart';
import '../state/nanny_hub_controller.dart';
import 'care_notes_section.dart';
import 'child_card_edits.dart';
import 'child_header.dart';
import 'child_safety_section.dart';
import 'comfort_section.dart';
import 'likes_section.dart';
import 'routine_section.dart';

/// Everything on a child's card once the hub has loaded. Safety comes before
/// anything else — allergies, then medication — on every card, for every
/// viewer, because that is the order it matters in.
class ChildCardBody extends StatelessWidget {
  const ChildCardBody({
    required this.child,
    required this.controller,
    super.key,
  });

  final ChildInCare child;
  final NannyHubController controller;

  @override
  Widget build(BuildContext context) {
    final access = controller.access;
    final canEdit = access.canEdit;
    final card = child.card;
    final edits = ChildCardEdits(controller: controller, child: child);
    final today = context.read<HouseholdClock>().today;
    final sections = <Widget>[
      ChildHeader(
        child: child,
        age: child.member.birthday?.ageOn(today),
        onChangePhoto: canEdit ? () => edits.changePhoto(context) : null,
      ),
      ChildSafetySection(
        food: child.food,
        health: controller.healthOf(child.memberId),
        onRetry: controller.retry,
      ),
      RoutineSection(
        routines: card.routinesInOrder,
        onEdit: canEdit ? () => edits.editRoutine(context) : null,
      ),
      LikesSection(food: child.food),
      ComfortSection(
        items: card.comfortItems,
        onEdit: canEdit ? () => edits.editComfort(context) : null,
      ),
      CareNotesSection(
        settling: card.settling,
        goodToKnow: card.goodToKnow,
        onEdit: canEdit ? () => edits.editCareNotes(context) : null,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final (index, section) in sections.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: NestRiseIn(index: index, child: section),
          ),
        if (!canEdit)
          Text(
            NannyCopy.viewOnlyNote,
            style: NestTheme.of(context).text.caption,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
