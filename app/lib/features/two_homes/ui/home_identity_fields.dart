import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/ui/member_colour_picker.dart';
import '../model/co_parent_home.dart';

/// What this home is called and its colour on both calendars — all the other
/// home ever learns about this household (household ADR-0004). The palette
/// is the members' own, proven readable in both themes (`FE-13`).
class HomeIdentityFields extends StatefulWidget {
  const HomeIdentityFields({
    required this.name,
    required this.color,
    required this.onName,
    required this.onColor,
    super.key,
  });

  final String name;
  final MemberColor color;
  final ValueChanged<String> onName;
  final ValueChanged<MemberColor> onColor;

  @override
  State<HomeIdentityFields> createState() => _HomeIdentityFieldsState();
}

class _HomeIdentityFieldsState extends State<HomeIdentityFields> {
  late final _name = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: TwoHomesSetupCopy.homeNameLabel,
          hint: TwoHomesSetupCopy.homeNameHint,
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            LengthLimitingTextInputFormatter(CoParentHome.maxNameLength),
          ],
          onChanged: widget.onName,
        ),
        const SizedBox(height: NestSpace.lg),
        Text(
          TwoHomesSetupCopy.homeColour,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        MemberColourPicker(selected: widget.color, onSelect: widget.onColor),
      ],
    );
  }
}
