import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/emergency_contact.dart';

/// One person to call: who they are to the household, their number written
/// out, and a big green call button that is its own target — so reaching for
/// it one-handed never opens the editor instead (`FE-13`).
class EmergencyContactRow extends StatelessWidget {
  const EmergencyContactRow({
    required this.contact,
    required this.onCall,
    required this.onEdit,
    super.key,
  });

  final EmergencyContact contact;
  final VoidCallback onCall;

  /// Null when the viewer may not change the sheet.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final note = contact.note;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.md),
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NestTag(
                  label: NannyCopy.contactKindName(contact.kind),
                  tone: NestTagTone.accent,
                ),
                const SizedBox(height: NestSpace.xs),
                Text(contact.name, style: nest.text.title),
                Text(contact.phone, style: nest.text.body),
                if (note != null) Text(note, style: nest.text.caption),
              ],
            ),
          ),
          const SizedBox(width: NestSpace.sm),
          NestIconButton(
            icon: LucideIcons.phone,
            label: NannyCopy.call(contact.name),
            variant: NestIconButtonVariant.accent,
            onPressed: onCall,
          ),
        ],
      ),
    );
  }
}
