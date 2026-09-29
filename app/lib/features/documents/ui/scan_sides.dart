import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';

/// The sides a scan caught, side by side and labelled — front, back — so
/// somebody can see every word is sharp before it is filed (documents
/// ADR-0004). The images are the scanner's cropped output, in memory only.
class ScanSides extends StatelessWidget {
  const ScanSides({required this.sides, super.key});

  final List<Uint8List> sides;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SizedBox(
      height: NestSize.scanSidesHeight,
      child: Row(
        children: [
          for (final (index, side) in sides.indexed) ...[
            if (index > 0) const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: nest.colors.surfaceTint,
                        borderRadius: BorderRadius.circular(NestRadius.md),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(NestRadius.md),
                        child: Semantics(
                          image: true,
                          label: VaultCopy.side(index),
                          child: Image.memory(side, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: NestSpace.xs),
                  Text(
                    VaultCopy.side(index),
                    style: nest.text.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
