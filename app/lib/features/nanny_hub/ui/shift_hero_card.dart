import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../model/nanny_access.dart';
import '../model/nanny_hub.dart';
import '../model/shift.dart';
import 'hub_clock.dart';

/// The first thing on the hub: the carer's way into shift mode — start one,
/// or go back to the one they are on — and, for everybody else, who is on
/// shift right now. Big and plain, because it is tapped at the front door
/// with bags in hand.
class ShiftHeroCard extends StatelessWidget {
  const ShiftHeroCard({
    required this.hub,
    required this.access,
    required this.memberById,
    required this.onStartMine,
    required this.onStartForSomebody,
    required this.onOpenShift,
    super.key,
  });

  final NannyHub hub;
  final NannyAccess access;
  final Member? Function(String memberId) memberById;
  final VoidCallback onStartMine;

  /// Null for anybody who is not family.
  final VoidCallback? onStartForSomebody;
  final ValueChanged<String> onOpenShift;

  @override
  Widget build(BuildContext context) {
    final clock = context.read<HouseholdClock>();
    final mine = hub.openShiftOf(access.viewerMemberId);
    final others = [
      for (final shift in hub.openShifts)
        if (shift.id != mine?.id) shift,
    ];
    final startForSomebody = onStartForSomebody;
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mine != null)
            _OnShift(
              since: _started(clock, mine),
              onOpen: () => onOpenShift(mine.id),
            )
          else if (access.canEdit && access.viewerMemberId != null)
            _Ready(onStart: onStartMine)
          else if (others.isEmpty)
            const _Nobody(),
          for (final shift in others) ...[
            const SizedBox(height: NestSpace.sm),
            _OtherShiftRow(
              title: NannyCopy.onShiftSince(
                memberById(shift.carerMemberId)?.displayName ?? '',
                _started(clock, shift),
              ),
              member: memberById(shift.carerMemberId),
              onTap: () => onOpenShift(shift.id),
            ),
          ],
          if (startForSomebody != null && mine == null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: NannyCopy.startShiftFor,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.userPlus,
              onPressed: startForSomebody,
            ),
          ],
        ],
      ),
    );
  }

  static String _started(HouseholdClock clock, Shift shift) {
    final at = shift.startedAt;
    return at == null ? NannyShiftCopy.summaryPending : clock.timeOf(at);
  }
}

class _OnShift extends StatelessWidget {
  const _OnShift({required this.since, required this.onOpen});

  final String since;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const NestIconTile(
              icon: LucideIcons.baby,
              tint: NestTileTint.basil,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(NannyCopy.onShiftTitle, style: nest.text.headline),
                  Text(
                    NannyCopy.youSince(since),
                    style: nest.text.bodySecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: NannyCopy.openShiftMode,
          icon: LucideIcons.arrowRight,
          onPressed: onOpen,
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(NannyCopy.readyTitle, style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(NannyCopy.readyBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: NannyCopy.startMyShift,
          icon: LucideIcons.play,
          onPressed: onStart,
        ),
      ],
    );
  }
}

class _Nobody extends StatelessWidget {
  const _Nobody();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(NannyCopy.nobodyOnShift, style: nest.text.title),
        const SizedBox(height: NestSpace.xs),
        Text(NannyCopy.nobodyOnShiftBody, style: nest.text.bodySecondary),
      ],
    );
  }
}

class _OtherShiftRow extends StatelessWidget {
  const _OtherShiftRow({
    required this.title,
    required this.member,
    required this.onTap,
  });

  final String title;
  final Member? member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final carer = member;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        leading: carer == null
            ? const NestIconTile(icon: LucideIcons.baby)
            : NestAvatar(name: carer.displayName, color: carer.color),
        title: title,
        subtitle: NannyCopy.viewShift,
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}
