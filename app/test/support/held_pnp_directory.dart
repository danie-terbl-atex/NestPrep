import 'dart:async';

import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/add_to_pnp/data/pnp_directory.dart';
import 'package:nestprep/features/add_to_pnp/model/pnp_link_status.dart';

/// A Pick n Pay whose link status arrives only when the test completes
/// [answer].
final class HeldPnpDirectory implements PnpDirectory {
  final answer = Completer<PnpLinkStatus>();
  var reads = 0;

  @override
  Future<PnpLinkStatus> linkStatus() {
    reads++;
    return answer.future;
  }

  @override
  Future<Uri> startLink() => throw UnimplementedError();

  @override
  Future<PnpLinkStatus> completeLink({
    required String code,
    required String state,
  }) => throw UnimplementedError();

  @override
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  }) => throw UnimplementedError();

  @override
  Future<void> unlink() => throw UnimplementedError();
}
