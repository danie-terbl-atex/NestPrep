import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../family_profiles/model/allergen.dart';
import '../../meal_planning/model/ingredient_unit.dart';
import '../../plan_week/model/allergen_words.dart';
import 'own_recipe_ids.dart';
import 'own_recipe_limits.dart';
import 'own_recipe_photo_paths.dart';
import 'own_recipe_save.dart';
import 'recipe.dart';
import 'recipe_context.dart';
import 'recipe_course.dart';
import 'recipe_draft.dart';
import 'recipe_ingredient.dart';
import 'recipe_origin.dart';
import 'recipe_photo.dart';
import 'recipe_photo_cuts.dart';

part 'recipe_form.freezed.dart';

enum RecipeFormProblem {
  noName,
  noMeal,
  noIngredients,
  noSteps,
  badServings,
  badPrepMinutes,
  badCookMinutes,
}

@immutable
sealed class RecipeFormEntry {
  const RecipeFormEntry(this.id);

  final String id;
}

final class RecipeFormHeading extends RecipeFormEntry {
  const RecipeFormHeading({required String id, required this.text}) : super(id);

  final String text;
}

final class RecipeFormLine extends RecipeFormEntry {
  const RecipeFormLine({
    required String id,
    required this.name,
    this.amount,
    this.unit,
    this.note,
  }) : super(id);

  final String name;
  final num? amount;
  final IngredientUnit? unit;
  final String? note;
}

@immutable
final class RecipeFormStep {
  const RecipeFormStep({required this.id, required this.text});

  final String id;
  final String text;
}

@immutable
sealed class RecipeFormPhoto {
  const RecipeFormPhoto({required this.photoId, this.credit, this.sourceUrl});

  final String photoId;
  final String? credit;
  final String? sourceUrl;

  OwnRecipePhotoRef get ref =>
      OwnRecipePhotoRef(photoId: photoId, credit: credit, sourceUrl: sourceUrl);
}

final class KeptRecipeFormPhoto extends RecipeFormPhoto {
  const KeptRecipeFormPhoto({
    required super.photoId,
    required this.stored,
    super.credit,
    super.sourceUrl,
  });

  final RecipePhoto stored;
}

final class NewRecipeFormPhoto extends RecipeFormPhoto {
  const NewRecipeFormPhoto({
    required super.photoId,
    required this.cuts,
    super.credit,
    super.sourceUrl,
  });

  final RecipePhotoCuts cuts;
}

@freezed
abstract class RecipeForm with _$RecipeForm {
  const factory RecipeForm({
    @Default('') String name,
    @Default('') String summary,
    @Default('') String notes,
    @Default(<RecipeContext, RecipeCourse>{})
    Map<RecipeContext, RecipeCourse> placement,
    @Default('4') String servings,
    @Default('') String prepMinutes,
    @Default('') String cookMinutes,
    @Default(<RecipeFormEntry>[]) List<RecipeFormEntry> entries,
    @Default(<RecipeFormStep>[]) List<RecipeFormStep> steps,
    @Default(<Allergen>{}) Set<Allergen> alsoContains,
    @Default(<RecipeFormPhoto>[]) List<RecipeFormPhoto> photos,
    @Default(RecipeOrigin.typed) RecipeOrigin origin,
    String? sourceUrl,
    String? sourceName,
    @Default(0) int lastRowId,
  }) = _RecipeForm;

  const RecipeForm._();

  static const defaultServings = 4;

  static const offeredMeals = [
    RecipeContext.breakfast,
    RecipeContext.lunch,
    RecipeContext.dinner,
  ];

  factory RecipeForm.fromRecipe(Recipe recipe) => const RecipeForm()
      ._withIngredients(recipe.ingredients)
      ._withStepTexts(recipe.steps)
      .copyWith(
        name: recipe.name,
        summary: recipe.summary,
        notes: recipe.notes ?? '',
        placement: {
          for (final context in offeredMeals)
            if (recipe.contexts.contains(context))
              context: recipe.courseIn(context) ?? RecipeCourse.main,
        },
        servings: '${recipe.servings}',
        prepMinutes: '${recipe.prepMinutes}',
        cookMinutes: '${recipe.cookMinutes}',
        alsoContains: recipe.alsoContains,
        photos: [
          for (final photo in [?recipe.photo, ...recipe.gallery])
            if (OwnRecipePhotoPaths.photoIdIn(photo.card) case final photoId?)
              KeptRecipeFormPhoto(
                photoId: photoId,
                stored: photo,
                credit: photo.credit,
                sourceUrl: photo.sourceUrl,
              ),
        ],
        origin: recipe.origin,
        sourceUrl: recipe.sourceUrl,
        sourceName: recipe.sourceName,
      );

