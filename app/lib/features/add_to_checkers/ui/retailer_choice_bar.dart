import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../groceries/model/product_match.dart';
import '../state/retailer_choice_controller.dart';
import 'retailer_picker.dart';

/// The grocery screen's *Shop at*, wired to the choice kept on this phone.
class RetailerChoiceBar extends StatelessWidget {
  const RetailerChoiceBar({super.key});

  @override
  Widget build(BuildContext context) {
    final chosen = context.select<RetailerChoiceController, ProductRetailer>(
      (choice) => choice.chosen,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: RetailerPicker(
        chosen: chosen,
        onChoose: context.read<RetailerChoiceController>().choose,
      ),
    );
  }
}
