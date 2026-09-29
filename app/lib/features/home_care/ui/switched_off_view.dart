import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';

/// Shows [child] while [flag] is on, and says plainly that this part is not
/// switched on when it is off — for somebody who arrives by a link while a
/// V2 part is dark (foundation ADR-0014). Nothing is deleted either way.
class SwitchedOffView extends StatelessWidget {
  const SwitchedOffView({required this.flag, required this.child, super.key});

  final FeatureFlag flag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.watch<FeatureFlagsController>().isOn(flag)) return child;
    return const NestEmptyView(
      title: HomeCareCopy.switchedOffTitle,
      message: HomeCareCopy.switchedOffBody,
      icon: Icons.toggle_off_outlined,
    );
  }
}
