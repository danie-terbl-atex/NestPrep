import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/home_care_board.dart';
import '../model/safety/job_safety.dart';
import '../state/home_care_controller.dart';
import '../state/job_composer_controller.dart';
import 'job_details_form.dart';
import 'photo_capture_card.dart';
import 'safety_panel.dart';
import 'spot_marker_screen.dart';

/// A new cleaning job: photograph the spot, circle it, say where, who,
/// when, with what and how — and see the safety the helper will see before
/// it is sent (home-care ADR-0001, ADR-0002).
class JobComposeScreen extends StatelessWidget {
  const JobComposeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCareController>();
    final composer = context.watch<JobComposerController>();
    final failure = composer.actionFailure;
    return NestScaffold(
      title: HomeCareCopy.newJob,
      leading: backLeading(context),
      body: NestAsyncView<HomeCareBoard>(
        state: home.board,
        isEmpty: (_) => false,
        onRetry: home.retry,
        emptyBuilder: (_) => const SizedBox.shrink(),
        dataBuilder: (context, board) {
          final chosen = [
            for (final product in board.products)
              if (composer.details.productIds.contains(product.id)) product,
          ];
          final safety = JobSafety.of(chosen);
          return ListView(
            padding: const EdgeInsets.only(bottom: NestSpace.huge),
            children: [
              if (failure != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: NestSpace.lg),
                  child: NestBanner(
                    message: AppCopy.failure(failure),
                    tone: NestBannerTone.danger,
                    actionLabel: AppCopy.back,
                    onAction: composer.dismissActionFailure,
                  ),
                ),
              PhotoCaptureCard(
                photo: composer.photo,
                isBusy: composer.isTakingPhoto,
                prompt: HomeCareCopy.beforePrompt,
                promptBody: HomeCareCopy.beforePromptBody,
                semanticLabel: HomeCareCopy.beforePhoto,
                marks: composer.marks,
                onTake: composer.takePhoto,
                onMark: () => _mark(context, composer),
              ),
              if (composer.isMissingPhoto)
                const Padding(
                  padding: EdgeInsets.only(top: NestSpace.sm),
                  child: NestBanner(
                    message: HomeCareCopy.photoMissing,
                    tone: NestBannerTone.warning,
                  ),
                ),
              const SizedBox(height: NestSpace.xxl),
              JobDetailsForm(
                details: composer.details,
                onChanged: composer.updateDetails,
                rooms: board.roomsByName,
                products: board.productsByName,
                helpers: home.helpers,
                problems: composer.shownProblems,
                today: context.read<HouseholdClock>().today,
              ),
              if (chosen.isNotEmpty) ...[
                const SizedBox(height: NestSpace.xxl),
                const NestSectionHeader(title: HomeCareSafetyCopy.title),
                const SizedBox(height: NestSpace.sm),
                if (safety.hasDangers) ...[
                  const NestBanner(
                    message: HomeCareSafetyCopy.composerWarning,
                    tone: NestBannerTone.danger,
                  ),
                  const SizedBox(height: NestSpace.md),
                ],
                SafetyPanel(safety: safety),
              ],
              const SizedBox(height: NestSpace.xxl),
              NestButton(
                label: HomeCareCopy.assign,
                icon: LucideIcons.send,
                isLoading: composer.isSaving,
                onPressed: composer.isSaving
                    ? null
                    : () => _assign(context, composer),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _mark(
    BuildContext context,
    JobComposerController composer,
  ) async {
    final photo = composer.photo;
    if (photo == null) return;
    final marks = await showSpotMarker(
      context: context,
      bytes: photo.bytes,
      aspectRatio: photo.width / photo.height,
      marks: composer.marks,
    );
    if (marks != null) composer.setMarks(marks);
  }

  static Future<void> _assign(
    BuildContext context,
    JobComposerController composer,
  ) async {
    final isAssigned = await composer.assign();
    if (isAssigned && context.mounted) context.pop();
  }
}
