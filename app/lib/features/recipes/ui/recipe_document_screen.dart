import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe_draft.dart';
import '../state/recipe_document_controller.dart';
import 'recipe_document_panels.dart';
import 'recipe_import_panels.dart';

/// A PDF on its way to the household's recipes (recipes ADR-0009).
class RecipeDocumentScreen extends StatefulWidget {
  const RecipeDocumentScreen({
    required this.onOpenBuilder,
    required this.onFinish,
    required this.onSeeRecipes,
    required this.onBack,
    super.key,
  });

  /// The one recipe of a one-recipe PDF, to check and save like a link's.
  final ValueChanged<RecipeDraft> onOpenBuilder;

  /// A recipe of several that could not be saved as it was.
  final ValueChanged<RecipeDraft> onFinish;
  final VoidCallback onSeeRecipes;
  final VoidCallback onBack;

  @override
  State<RecipeDocumentScreen> createState() => _RecipeDocumentScreenState();
}

class _RecipeDocumentScreenState extends State<RecipeDocumentScreen> {
  late final RecipeDocumentController _controller;
  bool _hasOpenedBuilder = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<RecipeDocumentController>()
      ..addListener(_follow);
  }

  @override
  void dispose() {
    _controller.removeListener(_follow);
    super.dispose();
  }

  void _follow() {
    final draft = _controller.builderDraft;
    if (draft == null || _hasOpenedBuilder) return;
    _hasOpenedBuilder = true;
    widget.onOpenBuilder(draft);
  }

  Future<void> _leave() async {
    if (!_controller.isImporting) return widget.onBack();
    final isSure = await showNestConfirm(
      context: context,
      title: RecipeDocumentCopy.leaveTitle,
      message: RecipeDocumentCopy.leaveMessage,
      confirmLabel: RecipeDocumentCopy.leaveConfirm,
      cancelLabel: RecipeDocumentCopy.leaveCancel,
      isDangerous: true,
    );
    if (isSure == true && mounted) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeDocumentController>();
    return PopScope(
      canPop: !controller.isImporting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: NestScaffold(
        leading: NestIconButton(
          icon: LucideIcons.arrowLeft,
          label: AppCopy.back,
          onPressed: _leave,
        ),
        title: RecipeDocumentCopy.screenTitle,
        body: NestTwigWarmUp(
          poses: const [NestTwigPose.welcome, NestTwigPose.thinking],
          child: AnimatedSwitcher(
            duration: NestMotion.of(context).standard,
            child: KeyedSubtree(
              key: ValueKey(controller.step),
              child: switch (controller.step) {
                RecipeDocumentStep.start ||
                RecipeDocumentStep.stopped => RecipeDocumentStartPanel(
                  failure: controller.failure,
                  onChoose: controller.pick,
                  sharedName: controller.offeredName,
                  onReadShared: controller.readOffered,
                ),
                RecipeDocumentStep.opening => RecipeImportWorkingPanel(
                  title: RecipeDocumentCopy.openingTitle,
                  body: RecipeDocumentCopy.openingBody(
                    controller.pagesDrawn,
                    controller.pageCount,
                  ),
                ),
                RecipeDocumentStep.scanning => const RecipeImportWorkingPanel(
                  title: RecipeDocumentCopy.scanningTitle,
                  body: RecipeDocumentCopy.scanningBody,
                ),
                RecipeDocumentStep.drafting => const RecipeImportWorkingPanel(
                  title: RecipeDocumentCopy.draftingTitle,
                  body: RecipeDocumentCopy.draftingBody,
                ),
                RecipeDocumentStep.nothingFound => RecipeDocumentNothingPanel(
                  onChoose: controller.pick,
                ),
                RecipeDocumentStep.choosing =>
                  const RecipeDocumentChoosePanel(),
                RecipeDocumentStep.importing => RecipeDocumentImportPanel(
                  onFinish: widget.onFinish,
                  onSeeRecipes: widget.onSeeRecipes,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
