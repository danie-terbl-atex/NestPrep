import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/referral_copy.dart';
import '../../../shared/ui/upper_case_formatter.dart';

/// Where a new household enters the code of the family who told it about
/// NestPrep, in its first seven days (subscriptions ADR-0002). A refusal
/// lands on the field that caused it, in words (`FE-10`); the button cannot
/// be pressed twice, nor before eight characters are there.
class RedeemCodeCard extends StatefulWidget {
  const RedeemCodeCard({
    required this.deadlineLabel,
    required this.isBusy,
    required this.errorText,
    required this.onSubmit,
    required this.onEdited,
    super.key,
  });

  /// The last day a code may be entered, as the household reads a date.
  final String deadlineLabel;
  final bool isBusy;
  final String? errorText;
  final ValueChanged<String> onSubmit;
  final VoidCallback onEdited;

  static const codeLength = 8;

  @override
  State<RedeemCodeCard> createState() => _RedeemCodeCardState();
}

class _RedeemCodeCardState extends State<RedeemCodeCard> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !widget.isBusy &&
      _code.text.replaceAll(' ', '').length == RedeemCodeCard.codeLength;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NestIconTile(
                icon: Icons.redeem_outlined,
                tint: NestTileTint.guava,
              ),
              const SizedBox(width: NestSpace.lg),
              Expanded(
                child: Text(ReferralCopy.redeemTitle, style: nest.text.title),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Text(
            ReferralCopy.redeemBody(widget.deadlineLabel),
            style: nest.text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: ReferralCopy.redeemLabel,
            hint: ReferralCopy.redeemHint,
            controller: _code,
            errorText: widget.errorText,
            enabled: !widget.isBusy,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: const [UpperCaseFormatter()],
            onChanged: (_) {
              widget.onEdited();
              setState(() {});
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: ReferralCopy.redeemAction,
            isLoading: widget.isBusy,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_canSubmit) return;
    widget.onSubmit(_code.text);
  }
}
