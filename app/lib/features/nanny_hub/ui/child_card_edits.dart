import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
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

  Future<void> changePhoto(BuildContext context) => showNestSheet<void>(
    context: context,
    title: NannyCopy.photoOfChild,
    builder: (_) => _ChildPhotoSheet(controller: controller, child: child),
  );
}

/// Stays open while the photo uploads, so the person sees it working, and
/// keeps the picked photo when the upload is refused.
class _ChildPhotoSheet extends StatefulWidget {
  const _ChildPhotoSheet({required this.controller, required this.child});

  final NannyHubController controller;
  final ChildInCare child;

  @override
  State<_ChildPhotoSheet> createState() => _ChildPhotoSheetState();
}

class _ChildPhotoSheetState extends State<_ChildPhotoSheet> {
  PhotoChange _change = const PhotoKept();
  bool _isSaving = false;
  AppFailure? _failure;

  Future<void> _save() async {
    final change = _change;
    if (change is PhotoKept) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSaving = true;
      _failure = null;
    });
    await widget.controller.edit.changeCardPhoto(
      widget.child.memberId,
      change,
      current: widget.child.card.photoId,
    );
    if (!mounted) return;
    final failure = widget.controller.actionFailure;
    if (failure == null) {
      Navigator.of(context).pop();
      return;
    }
    widget.controller.dismissActionFailure();
    setState(() {
      _isSaving = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          PhotoField(
            currentPhotoId: widget.child.card.photoId,
            label: widget.child.member.displayName,
            onPick: widget.controller.pickPhoto,
            onChanged: (picked) => _change = picked,
            enabled: !_isSaving,
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: _isSaving ? NannyCopy.uploadingPhoto : NannyCopy.save,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}
