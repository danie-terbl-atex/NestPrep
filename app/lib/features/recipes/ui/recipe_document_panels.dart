import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../model/recipe_document.dart';
import '../model/recipe_draft.dart';
import '../state/recipe_document_controller.dart';

class RecipeDocumentStartPanel extends StatelessWidget {
  const RecipeDocumentStartPanel({
    required this.failure,
    required this.onChoose,
    this.sharedName,
    this.onReadShared,
    super.key,
  });

  final AppFailure? failure;
  final VoidCallback onChoose;

  /// A PDF shared from another app, read only once the member says so.
  final String? sharedName;
  final VoidCallback? onReadShared;

  @override
  Widget build(BuildContext context) {
    final shown = failure;
    final shared = sharedName;
    return ListView(
      key: const ValueKey('recipe-document-start'),
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (shown != null) ...[
          NestBanner(
            message: AppCopy.failure(shown),
            tone: NestBannerTone.danger,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        NestRiseIn(
          child: _Card(
            icon: LucideIcons.fileText,
            tint: NestTileTint.butter,
            title: shared == null
                ? RecipeDocumentCopy.heroTitle
                : RecipeDocumentCopy.sharedTitle,
            body: shared == null
                ? RecipeDocumentCopy.heroBody
                : RecipeDocumentCopy.sharedBody(shared),
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        if (shared != null) ...[
          NestRiseIn(
            index: 1,
            child: NestButton(
              key: const ValueKey('recipe-document-read-shared'),
              label: RecipeDocumentCopy.readShared(shared),
              icon: LucideIcons.fileText,
              onPressed: onReadShared,
            ),
          ),
          const SizedBox(height: NestSpace.md),
        ],
        NestRiseIn(
          index: 1,
          child: NestButton(
            key: const ValueKey('recipe-document-choose'),
            label: shown == null && shared == null
                ? RecipeDocumentCopy.choose
                : RecipeDocumentCopy.chooseAnother,
            icon: LucideIcons.fileText,
            variant: shared == null
                ? NestButtonVariant.primary
                : NestButtonVariant.tonal,
            onPressed: onChoose,
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        const NestRiseIn(index: 2, child: _Privacy()),
      ],
    );
  }
}

class RecipeDocumentNothingPanel extends StatelessWidget {
  const RecipeDocumentNothingPanel({required this.onChoose, super.key});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('recipe-document-nothing'),
    padding: const EdgeInsets.only(bottom: NestSpace.huge),
    children: [
      const NestRiseIn(
        child: _Card(
          icon: LucideIcons.circleSlash,
          tint: NestTileTint.butter,
          title: RecipeDocumentCopy.nothingTitle,
          body: RecipeDocumentCopy.nothingBody,
        ),
      ),
      const SizedBox(height: NestSpace.xl),
      NestButton(
        key: const ValueKey('recipe-document-choose-another'),
        label: RecipeDocumentCopy.chooseAnother,
        icon: LucideIcons.fileText,
        variant: NestButtonVariant.tonal,
        onPressed: onChoose,
      ),
    ],
  );
}

class RecipeDocumentChoosePanel extends StatelessWidget {
  const RecipeDocumentChoosePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeDocumentController>();
    final found = controller.found;
    final chosen = controller.chosenCount;
    return Column(
      key: const ValueKey('recipe-document-choosing'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            children: [
              Text(
                RecipeDocumentCopy.foundTitle(found.length),
                style: nest.text.title.copyWith(color: nest.colors.ink),
              ),
              const SizedBox(height: NestSpace.xs),
              Text(
                RecipeDocumentCopy.foundIn(controller.documentName),
                style: nest.text.bodySecondary,
              ),
              const SizedBox(height: NestSpace.lg),
              for (var at = 0; at < found.length; at++)
                _ChoiceRow(at: at, recipe: found[at]),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          key: const ValueKey('recipe-document-import'),
          label: RecipeDocumentCopy.importAction(chosen),
          icon: LucideIcons.sparkles,
          onPressed: chosen == 0 ? null : controller.importChosen,
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          [
            RecipeDocumentCopy.usesReads(chosen, controller.callsLeft),
            if (controller.mostChosen < found.length)
              RecipeDocumentCopy.mostAtOnce(controller.mostChosen),
            RecipeDocumentCopy.savedStraight,
          ].join(' '),
          style: nest.text.bodySecondary,
        ),
      ],
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.at, required this.recipe});

  final int at;
  final FoundDocumentRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeDocumentController>();
    final isChosen = controller.isChosen(at);
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.sm),
      child: Semantics(
        checked: isChosen,
        child: NestListRow(
          key: ValueKey('recipe-document-row-$at'),
          title: recipe.name,
          subtitle: [
            if (recipe.summary.isNotEmpty) recipe.summary,
            RecipeDocumentCopy.pagesOf(recipe.pages),
          ].join(' · '),
          isSelected: isChosen,
          leading: _Thumbnail(recipe: recipe),
          trailing: Icon(
            isChosen ? LucideIcons.circleCheck : LucideIcons.circle,
            color: isChosen ? nest.colors.accent : nest.colors.inkTertiary,
          ),
          onTap: () => controller.toggle(at),
        ),
      ),
    );
  }
}

