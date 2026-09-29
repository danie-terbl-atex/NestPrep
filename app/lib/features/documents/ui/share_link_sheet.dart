import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/data/invite_sharer.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../nanny_hub/data/shift_repository.dart';
import '../data/document_share_directory.dart';
import '../model/share_lifetime.dart';
import '../model/share_target.dart';
import '../state/share_link_composer.dart';
import 'share_lifetime_choice.dart';
import 'share_link_ready.dart';
import 'share_pin_field.dart';

/// Sharing one document by a link (documents ADR-0006): how long, a PIN if
/// wanted, a second look at an ID, then the link — once — with the phone's
/// share sheet and a copy button.
///
/// Open shifts are offered only to somebody who may see the nanny hub; the
/// server checks the shift again either way.
Future<void> showShareLinkSheet({
  required BuildContext context,
  required ShareTarget target,
}) {
  final view = context.read<HouseholdView>();
  final clock = context.read<HouseholdClock>();
  final directory = context.read<DocumentShareDirectory>();
  final sharer = context.read<InviteSharer>();
  final seesShifts = view.permissions.canView(HouseholdArea.nannyHub);
  final shifts = seesShifts ? context.read<ShiftRepository?>() : null;
  return showNestSheet<void>(
    context: context,
    title: ShareLinkCopy.sheetTitle,
    builder: (sheetContext) => MultiProvider(
      providers: [
        Provider<HouseholdClock>.value(value: clock),
        Provider<InviteSharer>.value(value: sharer),
        ChangeNotifierProvider(
          create: (_) => ShareLinkComposer(
            directory: directory,
            target: target,
            shifts: shifts,
            members: view.members,
          ),
        ),
      ],
      child: const _ShareLinkBody(),
    ),
  );
}

class _ShareLinkBody extends StatelessWidget {
  const _ShareLinkBody();

  @override
  Widget build(BuildContext context) {
    final composer = context.watch<ShareLinkComposer>();
    final link = composer.link;
    return SingleChildScrollView(
      child: link == null
          ? const _ShareLinkForm()
          : ShareLinkReady(
              link: link,
              hasPin: composer.asksForPin,
              endsLabel: composer.lifetime is ShiftLifetime
                  ? ShareLinkCopy.endsWithShift
                  : ShareLinkCopy.endsAt(_when(context, link.expiresAt)),
              onSend: () => _send(context, composer),
              onCopy: () => _copy(context, link.url.toString()),
              onDone: Navigator.of(context).pop,
            ),
    );
  }

  static String _when(BuildContext context, DateTime at) {
    final clock = context.read<HouseholdClock>();
    return NestDates.moment(
      clock.dateOf(at),
      clock.today,
      clock.minutesOfDay(at),
    );
  }

  Future<void> _send(BuildContext context, ShareLinkComposer composer) async {
    final link = composer.link;
    if (link == null) return;
    final outcome = await context.read<InviteSharer>().share(
      subject: ShareLinkCopy.shareSubject(composer.target.name),
      text: ShareLinkCopy.shareText(composer.target.name, link.url.toString()),
    );
    // No share sheet here: the copy button beside it is the way instead.
    if (outcome == InviteShareOutcome.unavailable && context.mounted) {
      await _copy(context, link.url.toString());
    }
  }

  static Future<void> _copy(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: url));
    messenger?.showSnackBar(
      const SnackBar(content: Text(ShareLinkCopy.copied)),
    );
  }
}

class _ShareLinkForm extends StatelessWidget {
  const _ShareLinkForm();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final composer = context.watch<ShareLinkComposer>();
    final failure = composer.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(composer.target.name, style: nest.text.title),
        const SizedBox(height: NestSpace.xs),
        Text(ShareLinkCopy.sheetBody, style: nest.text.bodySecondary),
        if (composer.isIdentityDocument) ...[
          const SizedBox(height: NestSpace.md),
          const NestBanner(
            message: ShareLinkCopy.identityBody,
            tone: NestBannerTone.warning,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        ShareLifetimeChoice(
          chosen: composer.lifetime,
          shiftOptions: composer.shiftOptions,
          onChosen: composer.chooseLifetime,
        ),
        const SizedBox(height: NestSpace.xl),
        SharePinField(
          asksForPin: composer.asksForPin,
          showsProblem: composer.showsPinProblem,
          onAsksForPin: composer.setAsksForPin,
          onPin: composer.setPin,
        ),
        if (failure != null) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: composer.isCreating
              ? ShareLinkCopy.creating
              : ShareLinkCopy.create,
          icon: Icons.link,
          isLoading: composer.isCreating,
          onPressed: composer.canCreate ? () => _create(context) : null,
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final composer = context.read<ShareLinkComposer>();
    if (composer.isIdentityDocument) {
      final confirmed = await showNestConfirm(
        context: context,
        title: ShareLinkCopy.identityTitle,
        message: ShareLinkCopy.identityBody,
        confirmLabel: ShareLinkCopy.identityConfirm,
        cancelLabel: AppCopy.householdCancel,
      );
      if (confirmed != true) return;
    }
    await composer.create();
  }
}
