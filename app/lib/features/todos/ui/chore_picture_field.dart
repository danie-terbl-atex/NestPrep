import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/chore_picture_copy.dart';
import '../model/chore_picture.dart';
import '../model/chore_picture_match.dart';
import 'chore_picture_picker.dart';

/// A task's picture, in the task sheet (todos ADR-0005): the one chosen, or —
/// with none — a few that fit the title as it is typed, each one tap. The app
/// suggests; only the grown-up ever sets one.
class ChorePictureField extends StatelessWidget {
  const ChorePictureField({
    required this.title,
    required this.picture,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String? picture;
  final ValueChanged<String?> onChanged;

  static const suggestions = 4;

  Future<void> _openPicker(BuildContext context) async {
    final choice = await showChorePicturePicker(
      context: context,
      title: title,
      selected: ChorePicture.byId(picture)?.id,
    );
    if (choice != null) onChanged(choice.id);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final chosen = ChorePicture.byId(picture);
    final suggested = chosen == null
        ? suggestChorePictures(title, limit: suggestions)
        : const <ChorePicture>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ChorePictureCopy.fieldLabel,
          style: nest.text.label.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        if (chosen != null)
          _Chosen(
            picture: chosen,
            onChange: () => _openPicker(context),
            onRemove: () => onChanged(null),
          )
        else ...[
          Text(
            ChorePictureCopy.fieldHelp,
            style: nest.text.caption.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final suggestion in suggested)
                _Suggestion(
                  picture: suggestion,
                  onTap: () => onChanged(suggestion.id),
                ),
              NestChip(
                key: const ValueKey('chore-picture-more'),
                label: suggested.isEmpty
                    ? ChorePictureCopy.choosePicture
                    : ChorePictureCopy.morePictures,
                icon: LucideIcons.images,
                onTap: () => _openPicker(context),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Chosen extends StatelessWidget {
  const _Chosen({
    required this.picture,
    required this.onChange,
    required this.onRemove,
  });

  final ChorePicture picture;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: ChorePictureCopy.chosen(picture.label),
            onTap: onChange,
            excludeSemantics: true,
            child: InkWell(
              key: const ValueKey('chore-picture-change'),
              borderRadius: BorderRadius.circular(NestRadius.lg),
              onTap: onChange,
              child: Row(
                children: [
                  NestSticker(
                    asset: picture.asset,
                    size: NestSize.stickerMedium,
                  ),
                  const SizedBox(width: NestSpace.md),
                  Expanded(
                    child: Text(picture.label, style: nest.text.bodyStrong),
                  ),
                ],
              ),
            ),
          ),
        ),
        NestIconButton(
          icon: LucideIcons.x,
          label: ChorePictureCopy.remove,
          variant: NestIconButtonVariant.plain,
          onPressed: onRemove,
        ),
      ],
    );
  }
}

/// One tap to wear it: a pill with the picture and its name.
class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.picture, required this.onTap});

  final ChorePicture picture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final shape = StadiumBorder(side: BorderSide(color: c.outline));
    return Semantics(
      container: true,
      button: true,
      label: ChorePictureCopy.use(picture.label),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('chore-picture-suggestion-${picture.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              NestSpace.xs,
              NestSpace.xs,
              NestSpace.lg,
              NestSpace.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NestSticker(asset: picture.asset),
                const SizedBox(width: NestSpace.sm),
                Flexible(child: Text(picture.label, style: nest.text.label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
