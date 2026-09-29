import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/lunch_board_controller.dart';

/// What "Fill the week" just did, said once: how many days it packed and how
/// many came from go-to boxes — or that there was nothing it could add.
class LunchAutoFillNote extends StatelessWidget {
  const LunchAutoFillNote({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchBoardController>();
    final result = controller.lastAutoFill;
    if (result == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.sm),
      child: NestBanner(
        message: result.isEmpty
            ? LunchCopy.filledNothing
            : LunchCopy.filledDays(
                result.dayCount,
                result.favouriteDays.length,
              ),
        tone: result.isEmpty ? NestBannerTone.info : NestBannerTone.success,
        actionLabel: AppCopy.back,
        onAction: controller.edit.dismissAutoFill,
      ),
    );
  }
}
