import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';

import '../../groceries/model/grocery_item.dart';
import '../state/checkers_push_controller.dart';
import 'add_to_checkers_bar.dart';
import 'add_to_checkers_flow.dart';

/// The grocery screen's *Add to Checkers*, wired: nothing when no unbought
/// item has a product, otherwise the bar, which runs the push flow.
class CheckersListBar extends StatelessWidget {
  const CheckersListBar({
    required this.householdId,
    required this.matched,
    super.key,
  });

  final String householdId;
  final List<GroceryItem> matched;

  @override
  Widget build(BuildContext context) {
    if (matched.isEmpty) return const SizedBox.shrink();
    final isPushing = context.select<CheckersPushController, bool>(
      (push) => push.isPushing,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: AddToCheckersBar(
        matchedCount: matched.length,
        isPushing: isPushing,
        onAdd: () => addListToCheckers(
          context,
          householdId: householdId,
          items: matched,
        ),
      ),
    );
  }
}
