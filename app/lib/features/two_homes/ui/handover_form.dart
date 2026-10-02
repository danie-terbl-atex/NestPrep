import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../model/handover_note.dart';
import '../model/handover_view.dart';
import '../state/handover_controller.dart';
import 'bag_checklist.dart';
import 'home_swatch.dart';

/// The handover's fields (household ADR-0004). Filled once from what both
/// homes last saved, then the person's own until they save — a save by the
/// other home while somebody is typing does not wipe what they typed; the
/// save that follows is the last word, as the ADR accepts.
class HandoverForm extends StatefulWidget {
  const HandoverForm({required this.view, required this.canEdit, super.key});

  final HandoverView view;
  final bool canEdit;

  @override
  State<HandoverForm> createState() => _HandoverFormState();
}

class _HandoverFormState extends State<HandoverForm> {
  late List<HandoverItem> _items = widget.view.note?.items ?? const [];
  late final _medicine = TextEditingController(
    text: widget.view.note?.medicine,
  );
  late final _homework = TextEditingController(
    text: widget.view.note?.homework,
  );
  late final _clothes = TextEditingController(text: widget.view.note?.clothes);
  late final _other = TextEditingController(text: widget.view.note?.note);

  @override
  void dispose() {
    for (final field in [_medicine, _homework, _clothes, _other]) {
      field.dispose();
    }
    super.dispose();
  }

  void _changeItems(List<HandoverItem> items) {
    setState(() => _items = items);
    context.read<HandoverController>().edited();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HandoverController>();
    final nest = NestTheme.of(context);
    final link = widget.view.link;
    final note = widget.view.note;
    final day = link.daysBetween(controller.date, controller.date).firstOrNull;
    final view = context.watch<HouseholdView>();
    final childName =
        view.memberById(link.childMemberId)?.displayName ?? link.childName;
    final savedBy = note?.updatedBySide;

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (day != null)
          NestRiseIn(
            child: NestCard(
              variant: NestCardVariant.tinted,
              padding: const EdgeInsets.all(NestSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TwoHomesHandoverCopy.goesFromTo(
                      childName,
                      link.homeOf(day.side.other).name,
                      link.homeOf(day.side).name,
                    ),
                    style: nest.text.title,
                  ),
                  const SizedBox(height: NestSpace.sm),
                  Wrap(
                    spacing: NestSpace.lg,
                    runSpacing: NestSpace.xs,
                    children: [
                      HomeSwatch(home: link.homeOf(day.side.other)),
                      HomeSwatch(home: link.homeOf(day.side)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (savedBy != null) ...[
          const SizedBox(height: NestSpace.sm),
          Text(
            TwoHomesHandoverCopy.lastSavedBy(link.homeOf(savedBy).name),
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
        ],
        if (!widget.canEdit) ...[
          const SizedBox(height: NestSpace.md),
          const NestBanner(message: TwoHomesHandoverCopy.readOnly),
        ],
        const SizedBox(height: NestSpace.xl),
        BagChecklist(
          items: _items,
          canEdit: widget.canEdit,
          onChanged: _changeItems,
        ),
        const SizedBox(height: NestSpace.xl),
        for (final (field, label, hint) in [
          (
            _medicine,
            TwoHomesHandoverCopy.medicine,
            TwoHomesHandoverCopy.medicineHint,
          ),
          (
            _homework,
            TwoHomesHandoverCopy.homework,
            TwoHomesHandoverCopy.homeworkHint,
          ),
          (
            _clothes,
            TwoHomesHandoverCopy.clothes,
            TwoHomesHandoverCopy.clothesHint,
          ),
          (_other, TwoHomesHandoverCopy.note, TwoHomesHandoverCopy.noteHint),
        ]) ...[
          NestTextField(
            label: label,
            hint: hint,
            controller: field,
            enabled: widget.canEdit,
            maxLines: 3,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                field == _other
                    ? HandoverNote.maxOtherLength
                    : HandoverNote.maxNoteLength,
              ),
            ],
            onChanged: (_) => controller.edited(),
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        if (widget.canEdit) ...[
          if (controller.justSaved) ...[
            const NestBanner(
              message: TwoHomesHandoverCopy.saved,
              tone: NestBannerTone.success,
            ),
            const SizedBox(height: NestSpace.md),
          ],
          NestButton(
            label: TwoHomesHandoverCopy.save,
            icon: LucideIcons.check,
            isLoading: controller.isSaving,
            onPressed: controller.isSaving ? null : _save,
          ),
        ],
      ],
    );
  }

  Future<void> _save() => context.read<HandoverController>().save(
    items: _items,
    medicine: _medicine.text,
    homework: _homework.text,
    clothes: _clothes.text,
    note: _other.text,
  );
}
