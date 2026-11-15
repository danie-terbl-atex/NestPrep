import 'package:flutter/widgets.dart';

import '../../../shared/copy/app_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_area.dart';

/// One Documents screen, locked for a household without Premium. The lock
/// sits on each screen and never on the shell around them: a shell that
/// stopped building its navigator leaves the router's back nothing to pop.
class DocumentsPremiumArea extends StatelessWidget {
  const DocumentsPremiumArea({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => PremiumArea(
    feature: PremiumFeature.documents,
    title: AppCopy.documentsTitle,
    child: child,
  );
}
