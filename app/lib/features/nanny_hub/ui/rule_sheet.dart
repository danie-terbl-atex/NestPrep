import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/house_rule.dart';
import '../model/nanny_limits.dart';

/// What the rule sheet decided: the rule's words, or — for one that exists —
/// that it goes. Null means closed.
typedef RuleOutcome = ({String text, bool isRemoval});

Future<RuleOutcome?> showRuleSheet({
  required BuildContext context,
  HouseRule? existing,
}) => showNestSheet<RuleOutcome>(
  context: context,
  title: existing == null ? NannyCopy.addRule : NannyCopy.editRule,
  builder: (_) => _RuleBody(existing: existing),
);

class _RuleBody extends StatefulWidget {
  const _RuleBody({required this.existing});

  final HouseRule? existing;

  @override
  State<_RuleBody> createState() => _RuleBodyState();
}

class _RuleBodyState extends State<_RuleBody> {
  late final _text = TextEditingController(text: widget.existing?.text);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    final confirmed = await showNestConfirm(
      context: context,
      title: NannyCopy.removeRuleConfirm,
      confirmLabel: NannyCopy.delete,
      cancelLabel: NannyCopy.cancel,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop((text: _text.text, isRemoval: true));
  }

  @override
  Widget build(BuildContext context) {
    final text = _text.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestTextField(
          label: NannyCopy.ruleText,
          hint: NannyCopy.ruleTextHint,
          controller: _text,
          autofocus: widget.existing == null,
          maxLines: 3,
          inputFormatters: [
            LengthLimitingTextInputFormatter(NannyLimits.ruleText),
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: NannyCopy.save,
          onPressed: text.isEmpty
              ? null
              : () => Navigator.of(
                  context,
                ).pop((text: text, isRemoval: false)),
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: NannyCopy.delete,
            variant: NestButtonVariant.ghost,
            icon: Icons.delete_outline,
            onPressed: _remove,
          ),
        ],
      ],
    );
  }
}
