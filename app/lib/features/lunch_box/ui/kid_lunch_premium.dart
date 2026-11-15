import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../subscriptions/data/entitlement_repository.dart';
import '../../subscriptions/model/entitlement.dart';

/// A kid device's lunch chooser, open only while its household has Premium
/// (subscriptions ADR-0009). A kid device sits outside the household shell,
/// so it reads the entitlement itself; a child cannot buy, so the locked
/// place offers no way to.
class KidLunchPremium extends StatefulWidget {
  const KidLunchPremium({
    required this.householdId,
    required this.child,
    super.key,
  });

  final String householdId;
  final Widget child;

  @override
  State<KidLunchPremium> createState() => _KidLunchPremiumState();
}

class _KidLunchPremiumState extends State<KidLunchPremium> {
  late final Stream<Entitlement> _entitlement = context
      .read<EntitlementRepository>()
      .watchEntitlement(widget.householdId);

  @override
  Widget build(BuildContext context) => StreamBuilder<Entitlement>(
    stream: _entitlement,
    builder: (context, snapshot) {
      final entitlement = snapshot.data;
      if (entitlement != null && entitlement.isPremiumAt(DateTime.now())) {
        return widget.child;
      }
      return NestScaffold(
        title: LunchKidPicksCopy.chooserTitle,
        leading: backLeading(context),
        body: entitlement == null && !snapshot.hasError
            ? const NestLoadingView()
            : const NestEmptyView(
                icon: LucideIcons.lock,
                title: LunchKidPicksCopy.kidLockedTitle,
                message: LunchKidPicksCopy.kidLockedBody,
              ),
      );
    },
  );
}
