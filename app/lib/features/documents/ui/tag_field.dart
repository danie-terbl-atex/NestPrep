import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';
import '../model/document_tags.dart';

/// A document's tags: the ones it has, each removable; a field to add another;
/// and the household's other tags offered as one-tap suggestions, so "ID" is
/// not typed three different ways (documents ADR-0005).
///
/// The limits are `firestore.rules`'; the field stops at them and says so
/// rather than dropping a tag silently (`FE-10`).
class TagField extends StatefulWidget {
  const TagField({
    required this.tags,
    required this.onChanged,
    this.suggestions = const [],
    super.key,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final List<String> suggestions;

  @override
  State<TagField> createState() => _TagFieldState();
}

class _TagFieldState extends State<TagField> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _isFull => widget.tags.length >= DocumentTags.maxTags;

  void _add(String raw) {
    final next = DocumentTags.adding(widget.tags, raw);
    _text.clear();
    setState(() {});
    if (!identical(next, widget.tags)) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final offered = [
      for (final tag in widget.suggestions)
        if (!DocumentTags.contains(widget.tags, tag)) tag,
    ].take(6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: VaultCopy.tagsLabel,
          hint: VaultCopy.tagsHint,
          controller: _text,
          enabled: !_isFull,
          helperText: VaultCopy.tagsLimit,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            LengthLimitingTextInputFormatter(DocumentTags.maxLength),
          ],
          onChanged: (_) => setState(() {}),
          onSubmitted: _add,
          suffix: NestIconButton(
            icon: Icons.add,
            label: VaultCopy.addTag,
            variant: NestIconButtonVariant.plain,
            onPressed:
                DocumentTags.canAdd(widget.tags, DocumentTags.tidy(_text.text))
                ? () => _add(_text.text)
                : null,
          ),
        ),
        if (widget.tags.isNotEmpty || offered.isNotEmpty)
          const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final tag in widget.tags)
              NestChip(
                label: tag,
                isSelected: true,
                icon: Icons.close,
                semanticLabel: VaultCopy.removeTag(tag),
                onTap: () => widget.onChanged([
                  for (final kept in widget.tags)
                    if (kept != tag) kept,
                ]),
              ),
            if (!_isFull)
              for (final tag in offered)
                NestChip(label: tag, icon: Icons.add, onTap: () => _add(tag)),
          ],
        ),
        if (_isFull)
          Text(
            VaultCopy.tagsLimit,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
      ],
    );
  }
}
