import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/frame_groceries.dart';
import '../model/frame_panels.dart';
import '../model/frame_screensaver.dart';
import '../model/photo_frame.dart';
import 'photo_frame_repository.dart';

final class FirestorePhotoFrameRepository implements PhotoFrameRepository {
  FirestorePhotoFrameRepository(this._firestore);

  static const householdsPath = 'households';
  static const framesPath = 'frames';

  final FirebaseFirestore _firestore;

  CollectionReference<PhotoFrame> _frames(String householdId) =>
      typedCollection(
        _firestore
            .collection(householdsPath)
            .doc(householdId)
            .collection(framesPath),
        fromJson: PhotoFrame.fromJson,
        toJson: (frame) => frame.toJson(),
      );

  @override
  Stream<List<PhotoFrame>> watchFrames(String householdId) =>
      _frames(householdId)
          .limit(PhotoFrameRepository.frameLimit)
          .snapshots()
          .map(
            (snapshot) =>
                [for (final doc in snapshot.docs) doc.data()]
                  ..sort((a, b) => a.name.compareTo(b.name)),
          )
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> updateFrame({
    required String householdId,
    required String frameId,
    required String name,
    required FramePanels panels,
    required FrameScreensaver screensaver,
    required FrameGroceries? groceries,
  }) => _guarded(
    () => _frames(householdId)
        .doc(frameId)
        .update(
          frameUpdate(
            name: name,
            panels: panels,
            screensaver: screensaver,
            groceries: groceries,
          ),
        ),
  );

  static Map<String, Object?> frameUpdate({
    required String name,
    required FramePanels panels,
    required FrameScreensaver screensaver,
    required FrameGroceries? groceries,
  }) => {
    'name': name,
    'panels': panels.toJson(),
    'screensaver': screensaver.isOn
        ? screensaver.toJson()
        : FieldValue.delete(),
    'groceries': groceries?.toJson() ?? FieldValue.delete(),
  };

  @override
  Future<void> unlinkFrame({
    required String householdId,
    required String frameId,
  }) => _guarded(() => _frames(householdId).doc(frameId).delete());

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
