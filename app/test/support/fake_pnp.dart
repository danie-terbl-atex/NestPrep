import 'dart:async';

import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/add_to_pnp/data/pnp_directory.dart';
import 'package:nestprep/features/add_to_pnp/model/pnp_link_status.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

/// The Pick n Pay callables, answered by the test. A link completes with any
/// code and state unless [completeFailure] says otherwise; pushes are
/// recorded with their packs.
final class FakePnpDirectory implements PnpDirectory {
  PnpLinkStatus status = const PnpLinkStatus.unlinked();
  AppFailure? statusFailure;
  AppFailure? startFailure;
  AppFailure? completeFailure;
  CartPushResult? pushResult;
  final pushFailures = <AppFailure>[];
  Completer<void>? pushGate;

  static final signInPage = Uri.https('login.pnp.co.za', '/authorize', {
    'state': 'test-state',
  });

  var starts = 0;
  var unlinks = 0;
  final completions = <({String code, String state})>[];
  final pushes =
      <
        ({
          String householdId,
          List<String> itemIds,
          Map<String, int> quantities,
        })
      >[];

  @override
  Future<PnpLinkStatus> linkStatus() async {
    if (statusFailure case final failure?) throw failure;
    return status;
  }

  @override
  Future<Uri> startLink() async {
    starts++;
    if (startFailure case final failure?) throw failure;
    return signInPage;
  }

  @override
  Future<PnpLinkStatus> completeLink({
    required String code,
    required String state,
  }) async {
    completions.add((code: code, state: state));
    if (completeFailure case final failure?) throw failure;
    return status = PnpLinkStatus(
      isLinked: true,
      linkedAt: DateTime.utc(2026, 10, 12, 9),
    );
  }

  @override
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  }) async {
    pushes.add((
      householdId: householdId,
      itemIds: itemIds,
      quantities: quantities,
    ));
    await pushGate?.future;
    if (pushFailures.isNotEmpty) throw pushFailures.removeAt(0);
    return pushResult ??
        const CartPushResult(
          added: [],
          skipped: [],
          cartItemCount: 0,
          cartTotal: Money.zero(),
        );
  }

  @override
  Future<void> unlink() async {
    unlinks++;
    status = const PnpLinkStatus.unlinked();
  }
}
