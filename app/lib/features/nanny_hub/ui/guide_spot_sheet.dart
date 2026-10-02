import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../data/photo_picker.dart';
import '../model/guide_spot.dart';
import '../model/nanny_limits.dart';
import '../model/photo_change.dart';
import 'photo_field.dart';

/// What the guide sheet decided: a place to save with what happened to its
/// photo, or — for one that exists — to remove. Null means closed.
typedef GuideSpotOutcome = ({
  String title,
  String? note,
  PhotoChange photo,
  bool isRemoval,
});

Future<GuideSpotOutcome?> showGuideSpotSheet({
  required BuildContext context,
  required Future<Uint8List?> Function(PhotoSource source) onPick,
  GuideSpot? existing,
}) => showNestSheet<GuideSpotOutcome>(
  context: context,
  title: existing == null ? NannyCopy.addSpot : NannyCopy.editSpot,
  builder: (_) => _GuideSpotBody(existing: existing, onPick: onPick),
);

class _GuideSpotBody extends StatefulWidget {
  const _GuideSpotBody({required this.existing, required this.onPick});

  final GuideSpot? existing;
  final Future<Uint8List?> Function(PhotoSource source) onPick;

  @override
  State<_GuideSpotBody> createState() => _GuideSpotBodyState();
}

class _GuideSpotBodyState extends State<_GuideSpotBody> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _note = TextEditingController(text: widget.existing?.note);
  PhotoChange _photo = const PhotoKept();

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _finish({required bool isRemoval}) => Navigator.of(context).pop((
    title: _title.text.trim(),
    note: _note.text,
    photo: _photo,
    isRemoval: isRemoval,
  ));

  Future<void> _remove() async {
    final confirmed = await showNestConfirm(
      context: context,
      title: NannyCopy.removeSpotConfirm,
      confirmLabel: NannyCopy.delete,
      cancelLabel: NannyCopy.cancel,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    _finish(isRemoval: true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PhotoField(
            currentPhotoId: widget.existing?.photoId,
            label: _title.text,
            onPick: widget.onPick,
            onChanged: (photo) => _photo = photo,
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyCopy.spotTitle,
            hint: NannyCopy.spotTitleHint,
            controller: _title,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.spotTitle),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.sm),
          NestTextField(
            label: NannyCopy.spotNote,
            hint: NannyCopy.spotNoteHint,
            controller: _note,
            maxLines: 3,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.spotNote),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyCopy.save,
            onPressed: _title.text.trim().isEmpty
                ? null
                : () => _finish(isRemoval: false),
          ),
          if (widget.existing != null) ...[
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
