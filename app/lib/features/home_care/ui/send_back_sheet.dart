import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/cleaning_job.dart';

/// Asks what still needs doing before a job goes back to the helper. The
/// note cannot be empty — the rules refuse it, and a job sent back without
/// a reason is a job done twice for nothing.
Future<String?> showSendBackSheet(BuildContext context) =>
    showNestSheet<String>(
      context: context,
      title: HomeCareCopy.sendBackTitle,
      builder: (context) => const _SendBackBody(),
    );

class _SendBackBody extends StatefulWidget {
  const _SendBackBody();

  @override
  State<_SendBackBody> createState() => _SendBackBodyState();
}

class _SendBackBodyState extends State<_SendBackBody> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = _note.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestTextField(
          label: HomeCareCopy.sendBackNote,
          hint: HomeCareCopy.sendBackHint,
          controller: _note,
          autofocus: true,
          maxLines: 3,
          inputFormatters: [
            LengthLimitingTextInputFormatter(CleaningJob.noteLimit),
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: HomeCareCopy.sendBack,
          icon: Icons.replay,
          onPressed: note.isEmpty
              ? null
              : () => Navigator.of(context).pop(note),
        ),
        const SizedBox(height: NestSpace.lg),
      ],
    );
  }
}
