import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/emulator_ping.dart';

class PingListView extends StatelessWidget {
  const PingListView({required this.pings, super.key});

  final List<EmulatorPing> pings;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: NestSize.controlLarge * 2),
      itemCount: pings.length,
      separatorBuilder: (_, _) => const SizedBox(height: NestSpace.sm),
      itemBuilder: (context, index) {
        final ping = pings[index];
        final sentAt = ping.sentAt;
        return NestListRow(
          key: ValueKey(ping.id),
          leading: NestIconTile(
            icon: sentAt == null
                ? Icons.cloud_upload_outlined
                : Icons.cloud_done_outlined,
            tint: sentAt == null ? NestTileTint.peach : NestTileTint.mint,
          ),
          title: '${AppCopy.diagnosticsPingFrom} ${ping.sentFrom}',
          subtitle: sentAt?.toIso8601String() ?? AppCopy.diagnosticsPingPending,
        );
      },
    );
  }
}
