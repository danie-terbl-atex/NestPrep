import 'package:flutter/widgets.dart';

import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_area.dart';

class TwoHomesPremiumArea extends StatelessWidget {
  const TwoHomesPremiumArea(this.title, this.child, {super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      PremiumArea(feature: PremiumFeature.twoHomes, title: title, child: child);
}
