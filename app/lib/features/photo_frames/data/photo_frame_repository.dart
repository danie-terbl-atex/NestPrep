import '../model/frame_groceries.dart';
import '../model/frame_panels.dart';
import '../model/frame_screensaver.dart';
import '../model/photo_frame.dart';

abstract interface class PhotoFrameRepository {
  Stream<List<PhotoFrame>> watchFrames(String householdId);

  Future<void> updateFrame({
    required String householdId,
    required String frameId,
    required String name,
    required FramePanels panels,
    required FrameScreensaver screensaver,
    required FrameGroceries? groceries,
  });

  Future<void> unlinkFrame({
    required String householdId,
    required String frameId,
  });

  static const frameLimit = 20;
}
