import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/home_layout.dart';
import '../state/home_layout_controller.dart';

class HomeLayoutButton extends StatelessWidget {
  const HomeLayoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeLayoutController?>();
    if (controller == null || !controller.canSwitch) {
      return const SizedBox.shrink();
    }
    final isCards = controller.layout == HomeLayout.cards;
    return NestIconButton(
      icon: isCards ? LucideIcons.panelBottom : LucideIcons.layoutDashboard,
      label: isCards ? HomeBoardCopy.switchToTabs : HomeBoardCopy.switchToCards,
      onPressed: controller.switchLayout,
    );
  }
}
