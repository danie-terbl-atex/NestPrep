import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/recipe_document.dart';
import '../model/recipe_draft_reading.dart';
import 'callable_recipe_drafter.dart';
import 'recipe_document_reader.dart';

final class CallableRecipeDocumentReader implements RecipeDocumentReader {
  const CallableRecipeDocumentReader(this._functions);

  final FirebaseFunctions _functions;

  /// A little past the Functions' two minutes.
  static const _timeout = Duration(seconds: 130);

  static const _unreadable = AiFailure(AiProblem.aiUnreadable);

  @override
  Future<RecipeDocumentScan> scan({
    required String householdId,
    required String documentName,
    required List<DocumentScanPage> pages,
  }) async {
    final data = await _call('scanRecipeDocument', {
      'householdId': householdId,
      'documentName': documentName,
      'pages': [
        for (final page in pages)
          {'number': page.number, 'data': base64Encode(page.jpeg)},
      ],
    });
    return scanFromWire(data);
  }

  @override
  Future<DocumentRecipeReading> draft({
    required String householdId,
    required String documentName,
    required String recipeName,
    required List<DocumentReadPage> pages,
  }) async {
    final data = await _call('draftDocumentRecipe', {
      'householdId': householdId,
      'documentName': documentName,
      'recipeName': recipeName,
      'pages': [
        for (final page in pages)
          {
            'number': page.number,
            'top': base64Encode(page.top),
            'bottom': base64Encode(page.bottom),
            'whole': switch (page.whole) {
              final whole? => base64Encode(whole),
              null => null,
            },
          },
      ],
    });
    return readingFromWire(data);
  }

  static RecipeDocumentScan scanFromWire(Object? data) {
    if (data is! Map) throw _unreadable;
    final callsLeft = data['callsLeft'];
    final recipes = data['recipes'];
    if (callsLeft is! num || recipes is! List) throw _unreadable;
    return RecipeDocumentScan(
      callsLeft: callsLeft.toInt(),
      recipes: [
        for (final Object? recipe in recipes)
          if (recipe
              case {
                'name': final String name,
                'pages': final List<Object?> pages,
              }
              when name.trim().isNotEmpty && _pages(pages).isNotEmpty)
            FoundDocumentRecipe(
              name: name.trim(),
              summary: switch (recipe['summary']) {
                final String summary => summary,
                _ => '',
              },
              pages: _pages(pages),
              usesPages: switch (recipe['usesPages']) {
                final List<Object?> uses => _pages(uses),
                _ => const [],
              },
            ),
      ],
    );
  }

  static DocumentRecipeReading readingFromWire(Object? data) {
    final reading = RecipeDraftReading.fromWire(data);
    return DocumentRecipeReading(
      draft: reading.draft,
      callsLeft: reading.callsLeft,
      photo: data is Map ? _photo(data['photo']) : null,
    );
  }

  static List<int> _pages(List<Object?> values) => [
    for (final value in values)
      if (value is num) value.toInt(),
  ];

  static DocumentPhoto? _photo(Object? value) {
    if (value
        case {
          'page': final num page,
          'box': [
            final num top,
            final num left,
            final num bottom,
            final num right,
          ],
        }
        when bottom > top && right > left) {
      return DocumentPhoto(
        page: page.toInt(),
        box: DocumentPhotoBox(
          top: top.toInt(),
          left: left.toInt(),
          bottom: bottom.toInt(),
          right: right.toInt(),
        ),
      );
    }
    return null;
  }

  Future<Object?> _call(String name, Map<String, Object?> input) async {
    try {
      final result = await _functions
          .httpsCallable(name, options: HttpsCallableOptions(timeout: _timeout))
          .call<Object?>(input);
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      throw failureFromRecipeDraftCallable(error);
    }
  }
}
