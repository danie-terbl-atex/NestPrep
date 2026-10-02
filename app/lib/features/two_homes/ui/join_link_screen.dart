import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../state/join_link_controller.dart';
import 'join_offer.dart';

/// Accepting the other home's code (household ADR-0004): type it, see exactly
/// what it offers and what will be shared, choose how this home appears, and
/// accept. Then the link waits for the other home to confirm — and the
/// screen says so, rather than pretending it is done.
class JoinLinkScreen extends StatefulWidget {
  const JoinLinkScreen({super.key});

  @override
  State<JoinLinkScreen> createState() => _JoinLinkScreenState();
}

class _JoinLinkScreenState extends State<JoinLinkScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JoinLinkController>();
    final failure = controller.actionFailure;
    final preview = controller.preview;
    final nest = NestTheme.of(context);

    return NestScaffold(
      title: TwoHomesSetupCopy.joinTitle,
      leading: backLeading(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          if (controller.linkId != null && preview != null)
            NestRiseIn(
              child: NestCard(
                variant: NestCardVariant.tinted,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NestIconTile(
                      icon: LucideIcons.hourglass,
                      tint: NestTileTint.basil,
                    ),
                    const SizedBox(height: NestSpace.md),
                    Text(
                      TwoHomesSetupCopy.acceptedTitle(preview.home.name),
                      style: nest.text.title,
                    ),
                    const SizedBox(height: NestSpace.sm),
                    Text(
                      TwoHomesSetupCopy.acceptedBody,
                      style: nest.text.bodySecondary,
                    ),
                    const SizedBox(height: NestSpace.lg),
                    NestButton(
                      label: TwoHomesSetupCopy.done,
                      onPressed: () => _leave(context, controller.householdId),
                    ),
                  ],
                ),
              ),
            )
          else if (preview != null)
            const JoinOffer()
          else ...[
            NestTextField(
              label: TwoHomesSetupCopy.codeLabel,
              controller: _code,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.go,
              onSubmitted: controller.check,
            ),
            const SizedBox(height: NestSpace.lg),
            NestButton(
              label: TwoHomesSetupCopy.checkCode,
              isLoading: controller.isBusy,
              onPressed: controller.isBusy
                  ? null
                  : () => controller.check(_code.text),
            ),
          ],
        ],
      ),
    );
  }
}

/// Back where the person came from — or, from a deep link with nothing under
/// it, to the two-homes list (`FE-17`).
void _leave(BuildContext context, String householdId) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(TwoHomesRoute.pathFor(householdId));
  }
}
