import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe_snap.dart';

class RecipeSnapStrip extends StatelessWidget {
  const RecipeSnapStrip({
    required this.snaps,
    required this.onRemove,
    super.key,
  });

  final List<RecipeSnap> snaps;
  final ValueChanged<RecipeSnap>? onRemove;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final remove = onRemove;
    return Column(
      key: const ValueKey('recipe-import-snaps'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          RecipeImportCopy.snapsTitle(snaps.length),
          style: nest.text.bodyStrong.copyWith(color: nest.colors.ink),
        ),
        Text(
          RecipeImportCopy.snapsHint,
          style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final (index, snap) in snaps.indexed) ...[
                if (index > 0) const SizedBox(width: NestSpace.sm),
                _SnapTile(
                  key: ObjectKey(snap),
                  snap: snap,
                  number: index + 1,
                  onRemove: remove == null ? null : () => remove(snap),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SnapTile extends StatelessWidget {
  const _SnapTile({
    required this.snap,
    required this.number,
    required this.onRemove,
    super.key,
  });

  final RecipeSnap snap;
  final int number;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: NestSize.avatarHero,
    child: Stack(
      fit: StackFit.expand,
      children: [
        NestPhotoFrame(
          radius: NestRadius.md,
          semanticsLabel: RecipeImportCopy.snapNumbered(number),
          child: Image.memory(
            snap.thumbnail,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
        ),
        PositionedDirectional(
          start: NestSpace.xs,
          bottom: NestSpace.xs,
          child: ExcludeSemantics(child: NestTag(label: '$number')),
        ),
        PositionedDirectional(
          end: NestSpace.xs,
          top: NestSpace.xs,
          child: NestIconButton(
            icon: LucideIcons.x,
            label: RecipeImportCopy.removeSnap(number),
            onPressed: onRemove,
          ),
        ),
      ],
    ),
  );
}
