import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/child_in_care.dart';
import '../model/photo_change.dart';
import '../state/nanny_hub_controller.dart';
import 'care_notes_sheet.dart';
import 'comfort_sheet.dart';
import 'photo_field.dart';
import 'routine_sheet.dart';

/// The four ways a card changes, each a sheet whose answer goes to the
/// controller. Kept apart from the card's layout so the screen only composes
/// (`FE-16`).
class ChildCardEdits {
  const ChildCardEdits({required this.controller, required this.child});

  final NannyHubController controller;
  final ChildInCare child;

  String get _childId => child.memberId;

  Future<void> editRoutine(BuildContext context) async {
    final routines = await showRoutineSheet(
      context: context,
      routines: child.card.routinesInOrder,
    );
    if (routines == null) return;
    await controller.edit.saveRoutines(_childId, routines);
  }

  Future<void> editComfort(BuildContext context) async {
    final items = await showComfortSheet(
      context: context,
      items: child.card.comfortItems,
    );
    if (items == null) return;
    await controller.edit.saveComfortItems(_childId, items);
  }

  Future<void> editCareNotes(BuildContext context) async {
    final notes = await showCareNotesSheet(
      context: context,
      settling: child.card.settling,
      goodToKnow: child.card.goodToKnow,
    );
    if (notes == null) return;
    await controller.edit.saveCareNotes(
      _childId,
      settling: notes.settling,
      goodToKnow: notes.goodToKnow,
    );
  }

  Future<void> changePhoto(BuildContext context) async {
    PhotoChange change = const PhotoKept();
    final saved = await showNestSheet<bool>(
      context: context,
      title: NannyCopy.photoOfChild,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PhotoField(
            currentPhotoId: child.card.photoId,
            label: child.member.displayName,
            onPick: controller.pickPhoto,
            onChanged: (picked) => change = picked,
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: NannyCopy.save,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      ),
    );
    if (saved != true || change is PhotoKept) return;
    await controller.edit.changeCardPhoto(
      _childId,
      change,
      current: child.card.photoId,
    );
  }
}
