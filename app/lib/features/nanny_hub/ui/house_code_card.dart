import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/house_code.dart';

/// One house code, big enough to read at a dark gate with a child on one hip:
/// what it is for, the code itself large, and any note. Family taps it to
/// change it.
class HouseCodeCard extends StatelessWidget {
  const HouseCodeCard({required this.code, this.onTap, super.key});

  final HouseCode code;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final note = code.note;
    return NestCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NestIconTile(
                icon: Icons.key_outlined,
                tint: NestTileTint.peach,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(child: Text(code.label, style: nest.text.title)),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Text(code.value, style: nest.text.display),
          if (note != null) ...[
            const SizedBox(height: NestSpace.sm),
            Text(note, style: nest.text.bodySecondary),
          ],
        ],
      ),
    );
  }
}
