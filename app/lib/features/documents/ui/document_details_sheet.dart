import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/document_limits.dart';
import 'expiry_field.dart';
import 'scan_sides.dart';
import 'tag_field.dart';

/// What somebody said about a document: its name, tags and expiry.
typedef DocumentDetails = ({
  String name,
  List<String> tags,
  CalendarDate? expiresOn,
});

/// Naming, tagging and dating a document — after a scan (with its sides shown
/// to check), after choosing a file, or later to change them. One sheet for
/// the three, so they cannot drift apart (`ENG-01`). Null when somebody backed
/// out.
Future<DocumentDetails?> showDocumentDetailsSheet({
  required BuildContext context,
  required String title,
  required String saveLabel,
  required CalendarDate today,
  required String initialName,
  List<Uint8List> sides = const [],
  bool withTagsAndExpiry = true,
  List<String> initialTags = const [],
  CalendarDate? initialExpiry,
  List<String> tagSuggestions = const [],
}) => showNestSheet<DocumentDetails>(
  context: context,
  title: title,
  builder: (sheetContext) => _DocumentDetailsBody(
    saveLabel: saveLabel,
    today: today,
    initialName: initialName,
    sides: sides,
    withTagsAndExpiry: withTagsAndExpiry,
    initialTags: initialTags,
    initialExpiry: initialExpiry,
    tagSuggestions: tagSuggestions,
  ),
);

class _DocumentDetailsBody extends StatefulWidget {
  const _DocumentDetailsBody({
    required this.saveLabel,
    required this.today,
    required this.initialName,
    required this.sides,
    required this.withTagsAndExpiry,
    required this.initialTags,
    required this.initialExpiry,
    required this.tagSuggestions,
  });

  final String saveLabel;
  final CalendarDate today;
  final String initialName;
  final List<Uint8List> sides;
  final bool withTagsAndExpiry;
  final List<String> initialTags;
  final CalendarDate? initialExpiry;
  final List<String> tagSuggestions;

  @override
  State<_DocumentDetailsBody> createState() => _DocumentDetailsBodyState();
}

class _DocumentDetailsBodyState extends State<_DocumentDetailsBody> {
  late final _name = TextEditingController(text: widget.initialName);
  late List<String> _tags = widget.initialTags;
  late CalendarDate? _expiresOn = widget.initialExpiry;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.sides.isNotEmpty) ...[
            Text(VaultCopy.reviewBody, style: nest.text.bodySecondary),
            const SizedBox(height: NestSpace.md),
            ScanSides(sides: widget.sides),
            const SizedBox(height: NestSpace.lg),
          ],
          NestTextField(
            label: AppCopy.documentsNameLabel,
            hint: VaultCopy.nameHint,
            controller: _name,
            textInputAction: TextInputAction.done,
            // The cap is the rules'; the keyboard stops at it rather than the
            // name being trimmed afterwards (`FE-10`).
            inputFormatters: [
              LengthLimitingTextInputFormatter(DocumentLimits.nameMaxLength),
            ],
            onChanged: (_) => setState(() {}),
          ),
          if (widget.withTagsAndExpiry) ...[
            const SizedBox(height: NestSpace.lg),
            TagField(
              tags: _tags,
              suggestions: widget.tagSuggestions,
              onChanged: (tags) => setState(() => _tags = tags),
            ),
            const SizedBox(height: NestSpace.lg),
            ExpiryField(
              value: _expiresOn,
              today: widget.today,
              onChanged: (date) => setState(() => _expiresOn = date),
            ),
          ],
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: widget.saveLabel,
            onPressed: _name.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, tags: _tags, expiresOn: _expiresOn));
  }
}
