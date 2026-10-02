import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/checkers_link_route.dart';
import '../../groceries/model/grocery_item.dart';
import '../state/checkers_push_controller.dart';
import 'checkers_push_sheet.dart';

/// *Add to Checkers* from the list, end to end: push [items] with the result
/// sheet open from the first moment; when the member's link has run out (or
/// never was) the sheet says so, *Link Checkers* sends them to link, and the
/// same items are pushed again once they have.
Future<void> addListToCheckers(
  BuildContext context, {
  required String householdId,
  required List<GroceryItem> items,
}) async {
  final push = context.read<CheckersPushController>();
  final router = GoRouter.of(context);
  final itemNames = {for (final item in items) item.id: item.name};
  var pushing = push.push([for (final item in items) item.id]);
  while (true) {
    if (!context.mounted) break;
    var wantsLink = false;
    await showCheckersPushSheet(
      context: context,
      controller: push,
      itemNames: itemNames,
      onLink: () => wantsLink = true,
      onManageLink: () =>
          unawaited(router.push<void>(CheckersLinkRoute.pathFor(householdId))),
    );
    await pushing;
    if (!wantsLink) break;
    final linked = await router.push<bool>(
      CheckersLinkRoute.pathFor(householdId, returnWhenLinked: true),
    );
    if (linked != true) break;
    pushing = push.retry();
  }
  push.reset();
}
