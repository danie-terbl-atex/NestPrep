import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/cart_push_copy.dart';
import '../../groceries/model/product_match.dart';
import '../model/cart_push_state.dart';
import '../state/cart_push_controller.dart';
import 'cart_push_result_view.dart';

/// What a push into [shop]'s cart did, as it happens: adding, a failure
/// with a retry, a link that ran out (or never was), or the result
/// (`FE-08`).
Future<void> showCartPushSheet({
  required BuildContext context,
  required ProductRetailer shop,
  required CartPushController controller,
  required Map<String, String> itemNames,
  required VoidCallback onLink,
  required VoidCallback onManageLink,
}) => showNestSheet<void>(
  context: context,
  title: CartPushCopy.title(shop),
  builder: (sheetContext) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => SingleChildScrollView(
      child: switch (controller.state) {
        CartPushIdle() || CartPushing() => _Pushing(shop: shop),
        CartPushNeedsLink() => _Notice(
          message: CartPushCopy.needsLink(shop),
          actionLabel: CartPushCopy.link(shop),
          onAction: () {
            Navigator.of(sheetContext).pop();
            onLink();
          },
        ),
        CartPushFailed(:final failure) => _Notice(
          message: AppCopy.failure(failure),
          actionLabel: CartPushCopy.retry,
          onAction: controller.retry,
        ),
        CartPushed(:final result) => CartPushResultView(
          shop: shop,
          result: result,
          itemNames: itemNames,
          onDone: () => Navigator.of(sheetContext).pop(),
          onManageLink: () {
            Navigator.of(sheetContext).pop();
            onManageLink();
          },
        ),
      },
    ),
  ),
);

class _Pushing extends StatelessWidget {
  const _Pushing({required this.shop});

  final ProductRetailer shop;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        CartPushCopy.pushing(shop),
        style: NestTheme.of(context).text.bodySecondary,
      ),
      const SizedBox(height: NestSpace.md),
      const NestSkeleton.rows(count: 3),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(message, style: NestTheme.of(context).text.body),
      const SizedBox(height: NestSpace.lg),
      NestButton(label: actionLabel, onPressed: onAction),
    ],
  );
}
