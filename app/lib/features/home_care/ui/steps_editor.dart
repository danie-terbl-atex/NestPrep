import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/job_step.dart';
import 'step_number.dart';

/// The checklist a helper will tick, written by the parent: steps in order,
/// each removable, a field for the next one, and a few common steps offered
/// as one tap each.
class StepsEditor extends StatefulWidget {
  const StepsEditor({
    required this.steps,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
    this.errorText,
    this.suggestions = HomeCareCopy.suggestedSteps,
    this.addLabel = HomeCareCopy.addStep,
    this.addHint = HomeCareCopy.addStepHint,
    super.key,
  });

  final List<JobStep> steps;
  final bool canAdd;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final String? errorText;

  /// Common lines offered as one tap each — a job's steps by default; a
  /// room routine offers what is usually done in that room (home-care
  /// ADR-0004).
  final List<String> suggestions;
  final String addLabel;
  final String addHint;

  @override
  State<StepsEditor> createState() => _StepsEditorState();
}

class _StepsEditorState extends State<StepsEditor> {
  final _next = TextEditingController();

  @override
  void dispose() {
    _next.dispose();
    super.dispose();
  }

  void _add(String text) {
    if (text.trim().isEmpty) return;
    widget.onAdd(text);
    _next.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final written = {for (final step in widget.steps) step.text};
    final error = widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, step) in widget.steps.indexed)
          NestListRow(
            key: ValueKey(step.id),
            title: step.text,
            leading: StepNumber(number: index + 1),
            trailing: NestIconButton(
              icon: LucideIcons.x,
              label: HomeCareCopy.removeStep(step.text),
              variant: NestIconButtonVariant.plain,
              onPressed: () => widget.onRemove(step.id),
            ),
          ),
        if (widget.canAdd) ...[
          const SizedBox(height: NestSpace.sm),
          NestTextField(
            label: widget.addLabel,
            hint: widget.addHint,
            controller: _next,
            errorText: error,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            onChanged: (_) => setState(() {}),
            onSubmitted: _add,
            suffix: NestIconButton(
              icon: LucideIcons.plus,
              label: widget.addLabel,
              variant: NestIconButtonVariant.plain,
              onPressed: _next.text.trim().isEmpty
                  ? null
                  : () => _add(_next.text),
            ),
          ),
          const SizedBox(height: NestSpace.md),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final suggestion in widget.suggestions)
                if (!written.contains(suggestion))
                  NestChip(
                    label: suggestion,
                    icon: LucideIcons.plus,
                    onTap: () => _add(suggestion),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}
