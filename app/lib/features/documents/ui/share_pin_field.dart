import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/share_request.dart';

/// "Ask for a PIN", and the PIN itself once asked for (documents ADR-0006).
/// The digits are shown, not hidden: the parent is about to read them out or
/// send them, and a PIN they cannot check is one they will get wrong.
class SharePinField extends StatefulWidget {
  const SharePinField({
    required this.asksForPin,
    required this.showsProblem,
    required this.onAsksForPin,
    required this.onPin,
    super.key,
  });

  final bool asksForPin;
  final bool showsProblem;
  final ValueChanged<bool> onAsksForPin;
  final ValueChanged<String> onPin;

  @override
  State<SharePinField> createState() => _SharePinFieldState();
}

class _SharePinFieldState extends State<SharePinField> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // One node for a screen reader: the switch, what it does, its state.
        MergeSemantics(
          child: NestListRow(
            title: ShareLinkCopy.pinToggle,
            subtitle: ShareLinkCopy.pinToggleNote,
            leading: const NestIconTile(
              icon: LucideIcons.rectangleEllipsis,
              tint: NestTileTint.lilac,
            ),
            trailing: Switch(
              value: widget.asksForPin,
              onChanged: widget.onAsksForPin,
            ),
            onTap: () => widget.onAsksForPin(!widget.asksForPin),
          ),
        ),
        if (widget.asksForPin) ...[
          const SizedBox(height: NestSpace.md),
          NestTextField(
            label: ShareLinkCopy.pinLabel,
            hint: ShareLinkCopy.pinHint,
            controller: _pin,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofocus: true,
            prefixIcon: LucideIcons.rectangleEllipsis,
            errorText: widget.showsProblem ? ShareLinkCopy.pinInvalid : null,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(ShareRequest.pinMaxLength),
            ],
            onChanged: widget.onPin,
          ),
          const SizedBox(height: NestSpace.xs),
          Text(
            ShareLinkCopy.withPinReminder,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
      ],
    );
  }
}
