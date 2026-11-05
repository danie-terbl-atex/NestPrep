import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/list_scan_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';

/// The way into snapping a list, beside the grocery list's add field
/// (list-scan ADR-0001). Premium first — the paywall opens on this feature —
/// then the screen; the server checks premium again.
class SnapListButton extends StatelessWidget {
  const SnapListButton({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context) => NestIconButton(
    key: const ValueKey('snap-list-open'),
    icon: LucideIcons.scanText,
    label: ListScanCopy.open,
    onPressed: () => _open(context),
  );

  Future<void> _open(BuildContext context) async {
    if (!await ensurePremium(context, feature: PremiumFeature.listScan)) {
      return;
    }
    if (!context.mounted) return;
    await context.push(ListScanRoute.pathFor(householdId));
  }
}
