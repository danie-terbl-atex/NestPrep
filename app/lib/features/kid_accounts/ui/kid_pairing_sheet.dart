import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../household/model/member.dart';
import '../state/kid_sign_in_controller.dart';
import 'kid_code_letters.dart';
import 'kid_pairing_countdown.dart';

/// Adding a device for one child, in three beats (accounts ADR-0003): name the
/// device and make a code; read the code out while it counts down; and — the
/// moment the child's tablet uses it — see it land.
///
/// Whatever way the sheet closes, a code nobody used is retired then, not ten
/// minutes later.
Future<void> showKidPairingSheet({
  required BuildContext context,
  required KidSignInController controller,
  required Member member,
}) async {
  controller.beginPairing();
  await showNestSheet<void>(
    context: context,
    title: KidCopy.pairTitle,
    // The sheet is a route of its own, above the screen's providers, so it is
    // handed the screen's controller rather than looking for one.
    builder: (_) => ChangeNotifierProvider.value(
      value: controller,
      child: _PairingSheetBody(member: member),
    ),
  );
  await controller.closePairing();
}

class _PairingSheetBody extends StatefulWidget {
  const _PairingSheetBody({required this.member});

  final Member member;

  @override
  State<_PairingSheetBody> createState() => _PairingSheetBodyState();
}

class _PairingSheetBodyState extends State<_PairingSheetBody> {
  final TextEditingController _label = TextEditingController();

  /// Mirrors the Functions' `KID_CODE_LIFETIME_MS`.
  static const _lifetime = Duration(minutes: 10);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _makeCode(KidSignInController controller) =>
      controller.makeCode(memberId: widget.member.id, label: _label.text);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KidSignInController>();
    final nest = NestTheme.of(context);
    final pairing = controller.pairing;
    final paired = controller.pairedDevice;
    final failure = controller.actionFailure;

    final Widget beat;
    if (paired != null) {
      beat = _Paired(name: widget.member.displayName);
    } else if (pairing != null) {
      beat = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: pairing.code.split('').join(' '),
            child: KidCodeLetters(
              code: pairing.code,
              length: pairing.code.length,
            ),
          ),
          const SizedBox(height: NestSpace.lg),
          KidPairingCountdown(
            key: ValueKey(pairing.code),
            pairing: pairing,
            lifetime: _lifetime,
            onMakeAnother: () => _makeCode(controller),
          ),
          const SizedBox(height: NestSpace.lg),
          Text(
            KidCopy.pairBody,
            textAlign: TextAlign.center,
            style: nest.text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            KidCopy.pairWaiting,
            textAlign: TextAlign.center,
            style: nest.text.caption,
          ),
        ],
      );
    } else {
      beat = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestListRow(
            leading: NestAvatar(
              name: widget.member.displayName,
              color: widget.member.color,
            ),
            title: widget.member.displayName,
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: KidCopy.pairLabel,
            hint: KidCopy.pairLabelHint,
            controller: _label,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _makeCode(controller),
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: KidCopy.pairMakeCode,
            icon: LucideIcons.rectangleEllipsis,
            isLoading: controller.isMakingCode,
            onPressed: () => _makeCode(controller),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          AnimatedSwitcher(
            duration: NestMotion.of(context).standard,
            child: KeyedSubtree(
              key: ValueKey((paired != null, pairing?.code)),
              child: beat,
            ),
          ),
          const SizedBox(height: NestSpace.xl),
        ],
      ),
    );
  }
}

class _Paired extends StatelessWidget {
  const _Paired({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestRiseIn(
          child: Center(
            child: NestIconTile(
              icon: LucideIcons.partyPopper,
              tint: NestTileTint.basil,
              size: NestSize.mark,
              iconSize: NestSize.iconMark,
            ),
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        Text(
          KidCopy.pairSucceeded(name),
          textAlign: TextAlign.center,
          style: nest.text.headline,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: KidCopy.pairDone,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
