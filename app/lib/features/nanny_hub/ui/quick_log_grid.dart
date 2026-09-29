import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/handover_kind.dart';
import 'handover_look.dart';

/// The seven things a carer logs, as big tiles two to a row — each well past
/// the 44-point floor, so a thumb finds one without looking twice (`FE-13`).
/// While an entry is being stored the tiles wait, so a double tap is not two
/// entries (`FE-10`).
class QuickLogGrid extends StatelessWidget {
  const QuickLogGrid({required this.isBusy, required this.onLog, super.key});

  final bool isBusy;
  final ValueChanged<HandoverKind> onLog;

  /// The width, in unscaled points, two tiles need side by side.
  static const _twoColumnWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(NannyShiftCopy.logSomething, style: nest.text.title),
        const SizedBox(height: NestSpace.md),
        LayoutBuilder(
          builder: (context, constraints) {
            // Two to a row while a word like "Medicine" still fits beside its
            // icon; one to a row at a large text setting, so no label ever
            // breaks mid-word (`FE-13`, `FE-14`).
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final columns = constraints.maxWidth / scale >= _twoColumnWidth
                ? 2
                : 1;
            final width =
                (constraints.maxWidth - NestSpace.sm * (columns - 1)) / columns;
            return Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final kind in HandoverKind.values)
                  SizedBox(
                    width: width,
                    child: _LogTile(
                      kind: kind,
                      onTap: isBusy ? null : () => onLog(kind),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.kind, required this.onTap});

  final HandoverKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: NannyShiftCopy.logTitle(kind),
      excludeSemantics: true,
      child: NestCard(
        variant: NestCardVariant.flat,
        padding: const EdgeInsets.all(NestSpace.md),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: NestSize.controlHuge),
          child: Row(
            children: [
              NestIconTile(
                icon: kind.icon,
                tint: kind.tint,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.sm),
              Expanded(
                child: Text(
                  NannyShiftCopy.kindName(kind),
                  style: nest.text.bodyStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
