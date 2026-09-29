import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/dietary_flag.dart';
import '../model/family_profile.dart';
import 'chip_list_editor.dart';
import 'sheet_label.dart';

/// What the food sheet collected. Null from `showFoodSheet` means the person
/// closed it without saving.
typedef FoodDraft = ({
  List<String> likes,
  List<String> dislikes,
  Set<DietaryFlag> diet,
});

Future<FoodDraft?> showFoodSheet({
  required BuildContext context,
  required FamilyProfile profile,
}) => showNestSheet<FoodDraft>(
  context: context,
  title: FamilyCopy.editFood,
  builder: (_) => _FoodSheetBody(profile: profile),
);

class _FoodSheetBody extends StatefulWidget {
  const _FoodSheetBody({required this.profile});

  final FamilyProfile profile;

  @override
  State<_FoodSheetBody> createState() => _FoodSheetBodyState();
}

class _FoodSheetBodyState extends State<_FoodSheetBody> {
  late List<String> _likes = widget.profile.likes;
  late List<String> _dislikes = widget.profile.dislikes;
  late Set<DietaryFlag> _diet = widget.profile.diet;

  void _toggle(DietaryFlag flag) => setState(() {
    _diet = _diet.contains(flag)
        ? ({..._diet}..remove(flag))
        : {..._diet, flag};
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetLabel(FamilyCopy.diet),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final flag in DietaryFlag.values)
                NestChip(
                  label: FamilyCopy.dietName(flag),
                  isSelected: _diet.contains(flag),
                  icon: _diet.contains(flag) ? Icons.check : null,
                  onTap: () => _toggle(flag),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          ChipListEditor(
            label: FamilyCopy.likes,
            hint: FamilyCopy.addLike,
            values: _likes,
            onChanged: (likes) => setState(() => _likes = likes),
          ),
          const SizedBox(height: NestSpace.xl),
          ChipListEditor(
            label: FamilyCopy.dislikes,
            hint: FamilyCopy.addDislike,
            values: _dislikes,
            onChanged: (dislikes) => setState(() => _dislikes = dislikes),
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: FamilyCopy.save,
            onPressed: () =>
                Navigator.of(context)
                    .pop((likes: _likes, dislikes: _dislikes, diet: _diet)),
          ),
        ],
      ),
    );
  }
}
