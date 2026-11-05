import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/list_scan/data/list_photo_picker.dart';
import 'package:nestprep/features/list_scan/data/list_scan_reader.dart';
import 'package:nestprep/features/list_scan/model/list_photo.dart';
import 'package:nestprep/features/list_scan/model/list_reading.dart';
import 'package:nestprep/features/list_scan/model/list_scan_line.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

final aListPhoto = ListPhoto(Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]));

/// Three lines, the way a fridge list reads.
const threeLines = [
  ListScanLine(key: 0, name: 'Full cream milk', quantity: '2 l'),
  ListScanLine(key: 1, name: 'Brown bread'),
  ListScanLine(key: 2, name: 'Bananas', quantity: '1 kg'),
];

/// The reader, answering what the test says — or holding the answer until
/// [complete] so a test can see the reading step.
final class FakeListScanReader implements ListScanReader {
  ListReading reading = const ListReading(lines: threeLines, callsLeft: 97);
  AppFailure? failWith;
  Completer<void>? gate;
  final requests = <({String householdId, ListPhoto photo})>[];

  void complete() => gate?.complete();

  @override
  Future<ListReading> read({
    required String householdId,
    required ListPhoto photo,
  }) async {
    requests.add((householdId: householdId, photo: photo));
    final waiting = gate;
    if (waiting != null) await waiting.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return reading;
  }
}

final class FakeListPhotoPicker implements ListPhotoPicker {
  ListPhoto? next = aListPhoto;
  AppFailure? failWith;
  final asked = <ListPhotoSource>[];

  @override
  Future<ListPhoto?> pick(ListPhotoSource source) async {
    asked.add(source);
    final failure = failWith;
    if (failure != null) throw failure;
    return next;
  }
}
