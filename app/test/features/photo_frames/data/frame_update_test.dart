import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/photo_frames/data/firestore_photo_frame_repository.dart';
import 'package:nestprep/features/photo_frames/data/storage_frame_photo_store.dart';
import 'package:nestprep/features/photo_frames/model/frame_groceries.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/model/frame_photo.dart';
import 'package:nestprep/features/photo_frames/model/frame_screensaver.dart';

void main() {
  test(
    'an edit writes the name, the panels, the screensaver and groceries',
    () {
      expect(
        FirestorePhotoFrameRepository.frameUpdate(
          name: 'Hall frame',
          panels: const FramePanels(meals: false),
          screensaver: const FrameScreensaver(
            idleMinutes: 5,
            secondsPerPhoto: 30,
          ),
          groceries: const FrameGroceries(
            shop: ProductRetailer.pickNPay,
            area: CheckersArea.johannesburg,
          ),
        ),
        {
          'name': 'Hall frame',
          'panels': const FramePanels(meals: false).toJson(),
          'screensaver': {'idleMinutes': 5, 'secondsPerPhoto': 30},
          'groceries': {'shop': 'pickNPay', 'area': 'johannesburg'},
        },
      );
    },
  );

  test(
    'an edit with it off removes the field, so rules from before it still pass',
    () {
      expect(
        FirestorePhotoFrameRepository.frameUpdate(
          name: 'Hall frame',
          panels: const FramePanels(),
          screensaver: FrameScreensaver.off,
          groceries: null,
        )['screensaver'],
        FieldValue.delete(),
      );
    },
  );

  test('an edit with groceries off removes the field, so rules from before it '
      'still pass', () {
    expect(
      FirestorePhotoFrameRepository.frameUpdate(
        name: 'Hall frame',
        panels: const FramePanels(),
        screensaver: FrameScreensaver.off,
        groceries: null,
      )['groceries'],
      FieldValue.delete(),
    );
  });

  test('the album lives where the rules look', () {
    expect(
      StorageFramePhotoStore.pathFor('h1', 'abcdefgh1234'),
      'households/h1/framePhotos/abcdefgh1234',
    );
    expect(StorageFramePhotoStore.uploaderKey, 'uploadedByUid');
    expect(FramePhoto.maxBytes, 1048576);
    expect(FramePhoto.idPattern.hasMatch('A' * 20), isTrue);
    expect(FramePhoto.idPattern.hasMatch('short'), isFalse);
    expect(FramePhoto.idPattern.hasMatch('has/a/slash1'), isFalse);
  });
}
