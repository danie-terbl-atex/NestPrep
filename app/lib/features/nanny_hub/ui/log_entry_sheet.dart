import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../data/photo_picker.dart';
import '../model/handover_draft.dart';
import '../model/handover_entry.dart';
import '../model/handover_kind.dart';
import '../model/handover_mood.dart';
import '../model/nanny_limits.dart';
import '../model/photo_change.dart';
import 'child_choice.dart';
import 'mood_choice.dart';
import 'photo_field.dart';
import 'when_choice.dart';

/// What the log sheet decided: an entry and what happened to its photo, or —
/// for one that exists — that it goes. Null means closed.
typedef LogOutcome = ({HandoverDraft draft, PhotoChange photo, bool isRemoval});

/// Logs one thing that happened, or changes one already logged. Built for a
/// carer with one free hand: the kind is already chosen by the button that
/// opened it, every child is picked by default, "now" is the default time,
/// and the one required thing — a note, a mood or a photo — is said on the
/// button until it is there (`FE-10`).
Future<LogOutcome?> showLogEntrySheet({
  required BuildContext context,
  required HandoverKind kind,
  required List<Member> children,
  required HouseholdClock clock,
  required Future<Uint8List?> Function(PhotoSource source) onPick,
  HandoverEntry? existing,
}) => showNestSheet<LogOutcome>(
  context: context,
  title: NannyCopy.logTitle(existing?.kind ?? kind),
  builder: (_) => _LogEntryBody(
    kind: existing?.kind ?? kind,
    children: children,
    clock: clock,
    onPick: onPick,
    existing: existing,
  ),
);

class _LogEntryBody extends StatefulWidget {
  const _LogEntryBody({
    required this.kind,
    required this.children,
    required this.clock,
    required this.onPick,
    required this.existing,
  });

  final HandoverKind kind;
  final List<Member> children;
  final HouseholdClock clock;
  final Future<Uint8List?> Function(PhotoSource source) onPick;
  final HandoverEntry? existing;

  @override
  State<_LogEntryBody> createState() => _LogEntryBodyState();
}

class _LogEntryBodyState extends State<_LogEntryBody> {
  late final _note = TextEditingController(text: widget.existing?.note);
  late Set<String> _childIds = {
    ...?widget.existing?.childIds,
    if (widget.existing == null)
      for (final child in widget.children) child.id,
  };
  late HandoverMood? _mood = widget.existing?.mood;
  late DateTime _at = widget.existing?.at ?? widget.clock.now;
  PhotoChange _photo = const PhotoKept();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _hasPhoto => switch (_photo) {
    PhotoKept() => widget.existing?.photoId != null,
    PhotoPicked() => true,
    PhotoRemoved() => false,
  };

  String? get _noteText {
    final text = _note.text.trim();
    return text.isEmpty ? null : text;
  }

  bool get _saysSomething => _noteText != null || _mood != null || _hasPhoto;

  void _finish({required bool isRemoval}) => Navigator.of(context).pop((
    draft: HandoverDraft(
      kind: widget.kind,
      at: _at,
      note: _noteText,
      mood: _mood,
      childIds: [
        for (final child in widget.children)
          if (_childIds.contains(child.id)) child.id,
      ],
    ),
    photo: _photo,
    isRemoval: isRemoval,
  ));

  Future<void> _remove() async {
    final confirmed = await showNestConfirm(
      context: context,
      title: NannyCopy.removeEntryConfirm,
      confirmLabel: NannyCopy.delete,
      cancelLabel: NannyCopy.cancel,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    _finish(isRemoval: true);
  }

  @override
  Widget build(BuildContext context) {
    final isMood = widget.kind == HandoverKind.mood;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.kind == HandoverKind.incident) ...[
            const NestBanner(
              message: NannyCopy.incidentWarning,
              tone: NestBannerTone.warning,
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          if (widget.children.isNotEmpty) ...[
            ChildChoice(
              children: widget.children,
              chosen: _childIds,
              onChanged: (ids) => setState(() => _childIds = ids),
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          MoodChoice(
            mood: _mood,
            isProminent: isMood,
            onChanged: (mood) => setState(() => _mood = mood),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyCopy.note,
            hint: NannyCopy.noteHint(widget.kind),
            controller: _note,
            maxLines: 3,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.entryNote),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          WhenChoice(
            clock: widget.clock,
            at: _at,
            onChanged: (at) => setState(() => _at = at),
          ),
          const SizedBox(height: NestSpace.lg),
          PhotoField(
            currentPhotoId: widget.existing?.photoId,
            label: NannyCopy.kindName(widget.kind),
            onPick: widget.onPick,
            onChanged: (photo) => setState(() => _photo = photo),
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: _saysSomething
                ? NannyCopy.logIt
                : NannyCopy.entryNeedsSomething,
            icon: _saysSomething ? Icons.check : null,
            onPressed: _saysSomething ? () => _finish(isRemoval: false) : null,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: NannyCopy.delete,
              variant: NestButtonVariant.ghost,
              icon: Icons.delete_outline,
              onPressed: _remove,
            ),
          ],
        ],
      ),
    );
  }
}
