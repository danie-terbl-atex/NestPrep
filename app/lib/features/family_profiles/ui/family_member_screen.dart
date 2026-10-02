import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/family_roster.dart';
import '../state/family_controller.dart';
import '../state/member_health_controller.dart';
import 'family_member_body.dart';

/// One person's profile: what they cannot eat above all, then food,
/// medication, school and sizes, each with its own editor for whoever may
/// change it. The roster comes from the family shell; medication from this
/// route's own controller, because fewer people may read it
/// (family-profiles ADR-0001).
class FamilyMemberScreen extends StatelessWidget {
  const FamilyMemberScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyController>();
    final health = context.watch<MemberHealthController>();
    final failure = family.actionFailure ?? health.actionFailure;
    return NestScaffold(
      title: FamilyCopy.title,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
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
                onAction: () {
                  family.dismissActionFailure();
                  health.dismissActionFailure();
                },
              ),
            ),
          Expanded(
            child: NestAsyncView<FamilyRoster>(
              state: family.roster,
              // A person removed while their profile is open: the roster no
              // longer has them, and that is said rather than shown as blank.
              isEmpty: (roster) => roster.entryFor(memberId) == null,
              onRetry: family.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: FamilyCopy.memberGoneTitle,
                message: FamilyCopy.memberGoneBody,
                icon: LucideIcons.userX,
              ),
              dataBuilder: (_, roster) => FamilyMemberBody(
                entry: roster.entryFor(memberId)!,
                roster: roster,
                family: family,
                health: health,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
