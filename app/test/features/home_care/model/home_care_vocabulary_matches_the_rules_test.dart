import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/cleaning_job.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/home_care_room.dart';
import 'package:nestprep/features/home_care/model/job_photo.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/home_care/model/product_kind.dart';
import 'package:nestprep/features/home_care/model/room_kind.dart';
import 'package:nestprep/features/home_care/model/spot_mark.dart';

/// The names and limits written on both sides of the client/server line
/// (the vault lesson on contracts between two languages). A kind the app
/// offers and the rules refuse is a save that fails for no reason a parent
/// can see; a status spelt differently is a job that can never move.
void main() {
  final repoRoot = Directory.current.parent;
  final rules = File(
    '${repoRoot.path}/rules/firestore/household/home_care.rules',
  ).readAsStringSync();

  /// The quoted words inside the list a rules function tests `in`.
  Set<String> listIn(String function) {
    final start = rules.indexOf('function $function(');
    expect(start, isNonNegative, reason: '$function is not in the rules');
    final list = RegExp(r'\[([^\]]*)\]').firstMatch(rules.substring(start));
    return {
      for (final match in RegExp(r"'(\w+)'").allMatches(list!.group(1)!))
        match.group(1)!,
    };
  }

  test('every room kind is one the rules accept, and no more', () {
    expect(listIn('homeCareIsRoomKind'), {
      for (final kind in RoomKind.values) kind.name,
    });
  });

  test('every product kind is one the rules accept, and no more', () {
    expect(listIn('homeCareIsProduct'), {
      for (final kind in ProductKind.values) kind.name,
    });
  });

  test('every status the app writes is a status the rules move between', () {
    for (final status in JobStatus.values) {
      expect(rules, contains("'${status.name}'"));
    }
  });

  test('the rules keep what the fields let somebody type', () {
    expect(
      rules,
      contains('homeCareIsName(job.title, ${CleaningJob.titleLimit})'),
    );
    expect(
      rules,
      contains('homeCareIsName(job.note, ${CleaningJob.noteLimit})'),
    );
    expect(rules, contains('job.steps.size() <= ${CleaningJob.stepLimit}'));
    expect(
      rules,
      contains('job.productIds.size() <= ${CleaningJob.productLimit}'),
    );
    expect(rules, contains('marks.size() <= ${SpotMark.limit}'));
    expect(
      rules,
      contains(
        'homeCareIsName(request.resource.data.name, ${HomeCareRoom.nameLimit})',
      ),
    );
    expect(
      rules,
      contains('homeCareIsName(product.name, ${HomeCareProduct.nameLimit})'),
    );
    expect(
      rules,
      contains('homeCareIsName(value, ${HomeCareProduct.textLimit})'),
    );
  });

  test('photos are named the way the rules check them', () {
    expect(
      rules,
      contains(
        "homeCareIsPhoto(request.resource.data.beforePhoto, '${JobPhoto.beforeId}')",
      ),
    );
    expect(JobPhoto.afterIdFor(3), 'after-3');
    expect(rules, contains("'after-' + string(after.revision)"));
  });
}
