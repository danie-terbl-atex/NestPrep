import 'package:cloud_functions/cloud_functions.dart';

import '../model/frame_panels.dart';
import '../model/frame_share_item.dart';
import 'frame_share_payload.dart';
import 'photo_frame_directory.dart';
import 'photo_frame_failure_mapper.dart';

final class CallablePhotoFrameDirectory implements PhotoFrameDirectory {
  const CallablePhotoFrameDirectory(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<String> claimPairing({
    required String householdId,
    required String code,
    required String name,
    required FramePanels panels,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('claimFramePairing')
          .call<Object?>({
            'householdId': householdId,
            'code': code,
            'name': name,
            'panels': panels.toJson(),
          });
      final data = result.data;
      final frameId = data is Map ? data['frameId'] : null;
      if (frameId is String && frameId.isNotEmpty) return frameId;
      throw FormatException('frameId missing from the callable result', data);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromFrameCallable(error);
    }
  }

  @override
  Future<void> shareToFrame({
    required String householdId,
    required String frameId,
    required FrameShareItem item,
  }) async {
    try {
      await _functions
          .httpsCallable('shareToFrame')
          .call<Object?>(
            frameSharePayload(
              householdId: householdId,
              frameId: frameId,
              item: item,
            ),
          );
    } on FirebaseFunctionsException catch (error) {
      throw failureFromFrameCallable(error);
    }
  }
}
