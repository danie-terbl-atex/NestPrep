import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/school.dart';
import 'sheet_outcome.dart';

/// What the school sheet collected.
typedef SchoolDraft = ({String name, bool nutFree});

/// Adds a school, or edits [existing] — its name and whether it is nut-free,
/// which becomes a rule for every child at it. Only an admin reaches this.
Future<SheetOutcome<SchoolDraft>?> showSchoolSheet({
  required BuildContext context,
  School? existing,
}) => showNestSheet<SheetOutcome<SchoolDraft>>(
  context: context,
  title: existing == null ? FamilyCopy.addSchool : FamilyCopy.editSchool,
  builder: (_) => _SchoolSheetBody(existing: existing),
);

class _SchoolSheetBody extends StatefulWidget {
  const _SchoolSheetBody({required this.existing});

  final School? existing;

  @override
  State<_SchoolSheetBody> createState() => _SchoolSheetBodyState();
}

class _SchoolSheetBodyState extends State<_SchoolSheetBody> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late bool _nutFree = widget.existing?.nutFree ?? false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final canSave = _name.text.trim().isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: FamilyCopy.schoolName,
            controller: _name,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.xl),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NestChip(
              label: FamilyCopy.schoolNutFree,
              icon: _nutFree ? Icons.check : Icons.no_food_outlined,
              isSelected: _nutFree,
              onTap: () => setState(() => _nutFree = !_nutFree),
            ),
          ),
          const SizedBox(height: NestSpace.sm),
          Text(FamilyCopy.schoolNutFreeHelp, style: nest.text.caption),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: FamilyCopy.save,
            onPressed: canSave
                ? () => Navigator.of(context).pop(
                    SheetSaved((name: _name.text.trim(), nutFree: _nutFree)),
                  )
                : null,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: FamilyCopy.deleteSchool,
              variant: NestButtonVariant.ghost,
              icon: Icons.delete_outline,
              onPressed: () =>
                  Navigator.of(context).pop(const SheetRemoved<SchoolDraft>()),
            ),
          ],
        ],
      ),
    );
  }
}
