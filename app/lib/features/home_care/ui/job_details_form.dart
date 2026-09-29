import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/nest_date_field.dart';
import '../../household/model/member.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_product.dart';
import '../model/home_care_room.dart';
import '../model/job_details.dart';
import 'form_section.dart';
import 'product_kind_look.dart';
import 'room_kind_look.dart';
import 'steps_editor.dart';

/// Everything a parent writes about a job but its photo: what, where, who,
/// when, with what, and how. The composer and the edit sheet both use it.
class JobDetailsForm extends StatefulWidget {
  const JobDetailsForm({
    required this.details,
    required this.onChanged,
    required this.rooms,
    required this.products,
    required this.helpers,
    required this.problems,
    required this.today,
    super.key,
  });

  final JobDetails details;

  /// Hands back a change to make to the details as they stand when it is
  /// made — not a copy of what this form last saw, which a second tap in
  /// the same frame would overwrite.
  final ValueChanged<JobDetails Function(JobDetails)> onChanged;
  final List<HomeCareRoom> rooms;
  final List<HomeCareProduct> products;
  final List<Member> helpers;

  /// What to point at, once somebody has tried to save.
  final List<JobDetailsProblem> problems;
  final CalendarDate today;

  @override
  State<JobDetailsForm> createState() => _JobDetailsFormState();
}

class _JobDetailsFormState extends State<JobDetailsForm> {
  late final _title = TextEditingController(text: widget.details.title);
  late final _note = TextEditingController(text: widget.details.note ?? '');

  JobDetails get _details => widget.details;

  void _change(JobDetails Function(JobDetails) change) =>
      widget.onChanged(change);

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _errorFor(JobDetailsProblem problem) =>
      widget.problems.contains(problem) ? HomeCareCopy.missing(problem) : null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.xl),
          child: NestTextField(
            label: HomeCareCopy.jobTitle,
            hint: HomeCareCopy.jobTitleHint,
            controller: _title,
            errorText: _errorFor(JobDetailsProblem.noTitle),
            inputFormatters: [
              LengthLimitingTextInputFormatter(CleaningJob.titleLimit),
            ],
            onChanged: (text) => _change((d) => d.copyWith(title: text)),
          ),
        ),
        FormSection(
          label: HomeCareCopy.room,
          errorText: _errorFor(JobDetailsProblem.noRoom),
          child: widget.rooms.isEmpty
              ? Text(
                  HomeCareLibraryCopy.noRoomsYet,
                  style: NestTheme.of(context).text.caption,
                )
              : Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.sm,
                  children: [
                    for (final room in widget.rooms)
                      NestChip(
                        label: room.name,
                        icon: room.kind.icon,
                        isSelected: room.id == _details.roomId,
                        onTap: () =>
                            _change((d) => d.copyWith(roomId: room.id)),
                      ),
                  ],
                ),
        ),
        FormSection(
          label: HomeCareCopy.helper,
          errorText: _errorFor(JobDetailsProblem.noHelper),
          child: Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final member in widget.helpers)
                NestChip(
                  label: member.displayName,
                  icon: Icons.person_outline,
                  isSelected: member.id == _details.helperId,
                  onTap: () => _change((d) => d.copyWith(helperId: member.id)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.xl),
          child: NestDateField(
            label: HomeCareCopy.dueDate,
            value: _details.dueDate,
            today: widget.today,
            onChanged: (day) => _change((d) => d.copyWith(dueDate: day)),
          ),
        ),
        FormSection(
          label: HomeCareCopy.productsToUse,
          child: widget.products.isEmpty
              ? Text(
                  HomeCareLibraryCopy.noProductsYet,
                  style: NestTheme.of(context).text.caption,
                )
              : Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.sm,
                  children: [
                    for (final product in widget.products)
                      NestChip(
                        label: product.name,
                        icon: product.kind.icon,
                        isSelected: _details.productIds.contains(product.id),
                        onTap: () =>
                            _change((d) => d.withProductToggled(product.id)),
                      ),
                  ],
                ),
        ),
        FormSection(
          label: HomeCareCopy.steps,
          child: StepsEditor(
            steps: _details.steps,
            canAdd: _details.canAddStep,
            errorText: _errorFor(JobDetailsProblem.noSteps),
            onAdd: (text) => _change((d) => d.withStepAdded(text)),
            onRemove: (id) => _change((d) => d.withoutStep(id)),
          ),
        ),
        NestTextField(
          label: HomeCareCopy.jobNote,
          hint: HomeCareCopy.jobNoteHint,
          controller: _note,
          maxLines: 3,
          inputFormatters: [
            LengthLimitingTextInputFormatter(CleaningJob.noteLimit),
          ],
          onChanged: (text) => _change((d) => d.copyWith(note: text)),
        ),
      ],
    );
  }
}
