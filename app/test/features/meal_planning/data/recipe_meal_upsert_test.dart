import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/data/recipe_meal_upsert.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Planning a recipe when two phones may plan it at once (recipes ADR-0003
/// §6): a lost race becomes an ingredients update; a real refusal surfaces.
void main() {
  late List<String> writes;
  late bool isOnServer;
  AppFailure? refuseCreate;
  AppFailure? refuseUpdate;
  AppFailure? failServerRead;

  setUp(() {
    writes = [];
    isOnServer = false;
    refuseCreate = null;
    refuseUpdate = null;
    failServerRead = null;
  });

  Future<void> upsert({bool isKnown = false}) => upsertRecipeMeal(
    exists: () async => isKnown,
    existsOnServer: () async {
      final failure = failServerRead;
      if (failure != null) throw failure;
      return isOnServer;
    },
    create: () async {
      final failure = refuseCreate;
      if (failure != null) throw failure;
      writes.add('create');
    },
    updateIngredients: () async {
      final failure = refuseUpdate;
      if (failure != null) throw failure;
      writes.add('ingredients');
    },
  );

  test('a meal nobody has made yet is made in full', () async {
    await upsert();
    expect(writes, ['create']);
  });

  test('a meal already there only has its ingredients rewritten', () async {
    await upsert(isKnown: true);
    expect(writes, ['ingredients']);
  });

  test('a race lost to another phone falls back to the ingredients', () async {
    // The read said it was not there; by the create it was, and the rules
    // refused the create as an update that moves more than ingredients.
    refuseCreate = const PermissionDeniedFailure();
    isOnServer = true;
    await upsert();
    expect(writes, ['ingredients']);
  });

  test('a real refusal — somebody who may only look — surfaces', () async {
    refuseCreate = const PermissionDeniedFailure();
    await expectLater(upsert(), throwsA(isA<PermissionDeniedFailure>()));
    expect(writes, isEmpty);
  });

  test('a viewer who loses the race is refused the update too', () async {
    refuseCreate = const PermissionDeniedFailure();
    refuseUpdate = const PermissionDeniedFailure();
    isOnServer = true;
    await expectLater(upsert(), throwsA(isA<PermissionDeniedFailure>()));
    expect(writes, isEmpty);
  });

  test(
    'a second read that cannot answer leaves the refusal standing',
    () async {
      refuseCreate = const PermissionDeniedFailure();
      failServerRead = const UnavailableFailure();
      await expectLater(upsert(), throwsA(isA<PermissionDeniedFailure>()));
    },
  );

  test(
    'a failure that is not a refusal is never retried as an update',
    () async {
      refuseCreate = const UnavailableFailure();
      isOnServer = true;
      await expectLater(upsert(), throwsA(isA<UnavailableFailure>()));
      expect(writes, isEmpty);
    },
  );
}
