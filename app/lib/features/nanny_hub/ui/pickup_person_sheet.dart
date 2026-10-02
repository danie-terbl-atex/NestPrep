import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';
import '../data/photo_picker.dart';
import '../model/nanny_limits.dart';
import '../model/photo_change.dart';
import '../model/pickup_drafts.dart';
import '../model/pickup_person.dart';
import 'photo_field.dart';

/// What the person sheet decided: somebody to save with what happened to
/// their photo, or — for one who exists — to remove. Null means closed.
typedef PickupPersonOutcome = ({
  PickupPersonDraft draft,
  PhotoChange photo,
  bool isRemoval,
});

/// Adds an adult who may collect, or edits [existing]: a photo first, because
/// that is what a carer at the door looks at; a name and who they are to the
/// family; how to be sure; and which children. Save waits until the name, the
/// relationship and at least one child are there, and a number — if typed — is
/// one the rules accept (`FE-10`).
Future<PickupPersonOutcome?> showPickupPersonSheet({
  required BuildContext context,
  required List<Member> children,
  required Future<Uint8List?> Function(PhotoSource source) onPick,
  PickupPerson? existing,
  String? forChildId,
}) => showNestSheet<PickupPersonOutcome>(
  context: context,
  title: existing == null
      ? NannyPickupCopy.addPerson
      : NannyPickupCopy.editPerson,
  builder: (_) => _PersonBody(
    children: children,
    onPick: onPick,
    existing: existing,
    forChildId: forChildId,
  ),
);

class _PersonBody extends StatefulWidget {
  const _PersonBody({
    required this.children,
    required this.onPick,
    required this.existing,
    required this.forChildId,
  });

  final List<Member> children;
  final Future<Uint8List?> Function(PhotoSource source) onPick;
  final PickupPerson? existing;
  final String? forChildId;

  @override
  State<_PersonBody> createState() => _PersonBodyState();
}

class _PersonBodyState extends State<_PersonBody> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _relationship = TextEditingController(
    text: widget.existing?.relationship,
  );
  late final _idNote = TextEditingController(text: widget.existing?.idNote);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late Set<String> _children = {
    ...?widget.existing?.childIds,
    if (widget.existing == null && widget.children.length == 1)
      widget.children.single.id,
    ?widget.forChildId,
  };
  PhotoChange _photo = const PhotoKept();

  bool get _phoneIsValid =>
      _phone.text.trim().isEmpty ||
      NannyLimits.phonePattern.hasMatch(_phone.text.trim());

  bool get _canSave =>
      _name.text.trim().isNotEmpty &&
      _relationship.text.trim().isNotEmpty &&
      _children.isNotEmpty &&
      _phoneIsValid;

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _idNote.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _finish({required bool isRemoval}) => Navigator.of(context).pop((
    draft: (
      name: _name.text.trim(),
      relationship: _relationship.text.trim(),
      idNote: _idNote.text,
      phone: _phone.text,
      childIds: _children,
    ),
    photo: _photo,
    isRemoval: isRemoval,
  ));

  Future<void> _remove() async {
    final confirmed = await showNestConfirm(
      context: context,
      title: NannyPickupCopy.removePersonConfirm,
      confirmLabel: NannyCopy.delete,
      cancelLabel: NannyCopy.cancel,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    _finish(isRemoval: true);
  }

  void _toggle(String childId) => setState(
    () => _children = _children.contains(childId)
        ? ({..._children}..remove(childId))
        : {..._children, childId},
  );

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final phoneTyped = _phone.text.trim().isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PhotoField(
            currentPhotoId: widget.existing?.photoId,
            label: NannyPickupCopy.photoOf(_name.text),
            onPick: widget.onPick,
            onChanged: (photo) => _photo = photo,
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyPickupCopy.name,
            hint: NannyPickupCopy.nameHint,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.pickupName),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.sm),
          NestTextField(
            label: NannyPickupCopy.relationship,
            hint: NannyPickupCopy.relationshipHint,
            controller: _relationship,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.pickupRelationship),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.sm),
          NestTextField(
            label: NannyPickupCopy.idNote,
            hint: NannyPickupCopy.idNoteHint,
            controller: _idNote,
            maxLines: 2,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.pickupIdNote),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          NestTextField(
            label: NannyPickupCopy.phone,
            hint: NannyPickupCopy.phoneHint,
            controller: _phone,
            keyboardType: TextInputType.phone,
            prefixIcon: LucideIcons.phone,
            errorText: phoneTyped && !_phoneIsValid
                ? NannyPickupCopy.phoneNotValid
                : null,
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          Text(
            NannyPickupCopy.mayCollect,
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
                  isSelected: _children.contains(child.id),
                  icon: _children.contains(child.id) ? LucideIcons.check : null,
                  onTap: () => _toggle(child.id),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyCopy.save,
            onPressed: _canSave ? () => _finish(isRemoval: false) : null,
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
