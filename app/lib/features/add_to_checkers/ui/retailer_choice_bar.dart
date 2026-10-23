import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../state/retailer_choice_controller.dart';
import 'retailer_picker.dart';
import 'shops_on_list.dart';

/// The grocery screen's *Shop at*, wired to the choice kept on this phone.
class RetailerChoiceBar extends StatelessWidget {
  const RetailerChoiceBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Watches the choice and the switches, so a shop switched off live
    // leaves the row at once.
    final chosen = context.watch<RetailerChoiceController>().chosen;
    final available = shopsOnList(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: RetailerPicker(
        chosen: chosen,
        available: available,
        onChoose: context.read<RetailerChoiceController>().choose,
      ),
    );
  }
}
