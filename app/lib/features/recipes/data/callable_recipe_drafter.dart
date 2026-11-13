import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../list_scan/model/list_photo.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../model/recipe_draft_reading.dart';
import '../model/recipe_page.dart';
import 'recipe_drafter.dart';

final class CallableRecipeDrafter implements RecipeDrafter {
  const CallableRecipeDrafter(this._functions);

  final FirebaseFunctions _functions;

  /// A little past the Function's sixty seconds, so the phone hears its answer
  /// rather than its own timeout.
  static const _timeout = Duration(seconds: 70);

  @override
  Future<RecipeDraftReading> fromPage({
    required String householdId,
    required RecipePage page,
  }) => _ask({'householdId': householdId, 'page': page.toWire()});

  @override
  Future<RecipeDraftReading> fromPhoto({
    required String householdId,
    required ListPhoto photo,
  }) async {
    if (photo.isTooLarge) {
      throw const ListScanFailure(ListScanProblem.listPhotoTooLarge);
    }
    return _ask({
      'householdId': householdId,
      'photo': {
        'mimeType': ListPhoto.mimeType,
        'data': base64Encode(photo.bytes),
      },
    });
  }

  Future<RecipeDraftReading> _ask(Map<String, Object?> input) async {
    try {
      final result = await _functions
          .httpsCallable(
            'draftRecipe',
            options: HttpsCallableOptions(timeout: _timeout),
          )
          .call<Object?>(input);
      return RecipeDraftReading.fromWire(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromRecipeDraftCallable(error);
    }
  }
}

AppFailure failureFromRecipeDraftCallable(FirebaseFunctionsException error) {
  AppLog.failure('draft recipe callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason == 'premiumRequired') {
    return const PremiumRequiredFailure(PremiumFeature.ownRecipes);
  }
  if (reason is String) {
    if (_named(OwnRecipeProblem.values, reason) case final problem?) {
      return OwnRecipeFailure(problem);
    }
    if (_named(ListScanProblem.values, reason) case final problem?) {
      return ListScanFailure(problem);
    }
    if (_named(AiProblem.values, reason) case final problem?) {
      return AiFailure(problem);
    }
    if (_named(HouseholdProblem.values, reason) case final problem?) {
      return HouseholdFailure(problem);
    }
  }
  return switch (error.code) {
    'unauthenticated' => const HouseholdFailure(HouseholdProblem.notSignedIn),
    'permission-denied' => const PermissionDeniedFailure(),
    'deadline-exceeded' => const AiFailure(AiProblem.aiUnavailable),
    'unavailable' => const UnavailableFailure(),
    _ => UnknownFailure(error),
  };
}

T? _named<T extends Enum>(List<T> values, String name) =>
    values.where((value) => value.name == name).firstOrNull;
