import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/data/callable_shift_directory.dart';
import 'package:nestprep/features/nanny_hub/data/firestore_photo_update_repository.dart';
import 'package:nestprep/features/nanny_hub/data/nanny_paths.dart';
import 'package:nestprep/features/nanny_hub/model/nanny_limits.dart';
import 'package:nestprep/shared/flags/firestore_feature_flag_source.dart';

/// The nanny hub's V2 names and numbers are written in the app, the rules
/// partials, the Storage rules and `setCarerShiftOnly` (nanny-hub ADR-0004 to
/// ADR-0007). Written down twice is a contract, and a contract between two
/// languages needs a test that reads both: widen the grace in the app and not
/// the rules, and a carer is shown codes the server refuses.
void main() {
  String read(String path) => File('../$path').readAsStringSync();

  final window = read('rules/firestore/shared/shift_window.rules');
  final access = read('rules/firestore/household/nanny_shift_access.rules');
  final photos = read('rules/firestore/household/nanny_photo_updates.rules');
  final pickups = read('rules/firestore/household/nanny_pickups.rules');
  final appConfig = read('rules/firestore/root/app_config.rules');
  final storage = read('storage.rules');
  final shiftOnly = read('functions/src/nanny_hub/set_carer_shift_only.ts');
  final schemas = read('functions/src/nanny_hub/schemas.ts');

  group('the booked-shift window', () {
    final grace = "duration.value(${NannyLimits.shiftGrace.inMinutes}, 'm')";

    test('opens and closes with the same grace in the app, the Firestore '
        'rules and the Storage rules', () {
      expect(grace.allMatches(window), hasLength(2));
      expect(grace.allMatches(storage), hasLength(2));
      expect(
        RegExp(r"duration\.value\(\d+, 'm'\)").allMatches(window),
        hasLength(2),
      );
    });

    test('a booking is at most as long in the rules as in the app', () {
      expect(
        access,
        contains(
          "data.startsAt + duration.value(${NannyLimits.bookingLength.inHours}, 'h')",
        ),
      );
    });

    test('shift-only is the same household field in the rules and the '
        'Function', () {
      expect(window, contains("household.get('shiftOnly', {})"));
      expect(storage, contains("get('shiftOnly', {})"));
      expect(shiftOnly, contains(r'`shiftOnly.${input.memberId}`'));
    });

    test('the callable is named and shaped as the app calls it', () {
      final directory = read(
        'app/lib/features/nanny_hub/data/callable_shift_directory.dart',
      );
      expect(directory, contains("httpsCallable('setCarerShiftOnly')"));
      for (final field in ['householdId', 'memberId', 'shiftOnly']) {
        expect(directory, contains("'$field':"));
        expect(schemas, contains('$field:'));
      }
      expect(CallableShiftDirectory, isNotNull);
    });
  });

  group('the collections', () {
    test('are named the same in the app and the rules', () {
      expect(photos, contains('/${NannyPaths.photoUpdates}/{updateId}'));
      expect(access, contains('/${NannyPaths.bookings}/{bookingId}'));
      expect(access, contains('/${NannyPaths.passes}/{memberId}'));
      expect(access, contains('/${NannyPaths.secrets}/{secretId}'));
      expect(window, contains('/${NannyPaths.passes}/'));
      expect(window, contains('/${NannyPaths.bookings}/'));
      expect(storage, contains('/${NannyPaths.passes}/'));
      expect(pickups, contains('/${NannyPaths.pickupPeople}/{personId}'));
      expect(pickups, contains('/${NannyPaths.schoolRuns}/{runId}'));
      expect(pickups, contains('/${NannyPaths.pickupChanges}/{changeId}'));
    });

    test('the switches live where the rules let everybody read them', () {
      expect(
        appConfig,
        contains('match /${FirestoreFeatureFlagSource.collection}/{configId}'),
      );
      expect(
        appConfig,
        contains("configId == '${FirestoreFeatureFlagSource.document}'"),
      );
    });
  });

  group('the limits', () {
    test('a photo update’s caption, children and delivery', () {
      expect(
        photos,
        contains(
          "isNannyOptionalText(data.get('caption', null), ${NannyLimits.photoCaption})",
        ),
      );
      expect(
        photos,
        contains('data.childIds.size() <= ${NannyLimits.photoUpdateChildren}'),
      );
      expect(
        photos,
        contains(
          "data.delivery == {'state': "
          "'${FirestorePhotoUpdateRepository.pendingDelivery['state']}'}",
        ),
      );
    });

    test('a booking’s note and a house code’s words', () {
      expect(
        access,
        contains(
          "isNannyOptionalText(data.get('note', null), ${NannyLimits.bookingNote})",
        ),
      );
      expect(
        access,
        contains('isNannyText(data.label, ${NannyLimits.secretLabel})'),
      );
      expect(
        access,
        contains('isNannyText(data.value, ${NannyLimits.secretValue})'),
      );
      expect(
        access,
        contains(
          "isNannyOptionalText(data.get('note', null), ${NannyLimits.secretNote})",
        ),
      );
    });

    test('who may collect, and the school run', () {
      expect(
        pickups,
        contains('isNannyText(data.name, ${NannyLimits.pickupName})'),
      );
      expect(
        pickups,
        contains(
          'isNannyText(data.relationship, ${NannyLimits.pickupRelationship})',
        ),
      );
      expect(
        pickups,
        contains(
          "isNannyOptionalText(data.get('idNote', null), ${NannyLimits.pickupIdNote})",
        ),
      );
      expect(
        pickups,
        contains('data.childIds.size() <= ${NannyLimits.pickupChildren}'),
      );
      expect(pickups, contains('${NannyLimits.schoolRunPlace})'));
      expect(pickups, contains('${NannyLimits.pickupChangeNote})'));
    });
  });
}
