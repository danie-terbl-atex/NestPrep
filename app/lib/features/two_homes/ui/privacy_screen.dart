import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import 'privacy_boundary.dart';

/// What the other home can see, on a screen of its own — reached from the
/// two-homes list and from every link (household ADR-0004). It reads no data:
/// the boundary is the same for every link, because the rules make it so.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NestScaffold(
      title: TwoHomesSetupCopy.privacyTitle,
      leading: backLeading(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: const [NestRiseIn(child: PrivacyBoundary())],
      ),
    );
  }
}
