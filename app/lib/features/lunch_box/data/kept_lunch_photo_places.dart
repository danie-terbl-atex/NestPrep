import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../shared/time/calendar_date.dart';

/// Where each child's box on each day was last pictured in Storage
/// (lunch-box ADR-0029), one small file per child-day in the app's support
/// directory, so a box the phone has shown before is read from the kept
/// photo without asking `lunchPhoto` first. A changed box has another
/// signature and asks again.
final class KeptLunchPhotoPlaces {
  KeptLunchPhotoPlaces({Future<Directory> Function()? root})
    : _root = root ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _root;

  Future<String?> pathOf({
    required String householdId,
    required String childId,
    required CalendarDate date,
    required String signature,
  }) async {
    final file = await _file(householdId, childId, date);
    if (!await file.exists()) return null;
    try {
      final kept = jsonDecode(await file.readAsString());
      if (kept is Map &&
          kept['signature'] == signature &&
          kept['path'] is String) {
        return kept['path'] as String;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<void> remember({
    required String householdId,
    required String childId,
    required CalendarDate date,
    required String signature,
    required String path,
  }) async {
    final file = await _file(householdId, childId, date);
    await file.writeAsString(
      jsonEncode({'signature': signature, 'path': path}),
      flush: true,
    );
  }

  Future<File> _file(
    String householdId,
    String childId,
    CalendarDate date,
  ) async {
    final folder = await Directory('${(await _root()).path}/lunch_photo_places')
        .create(recursive: true);
    return File('${folder.path}/${householdId}_${childId}_${date.iso}.json');
  }
}