  factory RecipeForm.fromDraft(RecipeDraft draft) => const RecipeForm()
      ._withIngredients([
        for (final line in draft.ingredients.take(OwnRecipeLimits.ingredients))
          if (line.name.trim().isNotEmpty) _clippedLine(line),
      ])
      ._withStepTexts([
        for (final step in draft.steps.take(OwnRecipeLimits.steps))
          if (step.trim().isNotEmpty) _clip(step, OwnRecipeLimits.step),
      ])
      .copyWith(
        name: _clip(draft.name, OwnRecipeLimits.name),
        summary: _clip(draft.summary, OwnRecipeLimits.summary),
        notes: _clip(draft.notes ?? '', OwnRecipeLimits.notes),
        placement: {
          for (final context in offeredMeals)
            context: ?draft.placement[context],
        },
        servings: switch (draft.servings) {
          final servings? when servings >= 1 => '$servings',
          _ => '',
        },
        prepMinutes: _minutes(draft.prepMinutes),
        cookMinutes: _minutes(draft.cookMinutes),
        photos: [
          for (final cuts in draft.photos.take(OwnRecipeLimits.photos))
            NewRecipeFormPhoto(
              photoId: OwnRecipeIds.newPhotoId(),
              cuts: cuts,
              credit: switch (draft.sourceName) {
                final name? => _clip(name, OwnRecipeLimits.credit),
                null => null,
              },
            ),
        ],
        origin: draft.origin,
        sourceUrl: draft.sourceUrl,
        sourceName: switch (draft.sourceName) {
          final name? => _clip(name, OwnRecipeLimits.sourceName),
          null => null,
        },
      );

  static bool cutsShort(RecipeDraft draft) =>
      draft.cutShort ||
      draft.ingredients.length > OwnRecipeLimits.ingredients ||
      draft.steps.length > OwnRecipeLimits.steps;

  static String _clip(String text, int limit) {
    final trimmed = text.trim();
    return trimmed.length <= limit ? trimmed : trimmed.substring(0, limit);
  }

  static String _minutes(int? minutes) =>
      minutes == null || minutes < 0 ? '' : '$minutes';

  static RecipeIngredient _clippedLine(RecipeIngredient line) =>
      RecipeIngredient(
        name: _clip(line.name, OwnRecipeLimits.ingredientName),
        quantity: switch (line.quantity) {
          final quantity?
              when quantity > 0 && quantity <= OwnRecipeLimits.quantity =>
            quantity,
          _ => null,
        },
        unit: IngredientUnit.fromCode(line.unit)?.code,
        note: switch (line.note) {
          final note? => _clip(note, OwnRecipeLimits.ingredientNote),
          null => null,
        },
        group: switch (line.group) {
          final group? => _clip(group, OwnRecipeLimits.ingredientGroup),
          null => null,
        },
      );

  RecipeForm _withIngredients(List<RecipeIngredient> lines) {
    final groups = <String?, List<RecipeIngredient>>{null: []};
    for (final line in lines) {
      groups.putIfAbsent(line.group, () => []).add(line);
    }
    var form = this;
    for (final MapEntry(key: group, value: members) in groups.entries) {
      if (group != null) form = form.withHeading(group);
      for (final line in members) {
        form = form.withLine(
          name: line.name,
          amount: line.quantity,
          unit: IngredientUnit.fromCode(line.unit),
          note: line.note,
        );
      }
    }
    return form;
  }

  RecipeForm _withStepTexts(List<String> texts) =>
      texts.fold(this, (form, text) => form.withStep(text));

  List<RecipeFormLine> get lines =>
      entries.whereType<RecipeFormLine>().toList();

  bool get canAddLine => lines.length < OwnRecipeLimits.ingredients;
  bool get canAddStep => steps.length < OwnRecipeLimits.steps;
  bool get canAddPhoto => photos.length < OwnRecipeLimits.photos;
  int get photosLeft => OwnRecipeLimits.photos - photos.length;

  List<RecipeIngredient> get ingredients {
    String? group;
    final ingredients = <RecipeIngredient>[];
    for (final entry in entries) {
      switch (entry) {
        case RecipeFormHeading(:final text) when text.trim().isNotEmpty:
          group = text.trim();
        case RecipeFormHeading():
          break;
        case final RecipeFormLine line:
          ingredients.add(_ingredientOf(line, group));
      }
    }
    return ingredients;
  }

  static RecipeIngredient _ingredientOf(RecipeFormLine line, String? group) {
    final note = line.note?.trim() ?? '';
    return RecipeIngredient(
      name: line.name.trim(),
      quantity: line.amount,
      unit: line.amount == null ? null : line.unit?.code,
      note: note.isEmpty ? null : note,
      group: group,
    );
  }

  // The same two reads `allergensOfOwnRecipe` makes on the server.
  Set<Allergen> get derivedAllergens {
    final ingredients = this.ingredients;
    return {
      ...AllergenWords.mentionedIn(
        [
          name,
          for (final line in ingredients) ...[line.name, line.note ?? ''],
          summary,
        ].join(' '),
      ),
      ...AllergenWords.mentionedIn(
        [
          notes,
          for (final step in steps) step.text,
          for (final line in ingredients) line.group ?? '',
        ].join(' '),
      ),
    };
  }

