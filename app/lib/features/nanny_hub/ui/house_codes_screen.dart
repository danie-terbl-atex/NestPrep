import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/house_code.dart';
import '../model/house_codes.dart';
import '../state/house_codes_controller.dart';
import 'house_code_card.dart';
import 'house_code_sheet.dart';
import 'hub_clock.dart';
import 'hub_empty_note.dart';
import 'nanny_hub_screen.dart';

/// The house codes (nanny-hub ADR-0006): the alarm, the gate, the spare key.
/// Family keeps them here. A carer sees them only inside a shift booked for
/// them — shut before, open for the shift and its quarter-hour either side,
/// shut again after — and the screen says which, never an empty list.
class HouseCodesScreen extends StatelessWidget {
  const HouseCodesScreen({super.key});

  Future<void> _edit(BuildContext context, {HouseCode? existing}) async {
    final controller = context.read<HouseCodesController>();
    final outcome = await showHouseCodeSheet(
      context: context,
      existing: existing,
    );
    if (outcome == null) return;
    final draft = outcome.draft;
    if (outcome.isRemoval && existing != null) {
      await controller.remove(existing.id);
    } else if (draft != null && existing != null) {
      await controller.update(existing.id, draft);
    } else if (draft != null) {
      await controller.add(draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HouseCodesController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: NannyBookingCopy.codesTitle,
      leading: backLeading(context),
      trailing: const [EmergencyLinkButton()],
      floatingAction: controller.isFamily
          ? NestButton(
              label: NannyBookingCopy.addCode,
              icon: LucideIcons.plus,
              isExpanded: false,
              onPressed: () => _edit(context),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<HouseCodes>(
              state: controller.codes,
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, codes) => switch (codes) {
                CodesShown() => _Shown(
                  codes: codes,
                  isFamily: controller.isFamily,
                  onEdit: (code) => _edit(context, existing: code),
                ),
                CodesClosed(:final next) => _Closed(
                  nextWhen: next == null
                      ? null
                      : context.read<HouseholdClock>().bookingOf(next),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Shown extends StatelessWidget {
  const _Shown({
    required this.codes,
    required this.isFamily,
    required this.onEdit,
  });

  final CodesShown codes;
  final bool isFamily;
  final ValueChanged<HouseCode> onEdit;

  @override
  Widget build(BuildContext context) {
    final closesAt = codes.closesAt;
    final sections = <Widget>[
      if (isFamily)
        const NestBanner(message: NannyBookingCopy.codesFamilyNote)
      else if (closesAt != null)
        NestBanner(
          message: NannyBookingCopy.codesOpenUntil(
            context.read<HouseholdClock>().timeOf(closesAt),
          ),
          tone: NestBannerTone.success,
        ),
      if (codes.codes.isEmpty)
        const HubEmptyNote(
          icon: LucideIcons.keyRound,
          title: NannyBookingCopy.noCodesTitle,
          message: NannyBookingCopy.noCodesBody,
        ),
      for (final code in codes.codes)
        HouseCodeCard(
          key: ValueKey(code.id),
          code: code,
          onTap: isFamily ? () => onEdit(code) : null,
        ),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge * 2),
      children: [
        for (final (index, section) in sections.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: NestRiseIn(index: index, child: section),
          ),
      ],
    );
  }
}

class _Closed extends StatelessWidget {
  const _Closed({required this.nextWhen});

  final String? nextWhen;

  @override
  Widget build(BuildContext context) {
    final when = nextWhen;
    return ListView(
      children: [
        NestCard(
          variant: NestCardVariant.tinted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: NestIconTile(icon: LucideIcons.lockKeyhole),
              ),
              const SizedBox(height: NestSpace.md),
              Text(
                NannyBookingCopy.codesClosedTitle,
                style: NestTheme.of(context).text.title,
              ),
              const SizedBox(height: NestSpace.xs),
              Text(
                when == null
                    ? NannyBookingCopy.codesClosedNone
                    : NannyBookingCopy.codesClosedNext(when),
                style: NestTheme.of(context).text.bodySecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        const NestBanner(message: NannyBookingCopy.codesNeedSignal),
      ],
    );
  }
}
