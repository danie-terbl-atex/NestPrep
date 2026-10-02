import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/child_in_care.dart';
import 'nanny_photo.dart';

/// The top of a child's card: their photo — or their initials in their
/// colour until there is one — their name and their age.
class ChildHeader extends StatelessWidget {
  const ChildHeader({
    required this.child,
    required this.age,
    required this.onChangePhoto,
    super.key,
  });

  final ChildInCare child;

  /// Null when the household does not know the birth year.
  final int? age;

  /// Null when the viewer may not change the card.
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final member = child.member;
    final photoId = child.card.photoId;
    final years = age;
    final change = onChangePhoto;
    return Row(
      children: [
        SizedBox.square(
          dimension: NestSize.mark,
          child: photoId == null
              ? NestAvatar(
                  name: member.displayName,
                  color: member.color,
                  size: NestSize.mark,
                )
              : ClipOval(
                  child: NannyPhoto(
                    photoId: photoId,
                    label: member.displayName,
                    aspectRatio: 1,
                  ),
                ),
        ),
        const SizedBox(width: NestSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.displayName, style: nest.text.headline),
              if (years != null)
                Text(FamilyCopy.age(years), style: nest.text.bodySecondary),
              if (change != null) ...[
                const SizedBox(height: NestSpace.sm),
                NestChip(
                  label: photoId == null
                      ? NannyCopy.addPhoto
                      : NannyCopy.changePhoto,
                  icon: LucideIcons.camera,
                  onTap: change,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