  List<RecipeFormProblem> get problems => [
    if (name.trim().isEmpty) RecipeFormProblem.noName,
    if (placement.isEmpty) RecipeFormProblem.noMeal,
    if (lines.isEmpty) RecipeFormProblem.noIngredients,
    if (steps.isEmpty) RecipeFormProblem.noSteps,
    if (!_isWholeIn(servings, 1, OwnRecipeLimits.servings))
      RecipeFormProblem.badServings,
    if (prepMinutes.isNotEmpty &&
        !_isWholeIn(prepMinutes, 0, OwnRecipeLimits.minutes))
      RecipeFormProblem.badPrepMinutes,
    if (cookMinutes.isNotEmpty &&
        !_isWholeIn(cookMinutes, 0, OwnRecipeLimits.minutes))
      RecipeFormProblem.badCookMinutes,
  ];

  static bool _isWholeIn(String text, int lowest, int highest) =>
      switch (int.tryParse(text)) {
        final number? => number >= lowest && number <= highest,
        null => false,
      };

  OwnRecipeSave toSave() {
    final cover = photos.firstOrNull;
    final tips = notes.trim();
    final source = sourceName?.trim() ?? '';
    return OwnRecipeSave(
      name: name.trim(),
      summary: summary.trim(),
      notes: tips.isEmpty ? null : tips,
      placement: placement,
      ingredients: ingredients,
      steps: [for (final step in steps) step.text.trim()],
      servings: int.parse(servings),
      prepMinutes: int.tryParse(prepMinutes) ?? 0,
      cookMinutes: int.tryParse(cookMinutes) ?? 0,
      origin: origin,
      sourceUrl: sourceUrl,
      sourceName: source.isEmpty ? null : source,
      alsoContains: alsoContains,
      photo: cover?.ref,
      gallery: [for (final photo in photos.skip(1)) photo.ref],
    );
  }

  RecipeForm withMeal(RecipeContext context, {required bool isOn}) => copyWith(
    placement: {
      for (final MapEntry(key: meal, value: course) in placement.entries)
        if (meal != context) meal: course,
      if (isOn) context: placement[context] ?? RecipeCourse.main,
    },
  );

  RecipeForm withCourse(RecipeContext context, RecipeCourse course) =>
      copyWith(placement: {...placement, context: course});

  RecipeForm withLine({
    required String name,
    num? amount,
    IngredientUnit? unit,
    String? note,
  }) => copyWith(
    lastRowId: lastRowId + 1,
    entries: [
      ...entries,
      RecipeFormLine(
        id: 'row-${lastRowId + 1}',
        name: name,
        amount: amount,
        unit: unit,
        note: note,
      ),
    ],
  );

  RecipeForm withHeading(String text) => copyWith(
    lastRowId: lastRowId + 1,
    entries: [
      ...entries,
      RecipeFormHeading(id: 'row-${lastRowId + 1}', text: text),
    ],
  );

  RecipeForm withEntryChanged(RecipeFormEntry changed) => copyWith(
    entries: [
      for (final entry in entries) entry.id == changed.id ? changed : entry,
    ],
  );

  RecipeForm withoutEntry(String id) => copyWith(
    entries: [
      for (final entry in entries)
        if (entry.id != id) entry,
    ],
  );

  RecipeForm withEntryMoved(int from, int to) =>
      copyWith(entries: _moved(entries, from, to));

  RecipeForm withStep(String text) => copyWith(
    lastRowId: lastRowId + 1,
    steps: [
      ...steps,
      RecipeFormStep(id: 'row-${lastRowId + 1}', text: text),
    ],
  );

  RecipeForm withStepChanged(String id, String text) => copyWith(
    steps: [
      for (final step in steps)
        step.id == id ? RecipeFormStep(id: id, text: text) : step,
    ],
  );

  RecipeForm withoutStep(String id) => copyWith(
    steps: [
      for (final step in steps)
        if (step.id != id) step,
    ],
  );

  RecipeForm withStepMoved(int from, int to) =>
      copyWith(steps: _moved(steps, from, to));

  RecipeForm withAllergenToggled(Allergen allergen) => copyWith(
    alsoContains: alsoContains.contains(allergen)
        ? ({...alsoContains}..remove(allergen))
        : {...alsoContains, allergen},
  );

  RecipeForm withPhoto(RecipeFormPhoto photo) =>
      canAddPhoto ? copyWith(photos: [...photos, photo]) : this;

  RecipeForm withoutPhoto(String photoId) => copyWith(
    photos: [
      for (final photo in photos)
        if (photo.photoId != photoId) photo,
    ],
  );

  RecipeForm withCover(String photoId) => copyWith(
    photos: [
      ...photos.where((photo) => photo.photoId == photoId),
      ...photos.where((photo) => photo.photoId != photoId),
    ],
  );

  static List<T> _moved<T>(List<T> rows, int from, int to) {
    final moved = [...rows];
    moved.insert(to, moved.removeAt(from));
    return moved;
  }
}