class RecipeDocumentImportPanel extends StatelessWidget {
  const RecipeDocumentImportPanel({
    required this.onFinish,
    required this.onSeeRecipes,
    super.key,
  });

  final ValueChanged<RecipeDraft> onFinish;
  final VoidCallback onSeeRecipes;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeDocumentController>();
    final isImporting = controller.isImporting;
    final rows = controller.rows;
    return ListView(
      key: const ValueKey('recipe-document-importing'),
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            isImporting
                ? RecipeDocumentCopy.importingTitle
                : RecipeDocumentCopy.doneTitle(controller.savedCount),
            style: nest.text.title.copyWith(color: nest.colors.ink),
          ),
        ),
        const SizedBox(height: NestSpace.xs),
        Text(
          isImporting
              ? RecipeDocumentCopy.importingBody
              : RecipeDocumentCopy.doneBody,
          style: nest.text.bodySecondary,
        ),
        const SizedBox(height: NestSpace.lg),
        for (var at = 0; at < rows.length; at++)
          _ImportRow(
            at: at,
            row: rows[at],
            onFinish: onFinish,
            onRetry: () => controller.retry(at),
          ),
        if (!isImporting && controller.savedCount > 0) ...[
          const SizedBox(height: NestSpace.lg),
          NestButton(
            key: const ValueKey('recipe-document-see'),
            label: RecipeDocumentCopy.seeThem,
            icon: LucideIcons.bookHeart,
            onPressed: onSeeRecipes,
          ),
        ],
      ],
    );
  }
}

class _ImportRow extends StatelessWidget {
  const _ImportRow({
    required this.at,
    required this.row,
    required this.onFinish,
    required this.onRetry,
  });

  final int at;
  final DocumentImportRow row;
  final ValueChanged<RecipeDraft> onFinish;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final failure = row.failure;
    final draft = row.draft;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.sm),
      child: NestListRow(
        key: ValueKey('recipe-document-import-$at'),
        title: row.recipe.name,
        subtitle: switch (row.state) {
          DocumentImportState.waiting => RecipeDocumentCopy.rowWaiting,
          DocumentImportState.reading => RecipeDocumentCopy.rowReading,
          DocumentImportState.saved => RecipeDocumentCopy.rowSaved,
          DocumentImportState.notARecipe => RecipeDocumentCopy.rowNotARecipe,
          DocumentImportState.unfinished => RecipeDocumentCopy.rowUnfinished,
          DocumentImportState.failed =>
            failure == null
                ? RecipeImportCopy.stoppedTitle
                : AppCopy.failure(failure),
        },
        leading: _Thumbnail(recipe: row.recipe),
        trailing: switch (row.state) {
          DocumentImportState.waiting => Icon(
            LucideIcons.clock,
            color: c.inkTertiary,
          ),
          DocumentImportState.reading => SizedBox.square(
            dimension: NestSize.iconSmall,
            child: CircularProgressIndicator(
              strokeWidth: NestStroke.focus,
              color: c.ink,
            ),
          ),
          DocumentImportState.saved => Icon(
            LucideIcons.circleCheck,
            color: c.success,
          ),
          DocumentImportState.notARecipe => Icon(
            LucideIcons.circleSlash,
            color: c.inkTertiary,
          ),
          DocumentImportState.unfinished || DocumentImportState.failed => Icon(
            LucideIcons.circleAlert,
            color: c.warning,
          ),
        },
        footer: switch ((row.state, draft)) {
          (DocumentImportState.unfinished, final draft?) => NestButton(
            key: ValueKey('recipe-document-finish-$at'),
            label: RecipeDocumentCopy.finishIt,
            icon: LucideIcons.pencilLine,
            size: NestButtonSize.small,
            variant: NestButtonVariant.tonal,
            onPressed: () => onFinish(draft),
          ),
          (DocumentImportState.failed, _) => NestButton(
            key: ValueKey('recipe-document-retry-$at'),
            label: RecipeDocumentCopy.tryAgain,
            icon: LucideIcons.refreshCw,
            size: NestButtonSize.small,
            variant: NestButtonVariant.tonal,
            onPressed: onRetry,
          ),
          _ => null,
        },
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.recipe});

  static const _width = 44.0;
  static const _height = 60.0;

  final FoundDocumentRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final page = context.read<RecipeDocumentController>().thumbnailOf(recipe);
    if (page == null) {
      return const NestIconTile(
        icon: LucideIcons.fileText,
        tint: NestTileTint.butter,
        size: NestSize.avatarMedium,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(NestRadius.xs),
      child: Image.memory(
        page,
        width: _width,
        height: _height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final NestTileTint tint;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NestIconTile(icon: icon, tint: tint),
          const SizedBox(height: NestSpace.md),
          Text(title, style: nest.text.title.copyWith(color: nest.colors.ink)),
          const SizedBox(height: NestSpace.sm),
          Text(
            body,
            style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

class _Privacy extends StatelessWidget {
  const _Privacy();

  @override
  Widget build(BuildContext context) => const NestToneRow(
    key: ValueKey('recipe-document-privacy'),
    icon: LucideIcons.lock,
    title: RecipeDocumentCopy.privacyTitle,
    subtitle: RecipeDocumentCopy.privacyBody,
  );
}
