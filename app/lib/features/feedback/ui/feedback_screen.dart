import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../account_data/ui/account_centre_screen.dart';
import '../model/feedback_draft.dart';
import '../state/feedback_controller.dart';

/// Under the account paths so a person with no household can reach it too
/// (feedback ADR-0001).
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  static const path = '/account/feedback';
  static const fromParameter = 'from';

  /// [from] is the route pattern of the screen it was opened over, so the
  /// entry says where the person was without carrying any ids.
  static String location({String? from}) => Uri(
    path: path,
    queryParameters: from == null ? null : {fromParameter: from},
  ).toString();

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FeedbackController>();
    return NestScaffold(
      title: FeedbackCopy.title,
      subtitle: FeedbackCopy.subtitle,
      leading: backLeading(context),
      body: switch (controller.status) {
        FeedbackStatus.delivered || FeedbackStatus.queued => _Sent(
          queued: controller.status == FeedbackStatus.queued,
          onAnother: () {
            _message.clear();
            controller.startAnother();
          },
        ),
        FeedbackStatus.editing || FeedbackStatus.sending => _Form(
          controller: controller,
          message: _message,
        ),
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.controller, required this.message});

  final FeedbackController controller;
  final TextEditingController message;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final failure = controller.failure;
    final enabled = !controller.isSending;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          Text(
            FeedbackCopy.lead,
            style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: FeedbackCopy.kindQuestion),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final kind in FeedbackKind.values)
                NestChip(
                  key: ValueKey('feedback-kind-${kind.name}'),
                  label: FeedbackCopy.kind(kind),
                  icon: _kindIcon(kind),
                  isSelected: controller.kind == kind,
                  onTap: enabled ? () => controller.chooseKind(kind) : null,
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          NestTextField(
            key: const ValueKey('feedback-message'),
            label: FeedbackCopy.messageLabel,
            hint: FeedbackCopy.messageHint(controller.kind),
            controller: message,
            enabled: enabled,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            inputFormatters: [
              LengthLimitingTextInputFormatter(FeedbackDraft.maxLength),
            ],
            onChanged: controller.setMessage,
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            FeedbackCopy.privacyNote,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: FeedbackCopy.areaQuestion),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final area in FeedbackArea.values)
                NestChip(
                  key: ValueKey('feedback-area-${area.name}'),
                  label: FeedbackCopy.area(area),
                  isSelected: controller.area == area,
                  onTap: enabled ? () => controller.chooseArea(area) : null,
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          NestCheckRow(
            label: FeedbackCopy.mayContact,
            value: controller.mayContact,
            onChanged: enabled ? controller.setMayContact : null,
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            key: const ValueKey('feedback-send'),
            label: FeedbackCopy.send,
            icon: LucideIcons.send,
            isLoading: controller.isSending,
            onPressed: controller.canSend
                ? () => unawaited(controller.send())
                : null,
          ),
        ],
      ),
    );
  }

  static IconData _kindIcon(FeedbackKind kind) => switch (kind) {
    FeedbackKind.problem => LucideIcons.bug,
    FeedbackKind.praise => LucideIcons.heart,
    FeedbackKind.idea => LucideIcons.lightbulb,
  };
}

class _Sent extends StatelessWidget {
  const _Sent({required this.queued, required this.onAnother});

  final bool queued;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestRiseIn(
            child: NestCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NestIconTile(
                    icon: queued ? LucideIcons.cloudOff : LucideIcons.heart,
                    tint: NestTileTint.basil,
                  ),
                  const SizedBox(height: NestSpace.lg),
                  Text(FeedbackCopy.deliveredTitle, style: nest.text.title),
                  const SizedBox(height: NestSpace.sm),
                  Text(
                    queued
                        ? FeedbackCopy.queuedBody
                        : FeedbackCopy.deliveredBody,
                    style: nest.text.body.copyWith(
                      color: nest.colors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            key: const ValueKey('feedback-done'),
            label: FeedbackCopy.done,
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AccountCentreScreen.path),
          ),
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: FeedbackCopy.another,
            variant: NestButtonVariant.outline,
            onPressed: onAnother,
          ),
        ],
      ),
    );
  }
}
