import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/copy/kid_copy.dart';
import '../state/kid_code_controller.dart';
import 'kid_code_letters.dart';

/// Where a child types their code: six big tiles over one real text field, so
/// the keyboard, paste and a screen reader all work as they would anywhere
/// else, and the child sees each letter land in its own box (accounts
/// ADR-0003).
///
/// What is typed is cleaned as it is typed — upper case, and only the letters a
/// code can have — and the tiles show the result, so nothing is changed behind
/// anybody's back (`FE-10`).
class KidCodeField extends StatefulWidget {
  const KidCodeField({
    required this.code,
    required this.onChanged,
    required this.onSubmitted,
    super.key,
  });

  final String code;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  State<KidCodeField> createState() => _KidCodeFieldState();
}

class _KidCodeFieldState extends State<KidCodeField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.code,
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.code;
    return Stack(
      children: [
        KidCodeLetters(
          code: code,
          length: KidCodeController.codeLength,
          activeIndex:
              _focus.hasFocus && code.length < KidCodeController.codeLength
              ? code.length
              : null,
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            // Invisible, but still the thing a screen reader announces and a
            // tap lands on.
            alwaysIncludeSemantics: true,
            child: TextField(
              controller: _text,
              focusNode: _focus,
              autofocus: true,
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.go,
              inputFormatters: [_KidCodeFormatter()],
              decoration: const InputDecoration(
                labelText: KidCopy.codeFieldLabel,
                border: InputBorder.none,
                counterText: '',
              ),
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSubmitted(),
            ),
          ),
        ),
      ],
    );
  }
}

class _KidCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = KidCodeController.normalise(newValue.text);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}
