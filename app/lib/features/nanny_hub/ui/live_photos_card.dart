import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The parents' way into a shift's live photos from the hub's home — one row
/// per carer on shift right now (nanny-hub ADR-0004). The feed itself is
/// where they arrive live; this only says where to look.
class LivePhotosCard extends StatelessWidget {
  const LivePhotosCard({required this.shifts, required this.onOpen, super.key});

  /// Each shift on now: its id and whose it is.
  final List<({String shiftId, String carer})> shifts;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, shift) in shifts.indexed) ...[
          if (index > 0) const SizedBox(height: NestSpace.sm),
          NestCard(
            variant: NestCardVariant.flat,
            padding: EdgeInsets.zero,
            child: NestListRow(
              leading: const NestIconTile(
                icon: LucideIcons.camera,
                tint: NestTileTint.lilac,
              ),
              title: NannyPhotoCopy.liveFrom(shift.carer),
              subtitle: NannyPhotoCopy.liveFromBody,
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => onOpen(shift.shiftId),
            ),
          ),
        ],
      ],
    );
  }
}
