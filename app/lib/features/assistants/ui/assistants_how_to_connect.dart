import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/assistants_copy.dart';

/// How to connect an assistant (assistants ADR-0001): where in Claude to add
/// nestprep, and the address to give it, which can be copied.
class AssistantsHowToConnect extends StatefulWidget {
  const AssistantsHowToConnect({super.key});

  @override
  State<AssistantsHowToConnect> createState() => _AssistantsHowToConnectState();
}

class _AssistantsHowToConnectState extends State<AssistantsHowToConnect> {
  bool _hasCopied = false;

  Future<void> _copy() async {
    await Clipboard.setData(
      const ClipboardData(text: AssistantsCopy.connectAddress),
    );
    if (!mounted) return;
    setState(() => _hasCopied = true);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AssistantsCopy.connectInClaude,
            style: nest.text.body.copyWith(color: nest.colors.ink),
          ),
          const SizedBox(height: NestSpace.sm),
          SelectableText(
            AssistantsCopy.connectAddress,
            style: nest.text.bodyStrong.copyWith(color: nest.colors.ink),
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            AssistantsCopy.connectInChatGpt,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: _hasCopied
                ? AssistantsCopy.addressCopied
                : AssistantsCopy.copyAddress,
            icon: _hasCopied ? LucideIcons.check : LucideIcons.copy,
            variant: NestButtonVariant.outline,
            onPressed: _copy,
          ),
        ],
      ),
    );
  }
}
