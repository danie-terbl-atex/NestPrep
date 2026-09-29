import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../model/calendar_provider.dart';
import 'calendar_source_look.dart';

/// One kind of calendar a member can bring in, and the way to do it. A
/// provider this deployment has not set up says so in words where the button
/// would be, instead of failing when tapped (calendar ADR-0003, `FE-09`).
///
/// The action sits beside the words at ordinary text sizes and moves under
/// them at large ones, where beside them there is no room for either
/// (`FE-13`, `FE-14`).
class ProviderConnectRow extends StatelessWidget {
  const ProviderConnectRow({
    required this.provider,
    required this.isAvailable,
    required this.isBusy,
    required this.onConnect,
    super.key,
  });

  final CalendarProvider provider;
  final bool isAvailable;
  final bool isBusy;
  final VoidCallback onConnect;

  static const _largeText = 1.3;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final look = CalendarSourceLook.of(provider);
    final isLargeText = MediaQuery.textScalerOf(context).scale(1) > _largeText;
    final action = isAvailable
        ? NestButton(
            label: CalendarSyncCopy.connect,
            variant: NestButtonVariant.tonal,
            size: NestButtonSize.small,
            isExpanded: false,
            isLoading: isBusy,
            onPressed: isBusy ? null : onConnect,
          )
        : Text(
            CalendarSyncCopy.notSetUp,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          );
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CalendarSyncCopy.providerName(provider),
          style: nest.text.bodyStrong.copyWith(color: nest.colors.ink),
        ),
        const SizedBox(height: NestSpace.xxs),
        Text(
          CalendarSyncCopy.providerBlurb(provider),
          style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
        ),
        if (isLargeText) ...[const SizedBox(height: NestSpace.sm), action],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NestSpace.lg,
        vertical: NestSpace.md,
      ),
      child: Row(
        children: [
          NestIconTile(
            icon: look.icon,
            tint: look.tint,
            size: NestSize.avatarMedium,
            iconSize: NestSize.iconMedium,
          ),
          const SizedBox(width: NestSpace.lg),
          Expanded(child: words),
          if (!isLargeText) ...[const SizedBox(width: NestSpace.md), action],
        ],
      ),
    );
  }
}
