import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/family_profile.dart';
import '../model/school.dart';
import 'sheet_label.dart';

/// What the schooling sheet collected: a school from the household's list, or
/// none, and a grade.
typedef SchoolingDraft = ({String? schoolId, String grade});

/// Where somebody goes to school. The household's schools are offered as
/// chips; an admin can add one without leaving — [onAddSchool] opens the
/// school sheet and answers with the school it made.
Future<SchoolingDraft?> showSchoolingSheet({
  required BuildContext context,
  required FamilyProfile profile,
  required List<School> schools,
  Future<School?> Function()? onAddSchool,
}) => showNestSheet<SchoolingDraft>(
  context: context,
  title: FamilyCopy.sectionSchool,
  builder: (_) => _SchoolingSheetBody(
    profile: profile,
    schools: schools,
    onAddSchool: onAddSchool,
  ),
);

class _SchoolingSheetBody extends StatefulWidget {
  const _SchoolingSheetBody({
    required this.profile,
    required this.schools,
    required this.onAddSchool,
  });

  final FamilyProfile profile;
  final List<School> schools;
  final Future<School?> Function()? onAddSchool;

  @override
  State<_SchoolingSheetBody> createState() => _SchoolingSheetBodyState();
}

class _SchoolingSheetBodyState extends State<_SchoolingSheetBody> {
  late List<School> _schools = widget.schools;

  /// A school id that is no longer in the list reads as none.
  late String? _schoolId =
      widget.schools.any((school) => school.id == widget.profile.schoolId)
      ? widget.profile.schoolId
      : null;
  late final _grade = TextEditingController(text: widget.profile.grade ?? '');

  @override
  void dispose() {
    _grade.dispose();
    super.dispose();
  }

  Future<void> _add(Future<School?> Function() addSchool) async {
    final school = await addSchool();
    if (school == null || !mounted) return;
    setState(() {
      _schools = [..._schools, school];
      _schoolId = school.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final addSchool = widget.onAddSchool;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetLabel(FamilyCopy.schoolLabel),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestChip(
                label: FamilyCopy.schoolNone,
                isSelected: _schoolId == null,
                onTap: () => setState(() => _schoolId = null),
              ),
              for (final school in _schools)
                NestChip(
                  key: ValueKey(school.id),
                  label: school.name,
                  icon: school.nutFree ? Icons.no_food_outlined : null,
                  isSelected: _schoolId == school.id,
                  onTap: () => setState(() => _schoolId = school.id),
                ),
              if (addSchool != null)
                NestChip(
                  label: FamilyCopy.addSchool,
                  icon: Icons.add,
                  onTap: () => _add(addSchool),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          NestTextField(
            label: FamilyCopy.grade,
            hint: FamilyCopy.gradeHint,
            controller: _grade,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: FamilyCopy.save,
            onPressed: () =>
                Navigator.of(context)
                    .pop((schoolId: _schoolId, grade: _grade.text)),
          ),
        ],
      ),
    );
  }
}
