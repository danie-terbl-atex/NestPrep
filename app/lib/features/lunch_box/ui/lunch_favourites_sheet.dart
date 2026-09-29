import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_board.dart';
import '../model/lunch_favourite.dart';
import 'art/lunch_glyph.dart';

/// A child's go-to boxes: pick one to pack it into the day, or remove one
/// (lunch-box ADR-0003). One that has stopped being safe for them says so and
/// cannot be packed.
Future<LunchFavourite?> showLunchFavouritesSheet({
  required BuildContext context,
  required LunchChildWeek childWeek,
  required ValueChanged<LunchFavourite>? onRemove,
}) => showNestSheet<LunchFavourite>(
  context: context,
  title: LunchCopy.favouritesFor(childWeek.child.member.displayName),
  builder: (_) => _FavouritesBody(childWeek: childWeek, onRemove: onRemove),
);

class _FavouritesBody extends StatelessWidget {
  const _FavouritesBody({required this.childWeek, required this.onRemove});

  final LunchChildWeek childWeek;
  final ValueChanged<LunchFavourite>? onRemove;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final favourites = childWeek.favourites;
    if (favourites.isEmpty) {
      return Text(LunchCopy.noFavourites, style: nest.text.bodySecondary);
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final favourite in favourites)
          _FavouriteRow(
            key: ValueKey(favourite.id),
            favourite: favourite,
            isUnsafe: childWeek.unsafeFavouriteIds.contains(favourite.id),
            onRemove: onRemove,
          ),
      ],
    );
  }
}

class _FavouriteRow extends StatelessWidget {
  const _FavouriteRow({
    required this.favourite,
    required this.isUnsafe,
    required this.onRemove,
    super.key,
  });

  final LunchFavourite favourite;
  final bool isUnsafe;
  final ValueChanged<LunchFavourite>? onRemove;

  @override
  Widget build(BuildContext context) {
    final filled = favourite.box.filled;
    final remove = onRemove;
    return NestListRow(
      title: favourite.name,
      subtitle: [for (final (_, pick) in filled) pick.name].join(' · '),
      leading: filled.isEmpty
          ? null
          : LunchSlotTile(slot: filled.first.$1, isEmpty: isUnsafe),
      footer: isUnsafe
          ? const NestTag(
              label: LunchCopy.favouriteUnsafe,
              tone: NestTagTone.danger,
              icon: Icons.block_rounded,
            )
          : null,
      trailing: remove == null
          ? null
          : NestIconButton(
              icon: Icons.delete_outline_rounded,
              label: LunchCopy.removeFavourite(favourite.name),
              variant: NestIconButtonVariant.plain,
              onPressed: () {
                Navigator.of(context).pop();
                remove(favourite);
              },
            ),
      onTap: isUnsafe ? null : () => Navigator.of(context).pop(favourite),
    );
  }
}
