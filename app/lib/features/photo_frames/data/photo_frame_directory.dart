import '../model/frame_panels.dart';
import '../model/frame_share_item.dart';

abstract interface class PhotoFrameDirectory {
  Future<String> claimPairing({
    required String householdId,
    required String code,
    required String name,
    required FramePanels panels,
  });

  Future<void> shareToFrame({
    required String householdId,
    required String frameId,
    required FrameShareItem item,
  });
}
