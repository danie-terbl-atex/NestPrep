import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../list_scan/data/list_photo_picker.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/recipe_draft.dart';
import '../model/recipe_import_way.dart';
import '../state/recipe_import_controller.dart';
import 'recipe_import_panels.dart';
import 'recipe_import_start_panel.dart';

/// A link or a photo on its way to a filled builder (recipes ADR-0008). A
/// [sharedLink] starts at once, because the share sheet has already said what
/// leaves the phone; every other way starts on the panel that says it.
class RecipeImportScreen extends StatefulWidget {
  const RecipeImportScreen({
    required this.onOpenBuilder,
    this.sharedLink,
    super.key,
  });

  final ValueChanged<RecipeDraft> onOpenBuilder;
  final String? sharedLink;

  @override
  State<RecipeImportScreen> createState() => _RecipeImportScreenState();
}

class _RecipeImportScreenState extends State<RecipeImportScreen> {
  late final RecipeImportController _controller;
  bool _hasOpenedBuilder = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<RecipeImportController>()..addListener(_follow);
    if (widget.sharedLink case final link?) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _readLink(link));
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_follow);
    super.dispose();
  }

  void _follow() {
    final draft = _controller.draft;
    if (draft == null || _hasOpenedBuilder) return;
    _hasOpenedBuilder = true;
    widget.onOpenBuilder(draft);
  }

  Future<bool> _mayStart() =>
      ensurePremium(context, feature: PremiumFeature.ownRecipes);

  Future<void> _readLink(String link) async {
    if (mounted && await _mayStart()) await _controller.readLink(link);
  }

  Future<void> _pick(ListPhotoSource source) async {
    if (await _mayStart()) await _controller.pick(source);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeImportController>();
    return NestScaffold(
      leading: backLeading(context),
      title: controller.way == RecipeImportWay.link
          ? RecipeImportCopy.linkScreenTitle
          : RecipeImportCopy.snapScreenTitle,
      body: NestTwigWarmUp(
        poses: const [NestTwigPose.welcome, NestTwigPose.thinking],
        child: AnimatedSwitcher(
          duration: NestMotion.of(context).standard,
          child: KeyedSubtree(
            key: ValueKey((controller.step, controller.way)),
            child: switch (controller.step) {
              RecipeImportStep.start => switch (controller.way) {
                RecipeImportWay.link => RecipeImportLinkPanel(
                  initial: widget.sharedLink ?? '',
                  failure: controller.failure,
                  isAiWelcome: controller.isAiWelcome,
                  onRead: _readLink,
                ),
                RecipeImportWay.snap => RecipeImportSnapPanel(
                  failure: controller.failure,
                  isAiWelcome: controller.isAiWelcome,
                  onPick: _pick,
                ),
              },
              RecipeImportStep.readingPage => const RecipeImportWorkingPanel(
                title: RecipeImportCopy.readingPageTitle,
                body: RecipeImportCopy.readingPageBody,
              ),
              RecipeImportStep.askingAi ||
              RecipeImportStep.done => const RecipeImportWorkingPanel(
                title: RecipeImportCopy.askingTitle,
                body: RecipeImportCopy.askingBody,
              ),
              RecipeImportStep.stopped => RecipeImportStoppedPanel(
                onType: () => widget.onOpenBuilder(controller.typedDraft),
              ),
            },
          ),
        ),
      ),
    );
  }
}
