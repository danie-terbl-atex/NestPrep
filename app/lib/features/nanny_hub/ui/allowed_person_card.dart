import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/pickup_person.dart';
import 'nanny_photo.dart';

/// One adult who may collect, as a carer at the door needs them: the photo
/// big and first, the name, who they are, and how to be sure — with today's
/// expected collector marked in words as well as in the card's tone
/// (`FE-13`).
class AllowedPersonCard extends StatelessWidget {
  const AllowedPersonCard({
    required this.person,
    required this.expectedLabel,
    required this.onCall,
    super.key,
  });

  final PickupPerson person;

  /// Today's plan names them — "Expected today", with the time if known.
  final String? expectedLabel;

  /// Null when there is no number to call.
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final photoId = person.photoId;
    final expected = expectedLabel;
    final call = onCall;
    return NestCard(
      variant: expected == null ? NestCardVariant.flat : NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (expected != null) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestTag(
                label: expected,
                tone: NestTagTone.success,
                icon: LucideIcons.circleCheck,
              ),
            ),
            const SizedBox(height: NestSpace.md),
          ],
          if (photoId != null)
            NannyPhoto(
              photoId: photoId,
              label: NannyPickupCopy.photoOf(person.name),
            )
          else
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestIconTile(
                icon: LucideIcons.user,
                tint: NestTileTint.lilac,
                size: NestSize.mark,
                iconSize: NestSize.iconMark,
              ),
            ),
          const SizedBox(height: NestSpace.md),
          Text(person.name, style: nest.text.headline),
          Text(person.relationship, style: nest.text.bodySecondary),
          if (person.idNote case final note?) ...[
            const SizedBox(height: NestSpace.md),
            NestToneRow(
              icon: LucideIcons.idCard,
              tone: NestTagTone.accent,
              title: note,
            ),
          ],
          if (call != null) ...[
            const SizedBox(height: NestSpace.md),
            NestButton(
              label: NannyPickupCopy.callPerson(person.name),
              icon: LucideIcons.phone,
              variant: NestButtonVariant.outline,
              onPressed: call,
            ),
          ],
        ],
      ),
    );
  }
}
